# Benchmarks

Reproduce the simulation measurements with `make test`. The raw values are in [benchmarks.csv](../results/benchmarks.csv), and synthesis details are in [synthesis.json](../results/synthesis.json).

## 32 × 32 × 32 GEMM

The testbench counts 32,768 useful multiply-accumulates. The separate sequential RTL baseline issues one multiply-accumulate per logical clock and uses 32,768 cycles. Host transfers are excluded from both counts.

| Array | Clock cycles | Stream | Tile clear | Writeback | MACs/clock | PE utilization | Serial/array cycle ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 × 2 | 28,672 | 16,384 | 4,096 | 8,192 | 1.14 | 28.6% | 1.14× |
| 4 × 4 | 7,680 | 5,120 | 512 | 2,048 | 4.27 | 26.7% | 4.27× |
| 8 × 8 | 1,984 | 1,408 | 64 | 512 | 16.52 | 25.8% | 16.52× |
| 16 × 16 | 504 | 368 | 8 | 128 | 65.02 | 25.4% | 65.02× |

Utilization is useful MACs / (elapsed accelerator cycles × PE count). The rectangular 17 × 13 × 19 workload takes 417 cycles on 8 × 8 and 154 cycles on 16 × 16. Utilization drops from 15.7% to 10.7% because partial tiles leave more PEs unused. On 8 × 8 × 8 GEMM both sizes take 31 cycles, with 25.8% and 6.5% utilization respectively. Input reuse and parallel writes improve cycle counts. Clears, fill/drain, writeback, and idle lanes explain the gap from peak throughput.

## Iris classifier

A fixed-seed stratified split uses 120 samples for training and 30 for evaluation. Feature scaling uses training statistics. The model is a 4 → 8 → 3 MLP with one ReLU, trained for 100 epochs. The same frozen INT8 model runs on all four RTL configurations.

| Array | Hidden-layer cycles | Logit-layer cycles | Total RTL cycles for 30 samples |
| --- | ---: | ---: | ---: |
| 2 × 2 | 840 | 780 | 1,620 |
| 4 × 4 | 232 | 216 | 448 |
| 8 × 8 | 104 | 100 | 204 |
| 16 × 16 | 82 | 80 | 162 |

The floating-point model got 29/30 correct. The RTL model got 29/30 correct and agreed with the floating-point classifications for all 30 samples. Quantization changed the measured accuracy by 0 percentage points on this split. These are small-sample demonstration results. The cycle totals exclude host transfers and the host-side addition of final biases and argmax.

## Coarse synthesis

| Array | Yosys cells | Multiplier cells | Memory macros |
| --- | ---: | ---: | ---: |
| 2 × 2 | 366 | 4 | 7 |
| 4 × 4 | 618 | 16 | 13 |
| 8 × 8 | 1,406 | 64 | 25 |
| 16 × 16 | 4,134 | 256 | 49 |

Counts include coarse Yosys operators and preserved memory macros. They describe structural scaling. No target LUT, gate area, physical frequency, power or fabricated silicon performance is inferred from them.
