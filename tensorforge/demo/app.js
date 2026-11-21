"use strict";
const data = window.TENSORFORGE_DATA;
const find = id => document.getElementById(id);
const formatMatrix = matrix => matrix.map(row => row.map(value => String(value).padStart(5)).join(" ")).join("\n");
const arraySelect = find("array");
const stepSlider = find("step");
const workloadSelect = find("workload");
const sampleSelect = find("sample");

function addOptions(select, options) {
  select.replaceChildren(...options.map(([value, label]) => new Option(label, value)));
}

function drawWavefront() {
  const size = Number(arraySelect.value);
  const trace = data.traces[size];
  const index = Number(stepSlider.value);
  const frame = trace.frames[index];
  const mask = BigInt("0x" + frame.mac_mask);
  const [tileRow, tileCol, tileDepth] = frame.tile;
  const cells = find("cells");
  const entries = [];
  cells.style.setProperty("--n", size);
  find("cycle").textContent = `RTL cycle ${frame.cycle} · Stream step ${index + 1}/${trace.frames.length} · Tile (${frame.tile.join(", ")})`;
  find("previous").disabled = index === 0;
  find("next").disabled = index === trace.frames.length - 1;
  for (let row = 0; row < size; row++) {
    for (let col = 0; col < size; col++) {
      const flat = row * size + col;
      const active = Boolean((mask >> BigInt(flat)) & 1n);
      const hexEnd = frame.sums_hex.length - flat * 8;
      const sum = Number.parseInt(frame.sums_hex.slice(hexEnd - 8, hexEnd), 16) | 0;
      const cell = document.createElement("div");
      cell.className = active ? "cell active" : "cell";
      cell.textContent = String(sum);
      cell.title = `PE (${row}, ${col}), accumulator ${sum}`;
      if (active) {
        const k = tileDepth + frame.step - row - col;
        const detail = document.createElement("small");
        detail.textContent = `${trace.a[tileRow + row][k]} × ${trace.b[k][tileCol + col]}`;
        cell.append(detail);
      }
      entries.push(cell);
    }
  }
  cells.replaceChildren(...entries);
  for (const [id, matrix] of [["matrix-a", trace.a], ["matrix-b", trace.b], ["matrix-c", trace.output]]) {
    find(id).textContent = formatMatrix(matrix);
  }
}

function resetWavefront() {
  stepSlider.max = data.traces[arraySelect.value].frames.length - 1;
  stepSlider.value = Math.min(2, Number(stepSlider.max));
  drawWavefront();
  drawSample();
}

function drawBenchmarks() {
  const rows = data.benchmarks.filter(row => row.case === workloadSelect.value);
  const largest = Math.max(...rows.map(row => row.cycles));
  const entries = rows.map(row => {
    const tr = document.createElement("tr");
    const values = [`${row.array} × ${row.array}`, row.cycles, row.serial_cycles,
      row.macs_per_cycle.toFixed(2), `${row.utilization_pct.toFixed(1)}%`];
    for (const [index, value] of values.entries()) {
      const cell = document.createElement(index === 0 ? "th" : "td");
      if (index === 0) cell.scope = "row";
      cell.textContent = value;
      if (index === 1) {
        const meter = document.createElement("meter");
        meter.min = 0;
        meter.max = largest;
        meter.value = row.cycles;
        meter.setAttribute("aria-hidden", "true");
        cell.append(meter);
      }
      tr.append(cell);
    }
    return tr;
  });
  find("measurements").replaceChildren(...entries);
}

function drawSample() {
  const info = data.inference[arraySelect.value];
  const names = ["Setosa", "Versicolor", "Virginica"];
  const example = info.examples[Number(sampleSelect.value)];
  find("classification").textContent = `Predicted ${names[example.prediction]} · actual ${names[example.label]}`;
  for (const field of ["features", "hidden", "logits"]) {
    find(field).textContent = example[field].join("  ");
  }
  find("accuracy").textContent = `${info.quantized_correct}/${info.samples} correct in quantized RTL · ${info.float_correct}/${info.samples} correct in the floating-point reference · ${info.cycles[0] + info.cycles[1]} RTL cycles for the full ${info.samples}-sample batch.`;
}

function parseMatrix(text) {
  const rows = text.trim().split(/\n+/).map(row => row.trim().split(/[\s,]+/));
  if (rows.length > 32 || rows[0].length > 32 || rows.some(row => row.length !== rows[0].length ||
      row.some(value => !/^[+-]?\d+$/.test(value) || Number(value) < -128 || Number(value) > 127))) {
    throw new Error("Use rectangular matrices up to 32 × 32 with integers from −128 to 127.");
  }
  return rows.map(row => row.map(Number));
}

function multiplyCustom() {
  const output = find("custom-product");
  try {
    const a = parseMatrix(find("custom-a").value);
    const b = parseMatrix(find("custom-b").value);
    if (a[0].length !== b.length) throw new Error("A’s column count must equal B’s row count.");
    const product = a.map(row => b[0].map((_, col) =>
      row.reduce((sum, value, k) => sum + value * b[k][col], 0)));
    find("custom-status").textContent = `Reference result · ${a.length} × ${b[0].length}`;
    output.textContent = formatMatrix(product);
  } catch (error) {
    find("custom-status").textContent = error.message;
    output.textContent = "";
  }
}

addOptions(arraySelect, data.sizes.map(size => [size, `${size} × ${size}`]));
arraySelect.value = String(data.sizes.includes(4) ? 4 : data.sizes[0]);
addOptions(workloadSelect, data.benchmarks.filter(row => row.array === data.sizes[0])
  .map(row => [row.case, `${row.m} × ${row.n} output, K = ${row.k}`]));
workloadSelect.value = "gemm_32x32x32";
addOptions(sampleSelect, data.inference[data.sizes[0]].examples.map((_, index) => [index, `Sample ${index + 1}`]));
arraySelect.addEventListener("change", resetWavefront);
stepSlider.addEventListener("input", drawWavefront);
find("previous").addEventListener("click", () => { stepSlider.stepDown(); drawWavefront(); });
find("next").addEventListener("click", () => { stepSlider.stepUp(); drawWavefront(); });
sampleSelect.addEventListener("change", drawSample);
workloadSelect.addEventListener("change", drawBenchmarks);
find("multiply").addEventListener("click", multiplyCustom);
resetWavefront();
drawBenchmarks();
multiplyCustom();
