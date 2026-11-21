module tf_array #(
    parameter integer SIZE = 4
) (
    input wire clk, rst, clear, advance,
    input wire [SIZE*8-1:0] left_data, top_data,
    input wire [SIZE-1:0] left_valid, top_valid,
    output wire [SIZE*SIZE*32-1:0] sums,
    output wire [SIZE*SIZE-1:0] mac_valid
);
    wire [SIZE*SIZE*8-1:0] a_links, b_links;
    wire [SIZE*SIZE-1:0] a_valid_links, b_valid_links;

    generate
        for (genvar row = 0; row < SIZE; row = row + 1) begin : rows
            for (genvar col = 0; col < SIZE; col = col + 1) begin : cols
                localparam integer CELL = row * SIZE + col;
                wire signed [7:0] a_in, b_in;
                wire a_valid_in, b_valid_in;
                if (col == 0) begin
                    assign a_in = left_data[row*8 +: 8];
                    assign a_valid_in = left_valid[row];
                end else begin
                    assign a_in = a_links[(CELL-1)*8 +: 8];
                    assign a_valid_in = a_valid_links[CELL-1];
                end
                if (row == 0) begin
                    assign b_in = top_data[col*8 +: 8];
                    assign b_valid_in = top_valid[col];
                end else begin
                    assign b_in = b_links[(CELL-SIZE)*8 +: 8];
                    assign b_valid_in = b_valid_links[CELL-SIZE];
                end
                assign mac_valid[row*SIZE+col] = advance && a_valid_in && b_valid_in;
                tf_pe pe (
                    .clk(clk), .rst(rst), .clear(clear), .advance(advance),
                    .a_in(a_in), .b_in(b_in), .a_valid_in(a_valid_in),
                    .b_valid_in(b_valid_in), .a_out(a_links[CELL*8 +: 8]),
                    .b_out(b_links[CELL*8 +: 8]), .a_valid_out(a_valid_links[CELL]),
                    .b_valid_out(b_valid_links[CELL]),
                    .sum(sums[(row*SIZE+col)*32 +: 32])
                );
            end
        end
    endgenerate
endmodule
