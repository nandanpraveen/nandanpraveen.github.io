// Compute-only reference that accepts one pair per cycle from scratchpad ports.
module tf_serial (
    input wire clk, rst, start,
    input wire [5:0] m, n, k,
    input wire signed [7:0] a, b,
    output reg [5:0] row, col, inner,
    output reg active,
    output wire output_valid,
    output wire signed [31:0] result
);
    reg signed [31:0] partial;
    wire signed [15:0] product = a * b;
    assign result = partial + {{16{product[15]}}, product};
    assign output_valid = active && inner + 1 == k;

    always @(posedge clk) begin
        if (rst || start) begin
            row <= 0;
            col <= 0;
            inner <= 0;
            partial <= 0;
            active <= !rst;
        end else if (active) begin
            if (output_valid) begin
                inner <= 0;
                partial <= 0;
                if (col + 1 == n) begin
                    col <= 0;
                    if (row + 1 == m)
                        active <= 0;
                    else
                        row <= row + 1;
                end else begin
                    col <= col + 1;
                end
            end else begin
                inner <= inner + 1;
                partial <= result;
            end
        end
    end
endmodule
