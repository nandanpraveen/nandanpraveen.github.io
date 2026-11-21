`timescale 1ns/1ps
module tb;
    parameter integer SIZE = 4;
    localparam integer DIM = 32;
    reg clk = 0;
    always #5 clk = !clk;
    reg rst = 1, host_valid = 0, host_write = 0;
    reg [13:0] host_addr = 0;
    reg [31:0] host_wdata = 0;
    wire host_ready, trace_advance;
    wire [31:0] host_rdata;
    wire [SIZE*SIZE-1:0] trace_valid;
    wire [SIZE*SIZE*32-1:0] trace_sums;
`ifdef TF_GATE_LEVEL
    tf_accelerator dut (.*);
`else
    tf_accelerator #(.SIZE(SIZE), .DIM(DIM)) dut (.*);
`endif

    reg serial_start = 0;
    reg [5:0] m, n, k;
    reg signed [7:0] a_matrix [0:DIM*DIM-1];
    reg signed [7:0] b_matrix [0:DIM*DIM-1];
    wire [5:0] baseline_row, baseline_col, baseline_inner;
    wire baseline_active, baseline_valid;
    wire signed [31:0] baseline_result;
    tf_serial baseline (
        .clk(clk), .rst(rst), .start(serial_start), .m(m), .n(n), .k(k),
        .a(a_matrix[baseline_row*DIM + baseline_inner]),
        .b(b_matrix[baseline_inner*DIM + baseline_col]), .row(baseline_row),
        .col(baseline_col), .inner(baseline_inner), .active(baseline_active),
        .output_valid(baseline_valid), .result(baseline_result)
    );

    integer case_id = -1, trace_case = -1, macs = 0, streams = 0, tb_cycle = 0;
    integer serial_cycles = 0;
    reg [SIZE*SIZE-1:0] sampled_valid;
    integer sampled_step;
    integer signed expected_raw [0:DIM*DIM-1];

    always @(posedge clk) begin
        if (trace_advance && !rst) begin
            sampled_valid = trace_valid;
            macs = macs + $countones(sampled_valid);
            streams = streams + 1;
`ifndef TF_GATE_LEVEL
            sampled_step = dut.step;
            if (case_id == trace_case) begin
                #1;
                $display("TRACE %0d %0d %0d %0d %0d %h %h",
                         dut.cycles, dut.tile_m, dut.tile_n, dut.tile_k, sampled_step,
                         sampled_valid, trace_sums);
            end
`endif
        end
    end

    always @(posedge clk) begin
        if (baseline_active && !rst) begin
            serial_cycles = serial_cycles + 1;
            if (baseline_valid && baseline_result !== expected_raw[baseline_row*DIM + baseline_col])
                $fatal(1, "serial baseline mismatch at %0d,%0d", baseline_row, baseline_col);
        end
    end

    task automatic bus_write(input [13:0] addr, input [31:0] val);
        @(negedge clk);
        host_addr = addr;
        host_wdata = val;
        host_valid = 1;
        host_write = 1;
        @(posedge clk);
        if (!host_ready) $fatal(1, "host write not acknowledged");
        #1;
        host_valid = 0;
        host_write = 0;
    endtask

    task automatic bus_read(input [13:0] addr, output [31:0] val);
        @(negedge clk);
        host_addr = addr;
        host_valid = 1;
        @(posedge clk);
        if (!host_ready) $fatal(1, "host read not acknowledged");
        val = host_rdata;
        #1;
        host_valid = 0;
    endtask

    integer fd, cases, rows, cols, depth, mode, value, scan, row, col, inner, dot;
    integer work_cycles, expected, max_wait;
    reg [31:0] status, actual;
    string vectors, waveform;

    initial begin
        if (!$value$plusargs("vectors=%s", vectors)) $fatal(1, "missing vectors");
