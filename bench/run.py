#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import math
import os
import platform
import re
import shlex
import shutil
import statistics
import subprocess
import sys
import time
from collections.abc import Callable
from dataclasses import asdict, dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = ROOT / "bench" / "datasets"
RESULTS_DIR = ROOT / "bench" / "results"
RAW_DIR = RESULTS_DIR / "raw"
RUST_DIR = ROOT / "bench" / "rust_baseline"
RUST_CRITERION_DIR = RUST_DIR / "target" / "criterion"
MOONBIT_TARGETS = ("native", "js", "wasm", "wasm-gc")
BENCHMARK_MODE = "steady_state"
MOONBIT_RELEASE_ARGS = ("--release",)
RUST_BENCH_PROFILE = "bench"
RUST_SUPPORTED_OPS = {
    "mul",
    "mul_vec",
    "determinant",
    "inverse",
    "rank",
    "reduce_row_elimination",
    "cholesky_decomposition",
    "eigen",
    "power_method",
}
MOON_SAMPLE_COUNT = 15
MOON_WARMUP_NS = 250_000_000
MOON_MEASUREMENT_NS = 1_000_000_000
MOON_TARGET_SAMPLE_NS = MOON_MEASUREMENT_NS // MOON_SAMPLE_COUNT
MOON_MAX_REPEAT = 1_000_000
DIAGNOSTIC_KIND = "diagnostic"
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
DETAIL_WIDTH = 34
RESET = "\033[0m"
BACKEND_COLORS = {
    "native": "\033[32m",
    "js": "\033[33m",
    "wasm": "\033[34m",
    "wasm-gc": "\033[35m",
    "rust": "\033[38;5;208m",
}


def log(message: str) -> None:
    print(message, flush=True)


def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def format_ns(ns: int) -> str:
    if ns >= 1_000_000_000:
        return f"{ns / 1_000_000_000:.2f}s"
    if ns >= 1_000_000:
        return f"{ns / 1_000_000:.2f}ms"
    if ns >= 1_000:
        return f"{ns / 1_000:.2f}us"
    return f"{ns}ns"


def visible_len(text: str) -> int:
    return len(ANSI_RE.sub("", text))


def truncate_text(text: str, width: int) -> str:
    if width <= 0:
        return ""
    if len(text) <= width:
        return text.ljust(width)
    if width <= 3:
        return "." * width
    return text[: width - 3] + "..."


def backend_badge(toolchain: str, backend: str, *, color: bool) -> str:
    badge = f"[{'rust' if toolchain.startswith('rust') else f'mbt/{backend}'}]"
    if not color:
        return badge
    key = "rust" if toolchain.startswith("rust") else backend
    prefix = BACKEND_COLORS.get(key, "")
    return badge if not prefix else f"{prefix}{badge}{RESET}"


def fixed_detail(left: str, badge: str, width: int) -> str:
    badge_width = visible_len(badge)
    spacer = 1 if left else 0
    left_width = max(0, width - badge_width - spacer)
    clipped = truncate_text(left, left_width)
    return f"{clipped}{' ' if left_width > 0 else ''}{badge}".rstrip()


