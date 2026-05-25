import {
  Chart,
  registerables,
} from "https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm";

Chart.register(...registerables);

const palette = ["#ea6a2a", "#127a78", "#1f4ca3", "#7e3f98", "#5d7a0f", "#b1456e"];
const chartRegistry = new Map();
const backendOrder = [
  "rust-nalgebra/native",
  "moonbit/native",
  "moonbit/js",
  "moonbit/wasm",
  "moonbit/wasm-gc",
];

let currentPhase = "warm";
let latestResults = { rows: [] };
let autoRefresh = true;

const operationsEl = document.getElementById("operations");
const overallChartEl = document.getElementById("overall-chart");

document.getElementById("rerun-full").addEventListener("click", () => triggerRun(false));
document.getElementById("rerun-smoke").addEventListener("click", () => triggerRun(true));
document.getElementById("auto-refresh").addEventListener("change", (event) => {
  autoRefresh = event.target.checked;
});

document.querySelectorAll(".phase-button").forEach((button) => {
  button.addEventListener("click", () => {
    currentPhase = button.dataset.phase;
    document.querySelectorAll(".phase-button").forEach((node) => node.classList.remove("active"));
    button.classList.add("active");
    render();
  });
});

function toMs(ns) {
  return ns / 1_000_000;
}

function sizeMetric(row) {
  const { rows, cols, rhs_cols } = row.shape;
  return rows * cols * Math.max(rhs_cols || cols, 1);
}

function groupedRows() {
  return latestResults.rows.filter((row) => row.phase === currentPhase && row.status === "ok");
}

function aggregateByBackend(rows) {
  const groups = new Map();
  for (const row of rows) {
    const key = `${row.toolchain}/${row.backend}`;
    const list = groups.get(key) ?? [];
    list.push(row.median_ns);
    groups.set(key, list);
  }
  return [...groups.entries()]
    .map(([key, values]) => ({
      key,
      value: values.reduce((sum, item) => sum + item, 0) / values.length,
    }))
    .sort((a, b) => compareBackendKey(a.key, b.key));
}

function groupByOperation(rows) {
  const groups = new Map();
  for (const row of rows) {
    const list = groups.get(row.operation) ?? [];
    list.push(row);
    groups.set(row.operation, list);
  }
  return [...groups.entries()].sort(([a], [b]) => a.localeCompare(b));
}

function panelTitle(operation) {
  return operation.replaceAll("_", " ");
}

function compareBackendKey(left, right) {
  const leftIndex = backendOrder.indexOf(left);
  const rightIndex = backendOrder.indexOf(right);
  const normalizedLeft = leftIndex === -1 ? Number.MAX_SAFE_INTEGER : leftIndex;
  const normalizedRight = rightIndex === -1 ? Number.MAX_SAFE_INTEGER : rightIndex;
  if (normalizedLeft !== normalizedRight) {
    return normalizedLeft - normalizedRight;
  }
  return left.localeCompare(right);
}

function logScaleMin(values) {
  const positives = values.filter((value) => value > 0);
  if (!positives.length) {
    return 0.001;
  }
  const minValue = Math.min(...positives);
  const exponent = Math.floor(Math.log10(minValue));
  return Math.pow(10, exponent);
}

function chartOptions({ title, minY = 0 } = {}) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    animation: false,
    interaction: {
      mode: "nearest",
      intersect: false,
    },
    plugins: {
      legend: {
        labels: {
          boxWidth: 10,
          boxHeight: 10,
          usePointStyle: true,
          pointStyle: "circle",
          color: "#4f5651",
          font: {
            family: "Avenir Next, Segoe UI, sans-serif",
            size: 12,
            weight: "600",
          },
        },
      },
      title: title
        ? {
            display: false,
            text: title,
          }
        : undefined,
      tooltip: {
        backgroundColor: "rgba(24, 32, 40, 0.92)",
        titleFont: {
          family: "Avenir Next, Segoe UI, sans-serif",
          size: 12,
          weight: "700",
        },
        bodyFont: {
          family: "Avenir Next, Segoe UI, sans-serif",
          size: 12,
        },
        padding: 12,
        displayColors: true,
      },
    },
    scales: {
      x: {
        grid: {
          display: false,
        },
        ticks: {
          color: "#5c635e",
          maxRotation: 42,
          minRotation: 42,
          font: {
            family: "Menlo, Monaco, Consolas, monospace",
            size: 11,
          },
        },
        border: {
          color: "rgba(24, 32, 40, 0.12)",
        },
      },
      y: {
        type: "logarithmic",
        min: minY,
        grid: {
          color: "rgba(24, 32, 40, 0.08)",
        },
        ticks: {
          color: "#5c635e",
          callback(value) {
            return `${Number(value).toFixed(value >= 1 ? 0 : 3)} ms`;
          },
          font: {
            family: "Menlo, Monaco, Consolas, monospace",
            size: 11,
          },
        },
        border: {
          color: "rgba(24, 32, 40, 0.12)",
        },
      },
    },
  };
}

