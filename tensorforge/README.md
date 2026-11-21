# TensorForge

TensorForge is a synthesizable SystemVerilog accelerator for signed INT8 matrix multiplication and small neural networks. A parameterized output-stationary systolic array forwards operands between processing elements and accumulates INT32 dot products. Banked scratchpads, a tiled controller, and a memory-mapped register interface support rectangular matrices up to 32 × 32. The design also supports per-column bias, ReLU, rounded requantization, and saturation.

[Interactive demo](https://nandanpraveen.github.io/tensorforge/demo/) · [Architecture](docs/ARCHITECTURE.md) · [Verification](docs/VERIFICATION.md) · [Benchmarks](docs/BENCHMARKS.md)

## Results

- Each of the 2 × 2, 4 × 4, 8 × 8, and 16 × 16 configurations passed 35 directed and seeded matrix workloads, two full RTL GEMM passes for a trained Iris classifier, and output comparisons against an independent Python reference.
- The quantized 4 → 8 → 3 classifier matched the floating-point model on all 30 held-out predictions. Both got 29 of 30 correct, or 96.7%, on this split.
- For 32 × 32 × 32 GEMM, the 8 × 8 array used 1,984 simulated cycles versus 32,768 for the sequential RTL MAC reference. The 16 × 16 array used 504 cycles. These comparisons count RTL compute and scheduling cycles and exclude host transfers.
- Yosys completed coarse synthesis and structural checks for all four array configurations. Reports preserve multiplier and memory macros.

## Run on Apple Silicon or Linux

Install Python 3.10 or later, a C11 compiler, GNU Make, Icarus Verilog and Yosys. On macOS, Homebrew provides the formulae `icarus-verilog` and `yosys`. The [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) also supplies both in a standalone bundle. On Debian or Ubuntu, the package names are `iverilog` and `yosys`. No FPGA, GPU, Python packages or paid services are required.

```sh
make check
make hardware
make demo
```

Open http://127.0.0.1:8000 for the demo. The checkout already includes the captured data, so you can also open `demo/index.html` directly. `make test` refreshes the simulation and inference artifacts, `make synth` refreshes the synthesis report, and `make driver` compiles and tests the C driver. To debug a single configuration, run `python3 software/run.py --size 4`; its results are saved separately in `build/results-4/`. VCD waveforms are generated in `build/`.

The [engineering report](docs/REPORT.md) covers design decisions, scaling, and trade-offs. The [interview guide](docs/INTERVIEW.md) gives concrete modifications to try and explain.

`make hardware` builds the 8 × 8 accelerator as a generic gate-level Verilog netlist under `build/hardware/`. It uses Verilator 5 with timing support and a C++20 compiler to verify the mapped netlist through matrix and two-layer inference workloads. For an Icarus-only environment, use `make hardware GATE_SIM=iverilog`. The command saves `verification.json` beside the build. The netlist supports functional simulation without a target technology library. It has no FPGA pin assignments or timing constraints.
