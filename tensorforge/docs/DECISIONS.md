# Design decisions

- Output-stationary PEs retain INT32 partial sums and only forward INT8 operands. Weight-stationary would favor weight reuse across repeated input batches but adds a different loading and accumulation schedule. Output-stationary kept the first implementation and verification model straightforward.
- Three banked scratchpads give the array a predictable supply of input and weight lanes. Banking also lets writeback handle one row per cycle. Small logical memories use asynchronous reads for the initial implementation.
- Runtime M, N and K control active lanes and tile boundaries. Array size and scratchpad stride are elaboration parameters, so synthesis tools can resolve constant bank division and selection.
- Iris keeps training and two-layer inference reproducible on a standard Python installation. The fixed-point interface is small enough for bit-exact inspection by hand. The two-layer model supplies a full functional demonstration with a limited dataset.
- Cycle comparisons use an independent sequential RTL compute baseline. No clock frequency is assumed, so the study does not report physical speedup or GOPS.
