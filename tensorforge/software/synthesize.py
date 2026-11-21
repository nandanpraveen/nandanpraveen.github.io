"""Collect Yosys coarse synthesis counts with RAM and arithmetic cells preserved."""
import concurrent.futures
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = " ".join(str(p.relative_to(ROOT)) for p in sorted((ROOT / "rtl").glob("*.sv")))
SIZES = (2, 4, 8, 16)


def synth(size):
    output = Path("build") / f"synth-{size}.json"
    script = (
        f"read_verilog -sv {FILES}; "
        f"chparam -set SIZE {size} tf_accelerator; "
        "hierarchy -check -top tf_accelerator; proc; opt; flatten; opt; "
        f"memory -nomap; opt; check -assert; tee -q -o {output} stat -json"
    )
    log = ROOT / "build" / f"synth-{size}.log"
    with log.open("w") as file:
        subprocess.run(["yosys", "-T", "-p", script], cwd=ROOT, check=True, stdout=file, stderr=subprocess.STDOUT)
    design = json.loads((ROOT / output).read_text())["design"]
    cells = design["num_cells_by_type"]
    return {
        "array": size, "total_cells": design["num_cells"], "multipliers": cells.get("$mul", 0),
        "register_cells": sum(count for name, count in cells.items() if "dff" in name),
        "memory_macros": cells.get("$mem_v2", 0), "cells_by_type": cells,
    }


def run():
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(synth, SIZES))
    version = subprocess.check_output(["yosys", "-V"], text=True).strip()
    report = {"tool": version, "stage": "coarse RTL synthesis, no target technology", "configurations": results}
    (ROOT / "results" / "synthesis.json").write_text(json.dumps(report, indent=2) + "\n")
    for result in results:
        print(f"PASS Yosys {result['array']}×{result['array']}: {result['total_cells']} coarse cells, "
              f"{result['multipliers']} multiplier cells, {result['memory_macros']} memory macros")


if __name__ == "__main__":
    run()
