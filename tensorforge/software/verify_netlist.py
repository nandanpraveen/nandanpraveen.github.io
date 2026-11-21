"""Verify the synthesized 8 × 8 accelerator at its register interface."""
import json

from model import train_model
from run import BUILD, basic_cases, execute, inference, run_cases

HARDWARE = BUILD / "hardware"


def main():
    binary = HARDWARE / "tensorforge-8x8.vvp"
    execute([
        "iverilog", "-g2012", "-DTF_GATE_LEVEL", "-s", "tb", "-P", "tb.SIZE=8",
        "-o", binary, HARDWARE / "tensorforge-8x8.v", "rtl/tf_serial.sv",
        "verification/tb.sv",
    ])
    selected = {
        "wavefront", "signed_extrema", "zero", "requant_edges", "requant_shift_zero",
        "requant_shift_31", "gemm_3x7x11", "gemm_8x8x8", "gemm_32x32x32",
    }
    cases = [case for case in basic_cases() if case.name in selected]
    measurements, _, _ = run_cases(binary, cases)
    print(f"PASS mapped netlist: {len(cases)} matrix workloads", flush=True)
    classification = inference(binary, *train_model())
    stats = json.loads((HARDWARE / "cells.json").read_text())
    report = {
        "target": "generic Yosys gates",
        "clock_model": "functional zero-delay gate simulation",
        "array": 8,
        "gate_cells": stats["design"]["num_cells"],
        "matrix_cases": [
            {"name": case.name, "cycles": measurements[i][0], "macs": measurements[i][2]}
            for i, case in enumerate(cases)
        ],
        "inference": {key: value for key, value in classification.items() if key != "examples"},
    }
    (HARDWARE / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"PASS {report['gate_cells']:,} mapped cells and {classification['samples']} "
          f"two-layer inference samples ({classification['quantized_correct']} correct)")


if __name__ == "__main__":
    main()
