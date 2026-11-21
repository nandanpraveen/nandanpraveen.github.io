# Limitations

- Matrices are limited to the synthesized scratchpad stride, at most 32 in each dimension. Larger operations require host-side partitioning.
- The simple one-owner host bus has no DMA or overlapping transfers. Copies and scalar register bandwidth can dominate short operations.
- The bank memories use asynchronous reads and Yosys reports them as coarse macros. Technology mapping, timing constraints, clock closure and device-specific RAM inference remain open.
- Verification uses unit and integration simulation plus synthesis checks. A formal proof and quantitative coverage instrumentation are outside the initial release.
- The inference result uses one fixed, small Iris holdout. Its accuracy and apparent quantization tolerance should not be generalized to larger models.
- The design was simulated and synthesized on a Mac. FPGA deployment and physical measurements remain future work.