function destroyChart(id) {
  const chart = chartRegistry.get(id);
  if (chart) {
    chart.destroy();
    chartRegistry.delete(id);
  }
}

function prepareChartHost(target, className = "") {
  target.textContent = "";
  const canvas = document.createElement("canvas");
  canvas.className = ["chart-canvas", className].filter(Boolean).join(" ");
  target.appendChild(canvas);
  return canvas;
}

function renderEmptyState(target, title) {
  target.innerHTML = `<p class="panel-subtle">${title}: no data yet.</p>`;
}

function renderBarChart(target, chartId, items, title) {
  destroyChart(chartId);
  if (!items.length) {
    renderEmptyState(target, title);
    return;
  }
  const valuesMs = items.map((item) => toMs(item.value));
  const canvas = prepareChartHost(target);
  const chart = new Chart(canvas, {
    type: "bar",
    data: {
      labels: items.map((item) => item.key),
      datasets: [
        {
          label: "Median runtime",
          data: valuesMs,
          backgroundColor: items.map((_, index) => palette[index % palette.length]),
          borderRadius: 0,
          borderSkipped: false,
          maxBarThickness: 66,
        },
      ],
    },
    options: {
      ...chartOptions({ title, minY: logScaleMin(valuesMs) }),
      layout: {
        padding: {
          top: 28,
        },
      },
      plugins: {
        ...chartOptions({ title, minY: logScaleMin(valuesMs) }).plugins,
        legend: {
          display: false,
        },
        tooltip: {
          ...chartOptions({ title, minY: logScaleMin(valuesMs) }).plugins.tooltip,
          callbacks: {
            label(context) {
              return `${context.dataset.label}: ${context.parsed.y.toFixed(2)} ms`;
            },
          },
        },
      },
      scales: {
        ...chartOptions({ title, minY: logScaleMin(valuesMs) }).scales,
        y: {
          ...chartOptions({ title, minY: logScaleMin(valuesMs) }).scales.y,
        },
      },
    },
    plugins: [
      {
        id: "valueLabels",
        afterDatasetsDraw(chartInstance) {
          const { ctx } = chartInstance;
          const meta = chartInstance.getDatasetMeta(0);
          ctx.save();
          ctx.fillStyle = "#4f5651";
          ctx.font = "600 11px Menlo, Monaco, Consolas, monospace";
          ctx.textAlign = "center";
          meta.data.forEach((bar, index) => {
            const value = items[index].value;
            ctx.fillText(`${toMs(value).toFixed(2)} ms`, bar.x, bar.y - 10);
          });
          ctx.restore();
        },
      },
    ],
  });
  chartRegistry.set(chartId, chart);
}

