module tf_pe (
    input wire clk, rst, clear, advance,
    input wire signed [7:0] a_in, b_in,
    input wire a_valid_in, b_valid_in,
    output reg signed [7:0] a_out, b_out,
    output reg a_valid_out, b_valid_out,
    output reg signed [31:0] sum
);
    wire signed [15:0] product = a_in * b_in;

    always @(posedge clk) begin
        if (rst || clear) begin
            a_out <= 0;
            b_out <= 0;
            a_valid_out <= 0;
            b_valid_out <= 0;
            sum <= 0;
        end else if (advance) begin
            a_out <= a_in;
            b_out <= b_in;
            a_valid_out <= a_valid_in;
            b_valid_out <= b_valid_in;
            if (a_valid_in && b_valid_in)
                sum <= sum + {{16{product[15]}}, product};
        end
    end
endmodule