`ifndef TF_GATE_LEVEL
        if ($value$plusargs("wave=%s", waveform)) begin
            $dumpfile(waveform);
            $dumpvars(0, clk, rst, dut.state, dut.step, dut.tile_m, dut.tile_n,
                         dut.tile_k, trace_valid, trace_sums);
        end
`endif
        scan = $value$plusargs("trace=%d", trace_case);
        fd = $fopen(vectors, "r");
        if (fd == 0) $fatal(1, "could not read vectors");
        if ($fscanf(fd, "%d", cases) != 1 || cases < 1) $fatal(1, "invalid case count");
        repeat (2) @(negedge clk);
        rst = 0;
        bus_write(0, 1);
        bus_read(4, status);
        if (status !== 4) $fatal(1, "invalid dimensions accepted");
        bus_write(0, 2);
        bus_write(1, 0);
        bus_read(4, status);
        if (status !== 4) $fatal(1, "unaligned write accepted");
        bus_write(0, 2);
        for (case_id = 0; case_id < cases; case_id = case_id + 1) begin
            if ($fscanf(fd, "%d %d %d %d", rows, cols, depth, mode) != 4)
                $fatal(1, "missing case header");
            m = rows;
            n = cols;
            k = depth;
            bus_write(8, rows);
            bus_write(12, cols);
            bus_write(16, depth);
            bus_write(24, mode);
            for (col = 0; col < cols; col = col + 1) begin
                if ($fscanf(fd, "%d", value) != 1) $fatal(1, "missing bias");
                bus_write('h100 + col*4, value);
            end
            for (row = 0; row < rows; row = row + 1)
                for (inner = 0; inner < depth; inner = inner + 1) begin
                    if ($fscanf(fd, "%d", value) != 1) $fatal(1, "missing activation");
                    a_matrix[row*DIM + inner] = value;
                    bus_write('h1000 + (row*DIM + inner)*4, value);
                end
            for (inner = 0; inner < depth; inner = inner + 1)
                for (col = 0; col < cols; col = col + 1) begin
                    if ($fscanf(fd, "%d", value) != 1) $fatal(1, "missing weight");
                    b_matrix[inner*DIM + col] = value;
                    bus_write('h2000 + (inner*DIM + col)*4, value);
                end
            for (row = 0; row < rows; row = row + 1)
                for (col = 0; col < cols; col = col + 1) begin
                    dot = 0;
                    for (inner = 0; inner < depth; inner = inner + 1)
                        dot = dot + a_matrix[row*DIM + inner] * b_matrix[inner*DIM + col];
                    expected_raw[row*DIM + col] = dot;
                end

            bus_read('h3000, actual);
            if (actual !== 0) $fatal(1, "stale output");
            macs = 0;
            streams = 0;
            serial_cycles = 0;
            bus_write(0, 3);
            if (case_id == 0) begin
                bus_write(8, 9);
                bus_read(4, status);
                if (!status[2]) $fatal(1, "busy write failed to set error");
            end
            @(negedge clk);
            serial_start = 1;
            @(negedge clk);
            serial_start = 0;
            status = 1;
            for (max_wait = 0; status[0] && max_wait < 200000; max_wait = max_wait + 1)
                bus_read(4, status);
            if (status[1:0] !== 2 || (case_id != 0 && status[2]))
                $fatal(1, "unexpected completion status %h", status);
            bus_read(20, actual);
            work_cycles = actual;

            for (row = 0; row < rows; row = row + 1)
                for (col = 0; col < cols; col = col + 1) begin
                    if ($fscanf(fd, "%d", expected) != 1) $fatal(1, "missing expected output");
                    bus_read('h3000 + (row*DIM + col)*4, actual);
                    if ($signed(actual) !== expected)
                        $fatal(1, "case %0d cell %0d,%0d: got %0d expected %0d",
                               case_id, row, col, $signed(actual), expected);
                    $display("OUTPUT %0d %0d %0d %0d", case_id, row, col, $signed(actual));
                end

            wait (!baseline_active);
            if (serial_cycles != rows*cols*depth || macs != rows*cols*depth)
                $fatal(1, "MAC counter mismatch");
            $display("METRIC %0d %0d %0d %0d %0d",
                     case_id, work_cycles, streams, macs, serial_cycles);
        end
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;
        bus_read(4, status);
        if (status !== 0) $fatal(1, "reset did not clear status");
        $fclose(fd);
        $display("PASS size=%0d cases=%0d", SIZE, cases);
        $finish;
    end
endmodule