class Progress:
    def __init__(self, total: int):
        self.total = max(1, total)
        self.done = 0
        self.start_ns = time.perf_counter_ns()
        self.is_tty = sys.stdout.isatty()
        self.last_width = 0
        self.pulse = 0
        self.activity_frames = [
            "[=   ]",
            "[==  ]",
            "[=== ]",
            "[ ===]",
            "[  ==]",
            "[   =]",
            "[  ==]",
            "[ ===]",
        ]
        self.last_render_ns = 0

    def tick(self, detail: str) -> None:
        self.done += 1
        self._render(detail)

    def update(self, detail: str) -> None:
        self._render(detail, advance=False)

    def finish(self, detail: str) -> None:
        self.done = self.total
        self._render(detail, final=True)

    def _render(self, detail: str, final: bool = False, advance: bool = True) -> None:
        width = 28
        filled = int(width * self.done / self.total)
        bar = "#" * filled + "-" * (width - filled)
        elapsed = format_ns(time.perf_counter_ns() - self.start_ns)
        spinner = " "
        activity = "[done]"
        if not final:
            frames = "|/-\\"
            spinner = frames[self.pulse % len(frames)]
            activity = self.activity_frames[self.pulse % len(self.activity_frames)]
            self.pulse += 1
        state = "done" if final else ("step" if advance else "wait")
        line = (
            f"{spinner} {activity} [{bar}] {self.done:>3}/{self.total}  "
            f"{state:<4}  {detail}  elapsed {elapsed}"
        )
        line = self._fit_line(line)
        if self.is_tty:
            line_width = visible_len(line)
            padding = max(0, self.last_width - line_width)
            end = "\n" if final else "\r"
            print(line + (" " * padding), end=end, flush=True)
            self.last_width = line_width
        else:
            print(line, flush=True)

    def heartbeat(self, detail: str, min_interval_ms: int = 120) -> None:
        if not self.is_tty:
            return
        now = time.perf_counter_ns()
        if now - self.last_render_ns < min_interval_ms * 1_000_000:
            return
        self.last_render_ns = now
        self._render(detail, advance=False)

    def _fit_line(self, line: str) -> str:
        if not self.is_tty:
            return line
        width = shutil.get_terminal_size(fallback=(120, 20)).columns
        line_width = visible_len(line)
        if width <= 0 or line_width <= width:
            return line
        elapsed_marker = "  elapsed "
        marker_index = line.rfind(elapsed_marker)
        if marker_index == -1:
            raw = ANSI_RE.sub("", line)
            return raw[: max(0, width - 3)] + "..."
        prefix = line[:marker_index]
        suffix = line[marker_index:]
        available = width - visible_len(suffix)
        if available <= 3:
            raw = ANSI_RE.sub("", line)
            return raw[: max(0, width - 3)] + "..."
        if visible_len(prefix) <= available:
            return prefix + suffix
        raw_prefix = ANSI_RE.sub("", prefix)
        return raw_prefix[: max(0, available - 3)] + "..." + suffix


@dataclass(frozen=True)
class Shape:
    rows: int
    cols: int
    rhs_cols: int


@dataclass(frozen=True)
class CaseMeta:
    case_id: str
    operation: str
    family: str
    workload_tier: str
    structure: str
    timing_scope: str
    input_layout: str
    mutation_policy: str
    size_tier: str
    cost_model: str
    case_path: str
    shape: Shape


@dataclass(frozen=True)
class MetricSummary:
    median_ns: int
    p90_ns: int
    mad_ns: int


@dataclass(frozen=True)
class BenchmarkRow:
    toolchain: str
    backend: str
    operation: str
    case_id: str
    family: str
    workload_tier: str
    structure: str
    timing_scope: str
    input_layout: str
    mutation_policy: str
    size_tier: str
    cost_model: str
    shape: Shape
    samples: list[int] = field(default_factory=list)
    median_ns: int = 0
    p90_ns: int = 0
    mad_ns: int = 0
    throughput_elements_per_s: float = 0.0
    throughput_estimated_flops_per_s: float | None = None
    throughput_estimated_bytes_per_s: float | None = None
    normalization_basis: str = "elements"
    checksum: str = ""
    status: str = "ok"

    def to_dict(self) -> dict[str, object]:
        payload = asdict(self)
        payload["shape"] = asdict(self.shape)
        return payload


@dataclass(frozen=True)
class MeasurementMetadata:
    tool: str
    sample_count: int
    warmup_ns: int
    target_sample_ns: int
    repeat_count: int
    launcher: str
    calibration_policy: str
    scratch_preparation_excluded: bool
    repeat_strategy: str


@dataclass(frozen=True)
class RunContext:
    started_at: str
    dataset_version: str
    include_rust: bool
    targets: list[str]
    smoke: bool
    environment: dict[str, str]
    mode: str = BENCHMARK_MODE


@dataclass(frozen=True)
class DiagnosticPayload:
    checksum: str


@dataclass(frozen=True)
class MoonBenchmarkPayload:
    samples: list[int]
    repeat_count: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run steady-state backend benchmarks.")
    parser.add_argument(
        "--targets",
        nargs="+",
        default=list(MOONBIT_TARGETS),
        choices=MOONBIT_TARGETS,
    )
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--include-rust", action="store_true")
    parser.add_argument("--ci", action="store_true")
    parser.add_argument("--target-dir", default="")
    env_args = shlex.split(os.environ.get("BENCH_FLAGS", ""))
    return parser.parse_args(env_args + sys.argv[1:])


