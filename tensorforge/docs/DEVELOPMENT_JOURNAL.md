# Development journal

## RTL and verification

I started with a signed MAC and checked the extreme INT8 values before assembling the array. The first array regression only produced a result at the corner PE. The RTL testbench exposed unknown valid bits, and Yosys identified undriven neighbor nets. Connecting each PE output to the corresponding slice of the link bus fixed both failures.

## Inference and measurement

I trained a small Iris classifier and passed its held-out data through both RTL layers. The first layer applies bias, ReLU, rounding and saturation in writeback. The host adds final bias to the raw logits. All 30 quantized predictions matched the floating-point model, including the one error.

## Scaling and demonstration

I measured all four configurations on the same inputs. The 16 × 16 array was faster in cycles on the larger matrices, while the 8 × 8 and 16 × 16 arrays tied on 8³ GEMM. I exported simulator values for the browser demo so the stepping view shows the same accumulators as the RTL testbench.
