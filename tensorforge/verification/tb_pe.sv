`timescale 1ns/1ps
module tb_pe;
    reg clk = 0;
    always #5 clk = !clk;
    reg rst = 1, clear = 0, advance = 1;
    reg signed [7:0] a_in = 0, b_in = 0;
    reg a_valid_in = 0, b_valid_in = 0;
    wire signed [7:0] a_out, b_out;
    wire a_valid_out, b_valid_out;
    wire signed [31:0] sum;
    tf_pe dut (.*);

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    initial begin
        tick();
        if (sum !== 0) $fatal(1, "reset");
        rst = 0;
        a_in = -128;
        b_in = -128;
        a_valid_in = 1;
        b_valid_in = 1;
        tick();
        if (sum !== 16384 || a_out !== -8'sd128 || b_out !== -8'sd128 ||
            !a_valid_out || !b_valid_out) $fatal(1, "signed extrema or forwarding");
        a_in = 127;
        tick();
        if (sum !== 128) $fatal(1, "signed accumulation");
        a_valid_in = 0;
        tick();
        if (sum !== 128 || a_valid_out) $fatal(1, "invalid input");
        advance = 0;
        a_valid_in = 1;
        tick();
        if (sum !== 128 || a_valid_out) $fatal(1, "advance stall");
        clear = 1;
        tick();
        if (sum !== 0 || b_valid_out) $fatal(1, "synchronous clear");
        $display("PASS tf_pe");
        $finish;
    end
endmodule
