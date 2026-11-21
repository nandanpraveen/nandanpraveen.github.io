# Verification

`make check` runs the host-driver C test, the PE test and end-to-end RTL regression, then Yosys structural synthesis. The reference generator and inference trainer use the Python standard library.

| Layer | Executed checks |
| --- | --- |
| Processing element | Synchronous reset and clear, valid forwarding, −128 × −128, mixed-sign accumulation, invalid input, and paused clock enable |
| Register interface | Reset, rejected zero dimensions, rejected unaligned and busy writes, host polling, output visibility, consecutive operations, and boundary addresses at DIM=32 |
| Arithmetic and tiling | 35 deterministic cases per configuration, including 20 seeded rectangular cases, signed extrema, degenerate dimensions, full-size matrices, and requantization with negative bias, ties, saturation, shift 0 and shift 31 |
| Independent baseline | A separate one-MAC RTL engine checks each raw dot product and its running cycle count during every workload |
| Iris classifier | Two RTL-layer jobs per array size, each evaluated on 30 held-out examples, with all 240 intermediate activations and 90 raw logits compared against the Python reference |
| C driver | Register addresses and byte packing, signed output, cycle reads, dimension validation, timeout, and busy handling against a deterministic fake bus |
| Synthesis | All four parameter sets elaborated, flattened and checked for structural errors with Yosys |

Each run of `make test` generates VCD waveforms. Open `build/tb-4.vcd` in GTKWave and add `trace_valid`, `trace_sums`, `tile_m`, `tile_n`, `tile_k` and `step` to inspect the first three-by-three multiplication. The web demo replays simulator-emitted accumulators and active bits for that workload.

Tests used Icarus Verilog 14.0 development build, Yosys 0.71+77, Python 3.14.6, and Apple clang on arm64 macOS. The repository also carries a standalone GitHub Actions workflow under its project root for running the same commands on Linux.
