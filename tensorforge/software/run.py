"""Generate golden cases, run Icarus, verify outputs, and publish measured artifacts."""
import argparse
import csv
import json
import random
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from model import ROOT, argmax, train_model

BUILD = ROOT / "build"
RESULTS = ROOT / "results"
RTL = sorted(str(path.relative_to(ROOT)) for path in (ROOT / "rtl").glob("*.sv"))
SIZES = (2, 4, 8, 16)
SEED = 41041


def requantize(value, bias, shift):
    adjusted = max(0, value + bias)
    rounding = (1 << (shift - 1)) if shift else 0
    return min(127, (adjusted + rounding) >> shift)


@dataclass
class Case:
    name: str
    a: list
    b: list
    biases: list | None = None
    shift: int = 0

    @property
    def dims(self):
        return len(self.a), len(self.b[0]), len(self.b)

    def output(self):
        rows = [[sum(x * y for x, y in zip(row, col)) for col in zip(*self.b)] for row in self.a]
        if self.biases is not None:
            return [[requantize(value, bias, self.shift) for value, bias in zip(row, self.biases)] for row in rows]
        return rows

    def serialize(self):
        m, n, k = self.dims
        biases = [0] * n if self.biases is None else self.biases
        mode = 0 if self.biases is None else 32 + self.shift
        lines = [[m, n, k, mode], biases, *self.a, *self.b, *self.output()]
        return "\n".join(" ".join(map(str, line)) for line in lines)


def basic_cases():
    rng = random.Random(SEED)

    def matrix(rows, cols):
        return [[rng.randint(-128, 127) for _ in range(cols)] for _ in range(rows)]

    cases = [
        Case("wavefront", [[3, -2, 4], [1, 5, -3], [-2, 4, 1]],
             [[2, -1, 3], [0, 4, -2], [-3, 2, 1]]),
        Case("signed_extrema", [[-128, 127], [127, -128]], [[-128, 127], [127, -128]]),
        Case("zero", [[0]], [[-128]]),
        Case("requant_edges", [[0]], [[0, 0, 0, 0, 0, 0, 0, 0]],
             [-2147483648, -1, 0, 3, 4, 1019, 1020, 2147483647], 3),
        Case("requant_shift_zero", [[127]], [[127, -128]], [2147483647, -2147483648]),
        Case("requant_shift_31", [[127]], [[127, -128]], [1073741824, -2147483648], 31),
    ]
    for m, n, k in [(1, 1, 1), (3, 7, 11), (17, 13, 19), (32, 32, 32), (1, 32, 32), (32, 1, 32),
                    (8, 8, 8), (16, 16, 16), (5, 9, 17)]:
        cases.append(Case(f"gemm_{m}x{n}x{k}", matrix(m, k), matrix(k, n)))
    for index in range(20):
        m, n, k = (rng.randint(1, 23) for _ in range(3))
        biases = [rng.randint(-8192, 8192) for _ in range(n)] if index % 2 else None
        cases.append(Case(f"random_{index}", matrix(m, k), matrix(k, n), biases, rng.randrange(9)))
    return cases


def execute(command):
    return subprocess.run(list(map(str, command)), cwd=ROOT, check=True, text=True, capture_output=True).stdout


def compile_tb(size):
    target = BUILD / f"tb-{size}.vvp"
    execute(["iverilog", "-g2012", "-s", "tb", "-P", f"tb.SIZE={size}", "-o", target, *RTL, "verification/tb.sv"])
    return target


def run_cases(binary, cases, trace=False):
    with tempfile.NamedTemporaryFile(mode="w", dir=BUILD) as file:
        file.write(str(len(cases)) + "\n" + "\n".join(case.serialize() for case in cases) + "\n")
        file.flush()
        flags = ["+trace=0", f"+wave={BUILD / (binary.stem + '.vcd')}"] if trace else []
        try:
            log = execute(["vvp", binary, f"+vectors={file.name}", *flags])
        except subprocess.CalledProcessError as error:
            raise RuntimeError(f"{binary.name}:\n{error.stdout}\n{error.stderr}") from error
    metrics, frames = {}, []
    outputs = [[[None] * case.dims[1] for _ in range(case.dims[0])] for case in cases]
    for line in log.splitlines():
        if line.startswith("METRIC "):
            index, cycles, streams, macs, serial = map(int, line.split()[1:])
            metrics[index] = (cycles, streams, macs, serial)
        if line.startswith("TRACE "):
            _, cycle, tm, tn, tk, step, mask, sums = line.split()
            frames.append({"cycle": int(cycle), "tile": [int(tm), int(tn), int(tk)], "step": int(step),
                           "mac_mask": mask, "sums_hex": sums})
        if line.startswith("OUTPUT "):
            case, row, col, value = map(int, line.split()[1:])
            outputs[case][row][col] = value
    if len(metrics) != len(cases) or not re.search(r"^PASS size=", log, re.M):
        raise RuntimeError("RTL simulation did not report a complete regression")
    for idx, case in enumerate(cases):
        if outputs[idx] != case.output():
            raise RuntimeError(f"Golden output mismatch for {case.name}")
    return metrics, outputs, frames