def run(
    cmd: list[str],
    cwd: Path = ROOT,
    check: bool = True,
    heartbeat: Callable[[], None] | None = None,
) -> subprocess.CompletedProcess[str]:
    if heartbeat is None:
        return subprocess.run(
            cmd,
            cwd=cwd,
            check=check,
            text=True,
            capture_output=True,
        )
    process = subprocess.Popen(
        cmd,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    assert process.stderr is not None
    while process.poll() is None:
        heartbeat()
        time.sleep(0.12)
    stdout, stderr = process.communicate()
    completed = subprocess.CompletedProcess(
        cmd,
        process.returncode,
        stdout=stdout,
        stderr=stderr,
    )
    if check and completed.returncode != 0:
        raise subprocess.CalledProcessError(
            completed.returncode,
            cmd,
            output=stdout,
            stderr=stderr,
        )
    return completed


def with_target_dir(cmd: list[str], target_dir: str) -> list[str]:
    if not target_dir:
        return cmd
    return cmd[:1] + ["--target-dir", target_dir] + cmd[1:]


def load_manifest() -> tuple[str, list[CaseMeta]]:
    manifest = json.loads((DATASET_DIR / "manifest.json").read_text(encoding="utf-8"))
    cases = [
        CaseMeta(
            case_id=item["case_id"],
            operation=item["operation"],
            family=item["family"],
            workload_tier=item["workload_tier"],
            structure=item["structure"],
            timing_scope=item["timing_scope"],
            input_layout=item["input_layout"],
            mutation_policy=item["mutation_policy"],
            size_tier=item["size_tier"],
            cost_model=item["cost_model"],
            case_path=str(DATASET_DIR / "cases" / f'{item["case_id"]}.json'),
            shape=Shape(
                rows=item["shape"]["rows"],
                cols=item["shape"]["cols"],
                rhs_cols=item["shape"]["rhs_cols"],
            ),
        )
        for item in manifest["cases"]
    ]
    return manifest["dataset_version"], cases


def select_smoke_cases(cases: list[CaseMeta]) -> list[CaseMeta]:
    selected: list[CaseMeta] = []
    seen_operations: set[str] = set()
    for case in cases:
        if case.operation in seen_operations:
            continue
        if case.workload_tier == "baseline" and case.size_tier == "medium":
            selected.append(case)
            seen_operations.add(case.operation)
    for case in cases:
        if case.operation in seen_operations:
            continue
        if case.workload_tier == "baseline":
            selected.append(case)
            seen_operations.add(case.operation)
    return selected


def metric_summary(median_ns: int, p90_ns: int | None = None, mad_ns: int = 0) -> MetricSummary:
    resolved_p90 = median_ns if p90_ns is None else p90_ns
    return MetricSummary(median_ns=median_ns, p90_ns=resolved_p90, mad_ns=mad_ns)


def benchmark_row(
    case: CaseMeta,
    *,
    toolchain: str,
    backend: str,
    metrics: MetricSummary | None = None,
    status: str = "ok",
    samples: list[int] | None = None,
    checksum: str = "",
) -> BenchmarkRow:
    resolved_metrics = metrics if metrics is not None else metric_summary(0)
    return BenchmarkRow(
        toolchain=toolchain,
        backend=backend,
        operation=case.operation,
        case_id=case.case_id,
        family=case.family,
        workload_tier=case.workload_tier,
        structure=case.structure,
        timing_scope=case.timing_scope,
        input_layout=case.input_layout,
        mutation_policy=case.mutation_policy,
        size_tier=case.size_tier,
        cost_model=case.cost_model,
        shape=case.shape,
        samples=[] if samples is None else samples,
        median_ns=resolved_metrics.median_ns,
        p90_ns=resolved_metrics.p90_ns,
        mad_ns=resolved_metrics.mad_ns,
        throughput_elements_per_s=throughput_elements_per_s(case, resolved_metrics.median_ns),
        throughput_estimated_flops_per_s=throughput_estimated_flops_per_s(case, resolved_metrics.median_ns),
        throughput_estimated_bytes_per_s=throughput_estimated_bytes_per_s(case, resolved_metrics.median_ns),
        normalization_basis=normalization_basis(case),
        checksum=checksum,
        status=status,
    )


def collect_environment_metadata() -> dict[str, str]:
    return {
        "platform": platform.platform(),
        "python": platform.python_version(),
        "moon": capture_command_text(["moon", "version"]),
        "cargo": capture_command_text(["cargo", "--version"]),
        "rustc": capture_command_text(["rustc", "--version"]),
    }


def capture_command_text(cmd: list[str]) -> str:
    try:
        completed = run(cmd)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        return f"unavailable: {exc}"
    return completed.stdout.strip() or completed.stderr.strip() or "unknown"


def percentile_nearest_rank(values: list[int], fraction: float) -> int:
    if not values:
        return 0
    ordered = sorted(values)
    rank = max(1, math.ceil(len(ordered) * fraction))
    return ordered[rank - 1]


def compute_sample_metrics(samples: list[int]) -> MetricSummary:
    if not samples:
        return metric_summary(0)
    median_ns = int(round(statistics.median(samples)))
    p90_ns = percentile_nearest_rank(samples, 0.9)
    deviations = [abs(value - median_ns) for value in samples]
    mad_ns = int(round(statistics.median(deviations)))
    return metric_summary(median_ns=median_ns, p90_ns=p90_ns, mad_ns=mad_ns)


def work_elements(case: CaseMeta) -> int:
    if case.operation == "mul":
        return case.shape.rows * case.shape.cols * case.shape.rhs_cols
    if case.operation == "mul_vec":
        return case.shape.rows * case.shape.cols
    return case.shape.rows * max(1, case.shape.cols)


def estimated_flops(case: CaseMeta) -> int | None:
    rows = case.shape.rows
    cols = case.shape.cols
    rhs_cols = case.shape.rhs_cols
    n = rows
    if case.operation == "mul":
        return 2 * rows * cols * rhs_cols
    if case.operation == "mul_vec":
        return 2 * rows * cols
    if case.operation in {"determinant", "inverse", "rank", "reduce_row_elimination", "cholesky_decomposition", "eigen"} and rows == cols:
        return n * n * n
    if case.operation in {"rank", "reduce_row_elimination"}:
        return rows * cols * min(rows, cols)
    return None


def estimated_bytes(case: CaseMeta) -> int:
    elements = case.shape.rows * case.shape.cols + case.shape.cols * max(1, case.shape.rhs_cols)
    if case.operation not in {"mul", "mul_vec"}:
        elements = case.shape.rows * case.shape.cols
    return elements * 8


def per_second(count: int | None, median_ns: int) -> float | None:
    if count is None or median_ns <= 0:
        return None
    return count * 1_000_000_000.0 / median_ns


def throughput_elements_per_s(case: CaseMeta, median_ns: int) -> float:
    value = per_second(work_elements(case), median_ns)
    return 0.0 if value is None else value


def throughput_estimated_flops_per_s(case: CaseMeta, median_ns: int) -> float | None:
    return per_second(estimated_flops(case), median_ns)


def throughput_estimated_bytes_per_s(case: CaseMeta, median_ns: int) -> float | None:
    return per_second(estimated_bytes(case), median_ns)


def normalization_basis(case: CaseMeta) -> str:
    if case.operation == "mul":
        return "2*m*n*k flops"
    if case.operation == "mul_vec":
        return "2*m*n flops"
    if estimated_flops(case) is not None:
        return "estimated dense work"
    return "elements"


def progress_label(case: CaseMeta, backend: str, phase: str) -> str:
    badge = backend_badge("moonbit", backend, color=sys.stdout.isatty())
    return fixed_detail(f"{phase} {case.case_id}", badge, DETAIL_WIDTH)


def build_moon_runner_target(target: str, target_dir: str, progress: Progress) -> None:
    run(
        with_target_dir(
            ["moon", "run", "--target", target, *MOONBIT_RELEASE_ARGS, "src/perf_runner", "--build-only"],
            target_dir,
        ),
        heartbeat=lambda: progress.heartbeat(
            fixed_detail(
                "build runner",
                backend_badge("moonbit", target, color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        ),
    )


def moon_build_dir(target: str, target_dir: str) -> Path:
    base_dir = ROOT / "_build" if not target_dir else Path(target_dir)
    return base_dir / target / "release" / "build" / "perf_runner"


def moon_runner_launcher(target: str, target_dir: str) -> tuple[list[str], str]:
    build_dir = moon_build_dir(target, target_dir)
    if target == "native":
        return [str(build_dir / "perf_runner.exe")], "direct native executable"
    if target == "js":
        return ["node", str(build_dir / "perf_runner.js")], "node js artifact"
    return (
        with_target_dir(
            ["moon", "run", "--target", target, *MOONBIT_RELEASE_ARGS, "src/perf_runner"],
            target_dir,
        ),
        "moon run launcher",
    )


def moon_runner_command(target: str, case: CaseMeta, repeat_count: int, target_dir: str) -> tuple[list[str], str]:
    launcher, label = moon_runner_launcher(target, target_dir)
    return [*launcher, case.case_id, "--case-file", case.case_path, "--repeat", str(repeat_count)], label


def parse_diagnostic_payload(output: str) -> DiagnosticPayload:
    for line in reversed(output.splitlines()):
        stripped = line.strip()
        if not stripped:
            continue
        payload = json.loads(stripped)
        if payload.get("kind") == DIAGNOSTIC_KIND:
            return DiagnosticPayload(checksum=str(payload["checksum"]))
    raise RuntimeError("missing diagnostic payload")


def parse_benchmark_payload(output: str) -> MoonBenchmarkPayload:
    for line in reversed(output.splitlines()):
        stripped = line.strip()
        if not stripped:
            continue
        payload = json.loads(stripped)
        if payload.get("kind") == "benchmark":
            return MoonBenchmarkPayload(
                samples=[int(value) for value in payload["samples"]],
                repeat_count=int(payload["repeat"]),
            )
    raise RuntimeError("missing benchmark payload")


def run_moon_case_sample(
    target: str,
    case: CaseMeta,
    repeat_count: int,
    target_dir: str,
    progress: Progress | None = None,
) -> tuple[int, DiagnosticPayload, str]:
    command, launcher = moon_runner_command(target, case, repeat_count, target_dir)
    started = time.perf_counter_ns()
    completed = run(
        command,
        heartbeat=(
            None
            if progress is None
            else lambda: progress.heartbeat(
                progress_label(case, target, "calibrate")
            )
        ),
    )
    elapsed_ns = time.perf_counter_ns() - started
    payload = parse_diagnostic_payload(completed.stdout)
    return elapsed_ns, payload, launcher


def run_moon_case_benchmark(
    target: str,
    case: CaseMeta,
    repeat_count: int,
    sample_count: int,
    warmup_count: int,
    target_dir: str,
    progress: Progress | None = None,
) -> tuple[MoonBenchmarkPayload, str]:
    command, launcher = moon_runner_command(target, case, repeat_count, target_dir)
    completed = run(
        [*command, "--samples", str(sample_count), "--warmup", str(warmup_count)],
        heartbeat=(
            None
            if progress is None
            else lambda: progress.heartbeat(
                progress_label(case, target, f"sample x{sample_count} repeat {repeat_count}")
            )
        ),
    )
    payload = parse_benchmark_payload(completed.stdout)
    return payload, launcher


def calibrate_repeat_count(target: str, case: CaseMeta, target_dir: str, progress: Progress) -> int:
    elapsed_ns, _, _ = run_moon_case_sample(target, case, 1, target_dir, progress)
    estimated_repeat = max(1, round(MOON_TARGET_SAMPLE_NS / max(elapsed_ns, 1)))
    return min(MOON_MAX_REPEAT, estimated_repeat)


def measure_moonbit_case(
    target: str,
    case: CaseMeta,
    target_dir: str,
    progress: Progress,
) -> tuple[BenchmarkRow, MeasurementMetadata]:
    repeat_count = calibrate_repeat_count(target, case, target_dir, progress)
    warmup_count = max(1, math.ceil(MOON_WARMUP_NS / max(MOON_TARGET_SAMPLE_NS * repeat_count, 1)))
    benchmark_payload, launcher = run_moon_case_benchmark(
        target,
        case,
        repeat_count,
        MOON_SAMPLE_COUNT,
        warmup_count,
        target_dir,
        progress,
    )
    samples = benchmark_payload.samples

    return (
        benchmark_row(
            case,
            toolchain="moonbit",
            backend=target,
            metrics=compute_sample_metrics(samples),
            samples=samples,
        ),
        MeasurementMetadata(
            tool="run.py sampled perf_runner",
            sample_count=MOON_SAMPLE_COUNT,
            warmup_ns=MOON_WARMUP_NS,
            target_sample_ns=MOON_TARGET_SAMPLE_NS,
            repeat_count=benchmark_payload.repeat_count,
            launcher=launcher,
            calibration_policy="process_runtime_single_repeat",
            scratch_preparation_excluded=True,
            repeat_strategy="per_case_repeat_count",
        ),
    )


def collect_moonbit_rows(
    target: str,
    cases: list[CaseMeta],
    target_dir: str,
    progress: Progress,
) -> tuple[list[BenchmarkRow], dict[str, MeasurementMetadata]]:
    rows: list[BenchmarkRow] = []
    measurements: dict[str, MeasurementMetadata] = {}
    for case in cases:
        row, measurement = measure_moonbit_case(target, case, target_dir, progress)
        rows.append(row)
        measurements[f"{target}:{case.case_id}"] = measurement
        detail = (
            progress_label(case, target, row.status)
            if row.status != "ok"
            else fixed_detail(
                f"{case.case_id} {format_ns(row.median_ns)}",
                backend_badge("moonbit", target, color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        )
        progress.tick(detail)
    return rows, measurements


def rust_bench_command(*args: str) -> list[str]:
    return ["cargo", "bench", "--profile", RUST_BENCH_PROFILE, *args]


def build_rust_kernel_bench(cases: list[CaseMeta], smoke: bool, progress: Progress) -> None:
    supported_cases = [case for case in cases if case.operation in RUST_SUPPORTED_OPS]
    shutil.rmtree(RUST_CRITERION_DIR, ignore_errors=True)
    if smoke or len(supported_cases) != len(cases):
        for case in supported_cases:
            run(
                rust_bench_command("--bench", "kernel", case.case_id, "--", "--noplot"),
                cwd=RUST_DIR,
                heartbeat=lambda case_id=case.case_id: progress.heartbeat(
                    fixed_detail(
                        f"warmup {case_id}",
                        backend_badge("rust", "native", color=sys.stdout.isatty()),
                        DETAIL_WIDTH,
                    )
                ),
            )
        return
    run(
        rust_bench_command("--bench", "kernel", "--", "--noplot"),
        cwd=RUST_DIR,
        heartbeat=lambda: progress.heartbeat(
            fixed_detail(
                f"warmup {len(supported_cases)} cases",
                backend_badge("rust", "native", color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        ),
    )


def load_rust_kernel_estimate(case: CaseMeta) -> MetricSummary:
    estimate_path = (
        RUST_CRITERION_DIR
        / case.operation
        / case.case_id
        / "new"
        / "estimates.json"
    )
    payload = json.loads(estimate_path.read_text(encoding="utf-8"))
    return metric_summary(
        median_ns=int(round(payload["median"]["point_estimate"])),
        mad_ns=int(round(payload.get("median_abs_dev", {}).get("point_estimate", 0))),
    )


def rust_case_row(case: CaseMeta) -> BenchmarkRow:
    if case.operation not in RUST_SUPPORTED_OPS:
        return benchmark_row(
            case,
            toolchain="rust-nalgebra",
            backend="native",
            status="unsupported",
        )
    return benchmark_row(
        case,
        toolchain="rust-nalgebra",
        backend="native",
        metrics=load_rust_kernel_estimate(case),
    )


def load_existing_rust_rows(cases: list[CaseMeta]) -> list[BenchmarkRow]:
    summary_path = RESULTS_DIR / "summary.json"
    if not summary_path.exists():
        return []
    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    allowed_case_ids = {case.case_id for case in cases}
    rows: list[BenchmarkRow] = []
    for row in payload.get("rows", []):
        if row.get("toolchain") != "rust-nalgebra":
            continue
        if row.get("case_id") not in allowed_case_ids and row.get("case_id") != "rust-baseline":
            continue
        shape = row.get("shape", {})
        rows.append(
            BenchmarkRow(
                toolchain=row["toolchain"],
                backend=row["backend"],
                operation=row["operation"],
                case_id=row["case_id"],
                family=row["family"],
                workload_tier=row.get("workload_tier", ""),
                structure=row.get("structure", ""),
                timing_scope=row.get("timing_scope", "kernel_only"),
                input_layout=row.get("input_layout", "row_major_dense"),
                mutation_policy=row.get("mutation_policy", "reusable_input"),
                size_tier=row.get("size_tier", ""),
                cost_model=row.get("cost_model", "elements"),
                shape=Shape(
                    rows=int(shape.get("rows", 0)),
                    cols=int(shape.get("cols", 0)),
                    rhs_cols=int(shape.get("rhs_cols", 0)),
                ),
                samples=[int(value) for value in row.get("samples", [])],
                median_ns=int(row.get("median_ns", 0)),
                p90_ns=int(row.get("p90_ns", 0)),
                mad_ns=int(row.get("mad_ns", 0)),
                throughput_elements_per_s=float(row.get("throughput_elements_per_s", 0.0)),
                throughput_estimated_flops_per_s=row.get("throughput_estimated_flops_per_s"),
                throughput_estimated_bytes_per_s=row.get("throughput_estimated_bytes_per_s"),
                normalization_basis=row.get("normalization_basis", "elements"),
                checksum=str(row.get("checksum", "")),
                status=row.get("status", "ok"),
            )
        )
    return rows


def summarise_markdown(context: RunContext, rows: list[BenchmarkRow]) -> str:
    lines = [
        "# Benchmark Summary",
        "",
        f"- Dataset version: `{context.dataset_version}`",
        f"- Generated at: `{now_iso()}`",
        f"- Benchmark mode: `{context.mode}`",
        f"- Smoke mode: `{context.smoke}`",
        "",
        "| Toolchain | Backend | Case | Operation | Tier | Structure | Median (ns) | GFLOP/s | Elements/s | Status |",
        "| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in sorted(rows, key=lambda item: (item.toolchain, item.backend, item.case_id)):
        gflops = 0.0 if row.throughput_estimated_flops_per_s is None else row.throughput_estimated_flops_per_s / 1_000_000_000.0
        lines.append(
            f"| {row.toolchain} | {row.backend} | "
            f"{row.case_id} | {row.operation} | {row.workload_tier} | "
            f"{row.structure} | {row.median_ns} | {gflops:.3f} | "
            f"{row.throughput_elements_per_s:.3f} | {row.status} |"
        )
    lines.append("")
    return "\n".join(lines)


def summary_payload(
    context: RunContext,
    rows: list[BenchmarkRow],
    moon_measurements: dict[str, MeasurementMetadata],
) -> dict[str, object]:
    return {
        "started_at": context.started_at,
        "finished_at": now_iso(),
        "dataset_version": context.dataset_version,
        "include_rust": context.include_rust,
        "targets": context.targets,
        "mode": context.mode,
        "smoke": context.smoke,
        "metadata": {
            "run": {
                "started_at": context.started_at,
                "dataset_version": context.dataset_version,
                "include_rust": context.include_rust,
                "targets": context.targets,
                "mode": context.mode,
                "smoke": context.smoke,
            },
            "measurement": {
                "moonbit": {
                    "tool": "run.py sampled perf_runner",
                    "sample_count": MOON_SAMPLE_COUNT,
                    "warmup_ns": MOON_WARMUP_NS,
                    "target_sample_ns": MOON_TARGET_SAMPLE_NS,
                    "calibration_policy": "process_runtime_single_repeat",
                    "scratch_preparation_excluded": True,
                    "repeat_strategy": "per_case_repeat_count",
                    "launcher_by_target": {
                        key: value.launcher
                        for key, value in sorted(moon_measurements.items())
                    },
                    "per_case_repeat_count": {
                        key: value.repeat_count
                        for key, value in sorted(moon_measurements.items())
                    },
                },
                "rust": {
                    "tool": "criterion",
                    "sample_count": 15,
                    "warmup_ns": 250_000_000,
                    "target_sample_ns": MOON_TARGET_SAMPLE_NS,
                    "calibration_policy": "criterion_default",
                    "scratch_preparation_excluded": True,
                    "repeat_strategy": "criterion_sampling",
                },
            },
            "environment": context.environment,
        },
        "rows": [row.to_dict() for row in rows],
    }


def write_summary(
    context: RunContext,
    rows: list[BenchmarkRow],
    moon_measurements: dict[str, MeasurementMetadata],
) -> None:
    summary = summary_payload(context, rows, moon_measurements)
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    atomic_write_text(RAW_DIR / "summary.json", json.dumps(summary, indent=2) + "\n")
    atomic_write_text(RESULTS_DIR / "summary.md", summarise_markdown(context, rows) + "\n")
    atomic_write_text(RESULTS_DIR / "summary.json", json.dumps(summary, indent=2) + "\n")


def atomic_write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    temp_path.write_text(content, encoding="utf-8")
    temp_path.replace(path)


def rust_build_failed_row() -> BenchmarkRow:
    return BenchmarkRow(
        toolchain="rust-nalgebra",
        backend="native",
        operation="build",
        case_id="rust-baseline",
        family="n/a",
        workload_tier="n/a",
        structure="n/a",
        timing_scope="kernel_only",
        input_layout="row_major_dense",
        mutation_policy="reusable_input",
        size_tier="n/a",
        cost_model="elements",
        shape=Shape(rows=0, cols=0, rhs_cols=0),
        status="build_failed",
    )


def main() -> int:
    start_ns = time.perf_counter_ns()
    args = parse_args()
    dataset_version, cases = load_manifest()
    if args.smoke:
        cases = select_smoke_cases(cases)
    context = RunContext(
        started_at=now_iso(),
        dataset_version=dataset_version,
        include_rust=args.include_rust,
        targets=args.targets,
        smoke=args.smoke,
        environment=collect_environment_metadata(),
    )
    total_steps = len(args.targets) * (1 + len(cases))
    if args.include_rust:
        total_steps += 1 + len(cases)
    progress = Progress(total_steps)
    log("")
    log("Benchmark Run")
    log(f"  dataset : {dataset_version}")
    log(f"  mode    : {BENCHMARK_MODE}")
    log(f"  targets : {', '.join(args.targets)}")
    log(f"  cases   : {len(cases)}")
    log(f"  rust    : {'on' if args.include_rust else 'reuse previous/off'}")
    log("")

    rows: list[BenchmarkRow] = []
    moon_measurements: dict[str, MeasurementMetadata] = {}
    if args.include_rust:
        try:
            progress.update(
                fixed_detail(
                    f"warmup {len(cases)} cases",
                    backend_badge("rust", "native", color=sys.stdout.isatty()),
                    DETAIL_WIDTH,
                )
            )
            build_rust_kernel_bench(cases, args.smoke, progress)
            progress.tick("rust benchmark")
            for case in cases:
                row = rust_case_row(case)
                rows.append(row)
                detail = (
                    fixed_detail(
                        f"unsupported {case.case_id}",
                        backend_badge("rust", "native", color=sys.stdout.isatty()),
                        DETAIL_WIDTH,
                    )
                    if row.status == "unsupported"
                    else fixed_detail(
                        f"{case.case_id} {format_ns(row.median_ns)}",
                        backend_badge("rust", "native", color=sys.stdout.isatty()),
                        DETAIL_WIDTH,
                    )
                )
                progress.tick(detail)
        except subprocess.CalledProcessError as exc:
            error_path = RAW_DIR / "rust_error.txt"
            error_path.write_text(exc.stdout + "\n--- stderr ---\n" + exc.stderr, encoding="utf-8")
            rows.append(rust_build_failed_row())
    else:
        rows.extend(load_existing_rust_rows(cases))
    write_summary(context, rows, moon_measurements)
    for target in args.targets:
        progress.update(
            fixed_detail(
                "build runner",
                backend_badge("moonbit", target, color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        )
        build_moon_runner_target(target, args.target_dir, progress)
        progress.tick(
            fixed_detail(
                "build runner",
                backend_badge("moonbit", target, color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        )
        progress.update(
            fixed_detail(
                f"sweep {len(cases)} cases",
                backend_badge("moonbit", target, color=sys.stdout.isatty()),
                DETAIL_WIDTH,
            )
        )
        target_rows, target_measurements = collect_moonbit_rows(target, cases, args.target_dir, progress)
        rows.extend(target_rows)
        moon_measurements.update(target_measurements)
        write_summary(context, rows, moon_measurements)
    progress.finish(f"wrote {len(rows)} rows total {format_ns(time.perf_counter_ns() - start_ns)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
