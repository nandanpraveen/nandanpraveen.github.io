# Interview preparation

1. Sketch a 2 × 2 array and follow A[1,0] and B[0,1]. Row 1 and column 1 start one edge late, and both values take another hop to PE (1,1). They match at stream step 2.
2. Explain why output-stationary is convenient. Local INT32 accumulators avoid moving wide partials between PEs. A separate writeback merge still accumulates across reduction tiles.
3. Work out the timing for a full 8 × 8 × 8 tile. There is one clear, 22 stream clocks, and eight writeback clocks, or 31 total.
4. Explain why a 16 × 16 array takes the same 31 clocks for 8³. Its controller uses active tile dimensions while unused PEs sit idle.
5. Explain the bank layout. Modulo banking assigns simultaneous lane requests to distinct storage banks. A and B are banked along different logical dimensions so both can advance on the same clock.
6. Explain how to improve larger networks. Double buffering can overlap host loads with compute, deeper reduction tiles can reduce partial writebacks, and synchronous SRAM targeting needs an explicit feed pipeline and revised alignment.
7. Defend the reported 16.5× result. It is the ratio of sequential RTL MAC cycles to 8 × 8 accelerator cycles for one GEMM. Uploads, operating frequency, power, CPU latency, and physical silicon are outside that measurement.

## Resume bullets

- Built a parameterized SystemVerilog INT8 systolic accelerator with tiled GEMM, banked scratchpads, a register-mapped host interface, and a C driver. Validated four array sizes against 35 matrix workloads each and synthesized all four in Yosys.
- Reduced simulated 32³ GEMM from 32,768 serial-MAC cycles to 1,984 cycles on an 8 × 8 array and verified a quantized Iris MLP that matched the floating-point model on all 30 held-out predictions.