def inference(binary, network, inputs, labels, floating):
    first_case = Case("iris_hidden", inputs, network["w1"], network["b1"], network["weight_shift"])
    first_metrics, first_result, _ = run_cases(binary, [first_case])
    second_case = Case("iris_logits", first_result[0], network["w2"])
    second_metrics, second_result, _ = run_cases(binary, [second_case])
    logits = [[value + bias for value, bias in zip(row, network["b2"])] for row in second_result[0]]
    predictions = [argmax(row) for row in logits]
    golden = [argmax([x + bias for x, bias in zip(row, network["b2"])]) for row in second_case.output()]
    assert predictions == golden
    return {
        "samples": len(labels),
        "float_correct": sum(a == b for a, b in zip(floating, labels)),
        "quantized_correct": sum(a == b for a, b in zip(predictions, labels)),
        "classification_agreement": sum(a == b for a, b in zip(predictions, floating)),
        "cycles": [first_metrics[0][0], second_metrics[0][0]],
        "examples": [{"features": x, "hidden": hidden, "logits": row, "prediction": prediction, "label": label}
                     for x, hidden, row, prediction, label in zip(inputs, first_result[0], logits, predictions, labels)],
    }


def run(sizes):
    BUILD.mkdir(exist_ok=True)
    RESULTS.mkdir(exist_ok=True)
    pe = BUILD / "pe.vvp"
    execute(["iverilog", "-g2012", "-s", "tb_pe", "-o", pe, "rtl/tf_pe.sv", "verification/tb_pe.sv"])
    print(execute(["vvp", pe]).splitlines()[0], flush=True)
    cases = basic_cases()
    network, inputs, labels, floating = train_model()
    records, traces, classifications = [], {}, {}
    for size in sizes:
        binary = compile_tb(size)
        metrics, outputs, frames = run_cases(binary, cases, trace=True)
        traces[str(size)] = {"a": cases[0].a, "b": cases[0].b, "output": outputs[0], "frames": frames}
        classifications[str(size)] = inference(binary, network, inputs, labels, floating)
        for index, case in enumerate(cases):
            cycles, streams, macs, serial = metrics[index]
            m, n, k = case.dims
            tiles = ((m+size-1)//size)*((n+size-1)//size)*((k+size-1)//size)
            records.append({
                "array": size, "case": case.name, "m": m, "n": n, "k": k,
                "cycles": cycles, "stream_cycles": streams, "tile_clears": tiles,
                "writeback_cycles": cycles-streams-tiles, "macs": macs, "serial_cycles": serial,
                "macs_per_cycle": round(macs/cycles, 6), "utilization_pct": round(100*macs/(cycles*size*size), 6),
                "serial_cycle_ratio": round(serial/cycles, 6),
            })
        print(f"PASS {size}×{size}: {len(cases)} GEMM cases and {len(labels)} two-layer RTL inference samples", flush=True)

    with (RESULTS / "benchmarks.csv").open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=records[0])
        writer.writeheader()
        writer.writerows(records)
    bundle = {"sizes": sizes, "traces": traces, "benchmarks": records, "inference": classifications, "model": network}
    (RESULTS / "rtl-results.json").write_text(json.dumps(bundle, separators=(",", ":")) + "\n")
    (ROOT / "demo" / "data.js").write_text("window.TENSORFORGE_DATA = " + json.dumps(bundle, separators=(",", ":")) + ";\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", type=int, choices=SIZES, action="append")
    args = parser.parse_args()
    run(tuple(args.size) if args.size else SIZES)