function renderLineChart(target, chartId, rows, title) {
  destroyChart(chartId);
  if (!rows.length) {
    renderEmptyState(target, title);
    return;
  }
  const grouped = new Map();
  for (const row of rows) {
    const key = `${row.toolchain}/${row.backend}`;
    const list = grouped.get(key) ?? [];
    list.push({
      x: sizeMetric(row),
      y: toMs(row.median_ns),
      caseId: row.case_id,
    });
    grouped.set(key, list);
  }

  const datasets = [...grouped.entries()]
    .sort(([left], [right]) => compareBackendKey(left, right))
    .map(([key, points], index) => {
    const color = palette[index % palette.length];
    return {
      label: key,
      data: points.sort((a, b) => a.x - b.x),
      parsing: false,
      borderColor: color,
      backgroundColor: `${color}22`,
      pointBackgroundColor: color,
      pointBorderColor: "#fffdf8",
      pointBorderWidth: 2,
      pointRadius: 4,
      pointHoverRadius: 5,
      borderWidth: 3,
      tension: 0,
      fill: false,
    };
    });
  const valuesMs = datasets.flatMap((dataset) => dataset.data.map((point) => point.y));

  const canvas = prepareChartHost(target);
  const chart = new Chart(canvas, {
    type: "line",
    data: {
      datasets,
    },
    options: {
      ...chartOptions({ title, minY: logScaleMin(valuesMs) }),
      plugins: {
        ...chartOptions({ title, minY: logScaleMin(valuesMs) }).plugins,
        tooltip: {
          ...chartOptions({ title, minY: logScaleMin(valuesMs) }).plugins.tooltip,
          callbacks: {
            title(items) {
              return items[0].dataset.label;
            },
            label(context) {
              return `size ${context.raw.x}, ${context.raw.y.toFixed(3)} ms`;
            },
            afterLabel(context) {
              return `case ${context.raw.caseId}`;
            },
          },
        },
      },
      scales: {
        x: {
          type: "linear",
          title: {
            display: true,
            text: "input size",
            color: "#5c635e",
            font: {
              family: "Menlo, Monaco, Consolas, monospace",
              size: 11,
            },
          },
          grid: {
            color: "rgba(24, 32, 40, 0.05)",
          },
          ticks: {
            color: "#5c635e",
            maxRotation: 0,
            font: {
              family: "Menlo, Monaco, Consolas, monospace",
              size: 11,
            },
          },
          border: {
            color: "rgba(24, 32, 40, 0.12)",
          },
        },
        y: {
          ...chartOptions({ title, minY: logScaleMin(valuesMs) }).scales.y,
          title: {
            display: true,
            text: "median runtime (ms)",
            color: "#5c635e",
            font: {
              family: "Menlo, Monaco, Consolas, monospace",
              size: 11,
            },
          },
        },
      },
    },
  });
  chartRegistry.set(chartId, chart);
}

function renderOperationPanels(rows) {
  const operations = groupByOperation(rows);
  for (const chartId of [...chartRegistry.keys()]) {
    if (chartId !== "overall") {
      destroyChart(chartId);
    }
  }
  operationsEl.innerHTML = operations.map(([operation, opRows]) => {
    const caseCount = opRows.length;
    return `
      <article class="panel operation-panel">
        <div class="operation-head">
          <div class="operation-copy">
            <h2 class="operation-title">${panelTitle(operation)}</h2>
            <p class="operation-note">One scaling curve and one backend comparison for ${caseCount} samples in the current ${currentPhase} phase.</p>
          </div>
        </div>
        <div class="operation-layout">
          <div class="chart-slot chart-card-shell">
            <p class="chart-slot-head">Scaling curve</p>
            <div class="chart-card" data-line-chart="${operation}"></div>
          </div>
          <div class="chart-slot chart-card-shell">
            <p class="chart-slot-head">Backend comparison</p>
            <div class="chart-card" data-bar-chart="${operation}"></div>
          </div>
        </div>
      </article>
    `;
  }).join("");

  for (const [operation, opRows] of operations) {
    const lineHost = document.querySelector(`[data-line-chart="${operation}"]`);
    const barHost = document.querySelector(`[data-bar-chart="${operation}"]`);
    renderLineChart(lineHost, `line:${operation}`, opRows, "Scaling curve");
    renderBarChart(barHost, `bar:${operation}`, aggregateByBackend(opRows), "Backend comparison");
  }
}

function render() {
  const rows = groupedRows();
  renderBarChart(overallChartEl, "overall", aggregateByBackend(rows), `Overall ${currentPhase} medians`);
  renderOperationPanels(rows);
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, options);
  if (!response.ok) {
    throw new Error(`${url} -> ${response.status}`);
  }
  return response.json();
}

async function refreshResults() {
  try {
    latestResults = await fetchJson("/api/results");
    render();
  } catch (error) {
    console.warn(error);
  }
}

async function refreshStatus() {
  try {
    await fetchJson("/api/status");
  } catch (error) {
    console.warn(error);
  }
}

async function triggerRun(smoke) {
  const includeRust = document.getElementById("include-rust").checked;
  const body = new URLSearchParams({
    include_rust: String(includeRust),
    smoke: String(smoke),
  });
  const response = await fetch("/api/run", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
  if (response.status === 409) {
    return;
  }
  await refreshStatus();
}

setInterval(() => {
  if (!autoRefresh) {
    return;
  }
  refreshStatus();
  refreshResults();
}, 2500);

await refreshStatus();
await refreshResults();
