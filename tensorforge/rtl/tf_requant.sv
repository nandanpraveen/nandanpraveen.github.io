module tf_requant (
    input wire signed [31:0] value, bias,
    input wire [4:0] shift,
    output reg signed [7:0] result
);
    wire signed [33:0] biased = {{2{value[31]}}, value} + {{2{bias[31]}}, bias};
    wire signed [33:0] rounding = shift == 0 ? 34'sd0 : (34'sd1 <<< (shift - 1'b1));
    wire signed [33:0] scaled = (biased + rounding) >>> shift;

    always @* begin
        if (biased <= 0)
            result = 0;
        else if (scaled > 127)
            result = 127;
        else
            result = scaled[7:0];
    end
endmodule
