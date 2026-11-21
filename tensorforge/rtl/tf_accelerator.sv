module tf_accelerator #(
    parameter integer SIZE = 4,
    parameter integer DIM = 32
) (
    input wire clk, rst,
    input wire host_valid, host_write,
    input wire [13:0] host_addr,
    input wire [31:0] host_wdata,
    output wire host_ready,
    output reg [31:0] host_rdata,
    output wire trace_advance,
    output wire [SIZE*SIZE-1:0] trace_valid,
    output wire [SIZE*SIZE*32-1:0] trace_sums
);
    localparam integer DEPTH = (DIM / SIZE) * DIM;
    localparam [1:0] IDLE = 0, CLEAR = 1, STREAM = 2, WRITEBACK = 3;
    reg [1:0] state;
    reg done, error, relu;
    reg [4:0] shift;
    reg [5:0] m, n, k;
    reg [5:0] tile_m, tile_n, tile_k;
    reg [5:0] write_row;
    reg [6:0] step;
    reg [31:0] cycles;
    reg [31:0] bias [0:DIM-1];

    wire busy = state != IDLE;
    wire [1:0] region = host_addr[13:12];
    wire [9:0] word_index = host_addr[11:2];
    wire [5:0] host_row = word_index / DIM;
    wire [5:0] host_col = word_index % DIM;
    wire aligned = host_addr[1:0] == 0;
    wire write_transaction = host_valid && host_write && aligned && !rst && !busy;
    wire matrix_index_valid = word_index < DIM * DIM;

    wire [6:0] remaining_m = m - tile_m;
    wire [6:0] remaining_n = n - tile_n;
    wire [6:0] remaining_k = k - tile_k;
    wire [6:0] active_m = remaining_m < SIZE ? remaining_m : SIZE;
    wire [6:0] active_n = remaining_n < SIZE ? remaining_n : SIZE;
    wire [6:0] active_k = remaining_k < SIZE ? remaining_k : SIZE;
    wire [6:0] stream_cycles = active_m + active_n + active_k - 2;
    wire [6:0] next_m = tile_m + SIZE;
    wire [6:0] next_n = tile_n + SIZE;
    wire [6:0] next_k = tile_k + SIZE;

    wire [SIZE*8-1:0] a_feed, b_feed;
    wire [SIZE-1:0] a_valid, b_valid;
    wire [SIZE*32-1:0] c_read;

    assign host_ready = 1'b1;
    assign trace_advance = state == STREAM;
    tf_array #(.SIZE(SIZE)) array_core (
        .clk(clk), .rst(rst), .clear(state == CLEAR), .advance(trace_advance),
        .left_data(a_feed), .top_data(b_feed), .left_valid(a_valid),
        .top_valid(b_valid), .sums(trace_sums), .mac_valid(trace_valid)
    );

    generate
        for (genvar lane = 0; lane < SIZE; lane = lane + 1) begin : banks
            reg signed [7:0] activations [0:DEPTH-1];
            reg signed [7:0] weights [0:DEPTH-1];
            reg signed [31:0] outputs [0:DEPTH-1];
            wire [5:0] read_k = tile_k + step - lane;
            wire [9:0] a_index = (tile_m / SIZE) * DIM + read_k;
            wire [9:0] b_index = (tile_n / SIZE) * DIM + read_k;
            wire [9:0] c_index = (tile_n / SIZE) * DIM + tile_m + write_row;
            wire [9:0] c_host_index = (host_col / SIZE) * DIM + host_row;
            wire signed [31:0] tile_sum = trace_sums[(write_row*SIZE+lane)*32 +: 32];
            wire signed [31:0] merged = tile_k == 0 ? tile_sum : outputs[c_index] + tile_sum;
            wire signed [7:0] quantized;
            tf_requant quantizer (
                .value(merged), .bias(bias[tile_n + lane]), .shift(shift), .result(quantized)
            );

            assign a_valid[lane] = trace_advance && lane < active_m &&
                                   step >= lane && step - lane < active_k;
            assign b_valid[lane] = trace_advance && lane < active_n &&
                                   step >= lane && step - lane < active_k;
            assign a_feed[lane*8 +: 8] = a_valid[lane] ? activations[a_index] : 8'b0;
            assign b_feed[lane*8 +: 8] = b_valid[lane] ? weights[b_index] : 8'b0;
            assign c_read[lane*32 +: 32] = outputs[c_host_index];

            always @(posedge clk) begin
                if (write_transaction && matrix_index_valid) begin
                    if (region == 1 && host_row % SIZE == lane)
                        activations[(host_row / SIZE) * DIM + host_col] <= host_wdata[7:0];
                    if (region == 2 && host_col % SIZE == lane)
                        weights[(host_col / SIZE) * DIM + host_row] <= host_wdata[7:0];
                end
                if (!rst && state == WRITEBACK && lane < active_n) begin
                    if (relu && next_k >= k)
                        outputs[c_index] <= {24'b0, quantized[7:0]};
                    else
                        outputs[c_index] <= merged;
                end
            end
        end
    endgenerate

    always @* begin
        host_rdata = 0;
        if (aligned) begin
            if (region == 0) begin
                case (host_addr)
                    14'h004: host_rdata = {29'b0, error, done, busy};
                    14'h008: host_rdata = {26'b0, m};
                    14'h00c: host_rdata = {26'b0, n};
                    14'h010: host_rdata = {26'b0, k};
                    14'h014: host_rdata = cycles;
                    14'h018: host_rdata = {26'b0, relu, shift};
                    default: host_rdata = 0;
                endcase
            end else if (region == 3 && done && !busy && matrix_index_valid &&
                         host_row < m && host_col < n) begin
                host_rdata = c_read[(host_col % SIZE)*32 +: 32];
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            error <= 0;
            m <= 0;
            n <= 0;
            k <= 0;
            relu <= 0;
            shift <= 0;
            cycles <= 0;
            tile_m <= 0;
            tile_n <= 0;
            tile_k <= 0;
            step <= 0;
            write_row <= 0;
            for (integer col = 0; col < DIM; col = col + 1)
                bias[col] <= 0;
        end else begin
            if (busy)
                cycles <= cycles + 1;
            if (host_valid && host_write && (!aligned || busy))
                error <= 1;

            case (state)
                IDLE: if (write_transaction && region == 0) begin
                    case (host_addr)
                        14'h000: begin
                            if (host_wdata[1])
                                error <= 0;
                            if (host_wdata[0]) begin
                                done <= 0;
                                cycles <= 0;
                                if (m == 0 || n == 0 || k == 0 || m > DIM || n > DIM || k > DIM) begin
                                    error <= 1;
                                end else begin
                                    tile_m <= 0;
                                    tile_n <= 0;
                                    tile_k <= 0;
                                    state <= CLEAR;
                                end
                            end
                        end
                        14'h008, 14'h00c, 14'h010: begin
                            if (host_addr == 14'h008)
                                m <= host_wdata <= DIM ? host_wdata[5:0] : 6'd0;
                            if (host_addr == 14'h00c)
                                n <= host_wdata <= DIM ? host_wdata[5:0] : 6'd0;
                            if (host_addr == 14'h010)
                                k <= host_wdata <= DIM ? host_wdata[5:0] : 6'd0;
                            done <= 0;
                        end
                        14'h018: begin
                            relu <= host_wdata[5];
                            shift <= host_wdata[4:0];
                        end
                        default: if (host_addr >= 14'h100 && host_addr < 14'h100 + DIM*4)
                            bias[(host_addr - 14'h100) >> 2] <= host_wdata;
                    endcase
                end
                CLEAR: begin
                    step <= 0;
                    state <= STREAM;
                end
                STREAM: if (step + 1 == stream_cycles) begin
                    write_row <= 0;
                    state <= WRITEBACK;
                end else begin
                    step <= step + 1;
                end
                WRITEBACK: if (write_row + 1 < active_m) begin
                    write_row <= write_row + 1;
                end else if (next_k < k) begin
                    tile_k <= next_k[5:0];
                    state <= CLEAR;
                end else if (next_n < n) begin
                    tile_k <= 0;
                    tile_n <= next_n[5:0];
                    state <= CLEAR;
                end else if (next_m < m) begin
                    tile_k <= 0;
                    tile_n <= 0;
                    tile_m <= next_m[5:0];
                    state <= CLEAR;
                end else begin
                    state <= IDLE;
                    done <= 1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
