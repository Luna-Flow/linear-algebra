#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import math
import os
import platform
import shlex
import shutil
import statistics
import subprocess
import sys
import time
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


class Progress:
    def __init__(self, total: int):
        self.total = max(1, total)
        self.done = 0
        self.start_ns = time.perf_counter_ns()
        self.is_tty = sys.stdout.isatty()
        self.last_width = 0

    def tick(self, detail: str) -> None:
        self.done += 1
        self._render(detail)

    def finish(self, detail: str) -> None:
        self.done = self.total
        self._render(detail, final=True)

    def _render(self, detail: str, final: bool = False) -> None:
        width = 28
        filled = int(width * self.done / self.total)
        bar = "#" * filled + "-" * (width - filled)
        elapsed = format_ns(time.perf_counter_ns() - self.start_ns)
        line = f"[{bar}] {self.done:>3}/{self.total}  {detail}  elapsed {elapsed}"
        if self.is_tty:
            padding = max(0, self.last_width - len(line))
            end = "\n" if final else "\r"
            print(line + (" " * padding), end=end, flush=True)
            self.last_width = len(line)
        else:
            print(line, flush=True)


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
    shape: Shape
    samples: list[int] = field(default_factory=list)
    median_ns: int = 0
    p90_ns: int = 0
    mad_ns: int = 0
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


def run(cmd: list[str], cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=cwd,
        check=check,
        text=True,
        capture_output=True,
    )


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
            shape=Shape(
                rows=item["shape"]["rows"],
                cols=item["shape"]["cols"],
                rhs_cols=item["shape"]["rhs_cols"],
            ),
        )
        for item in manifest["cases"]
    ]
    return manifest["dataset_version"], cases


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
        shape=case.shape,
        samples=[] if samples is None else samples,
        median_ns=resolved_metrics.median_ns,
        p90_ns=resolved_metrics.p90_ns,
        mad_ns=resolved_metrics.mad_ns,
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


def build_moon_runner_target(target: str, target_dir: str) -> None:
    run(
        with_target_dir(
            ["moon", "run", "--target", target, *MOONBIT_RELEASE_ARGS, "src/perf_runner", "--build-only"],
            target_dir,
        )
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


def moon_runner_command(target: str, case_id: str, repeat_count: int, target_dir: str) -> tuple[list[str], str]:
    launcher, label = moon_runner_launcher(target, target_dir)
    return [*launcher, case_id, "--repeat", str(repeat_count)], label


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
    case_id: str,
    repeat_count: int,
    target_dir: str,
) -> tuple[int, DiagnosticPayload, str]:
    command, launcher = moon_runner_command(target, case_id, repeat_count, target_dir)
    started = time.perf_counter_ns()
    completed = run(command)
    elapsed_ns = time.perf_counter_ns() - started
    payload = parse_diagnostic_payload(completed.stdout)
    return elapsed_ns, payload, launcher


def run_moon_case_benchmark(
    target: str,
    case_id: str,
    repeat_count: int,
    sample_count: int,
    warmup_count: int,
    target_dir: str,
) -> tuple[MoonBenchmarkPayload, str]:
    command, launcher = moon_runner_command(target, case_id, repeat_count, target_dir)
    completed = run([*command, "--samples", str(sample_count), "--warmup", str(warmup_count)])
    payload = parse_benchmark_payload(completed.stdout)
    return payload, launcher


def calibrate_repeat_count(target: str, case: CaseMeta, target_dir: str) -> int:
    elapsed_ns, _, _ = run_moon_case_sample(target, case.case_id, 1, target_dir)
    estimated_repeat = max(1, round(MOON_TARGET_SAMPLE_NS / max(elapsed_ns, 1)))
    return min(MOON_MAX_REPEAT, estimated_repeat)


def measure_moonbit_case(target: str, case: CaseMeta, target_dir: str) -> tuple[BenchmarkRow, MeasurementMetadata]:
    repeat_count = calibrate_repeat_count(target, case, target_dir)
    warmup_count = max(1, math.ceil(MOON_WARMUP_NS / max(MOON_TARGET_SAMPLE_NS * repeat_count, 1)))
    benchmark_payload, launcher = run_moon_case_benchmark(
        target,
        case.case_id,
        repeat_count,
        MOON_SAMPLE_COUNT,
        warmup_count,
        target_dir,
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
        row, measurement = measure_moonbit_case(target, case, target_dir)
        rows.append(row)
        measurements[f"{target}:{case.case_id}"] = measurement
        detail = (
            f"moon {target} {case.case_id} {row.status}"
            if row.status != "ok"
            else f"moon {target} {case.case_id} {format_ns(row.median_ns)}"
        )
        progress.tick(detail)
    return rows, measurements


def rust_bench_command(*args: str) -> list[str]:
    return ["cargo", "bench", "--profile", RUST_BENCH_PROFILE, *args]


def build_rust_kernel_bench(cases: list[CaseMeta], smoke: bool) -> None:
    supported_cases = [case for case in cases if case.operation in RUST_SUPPORTED_OPS]
    shutil.rmtree(RUST_CRITERION_DIR, ignore_errors=True)
    if smoke or len(supported_cases) != len(cases):
        for case in supported_cases:
            run(
                rust_bench_command("--bench", "kernel", case.case_id, "--", "--noplot"),
                cwd=RUST_DIR,
            )
        return
    run(rust_bench_command("--bench", "kernel", "--", "--noplot"), cwd=RUST_DIR)


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
                shape=Shape(
                    rows=int(shape.get("rows", 0)),
                    cols=int(shape.get("cols", 0)),
                    rhs_cols=int(shape.get("rhs_cols", 0)),
                ),
                samples=[int(value) for value in row.get("samples", [])],
                median_ns=int(row.get("median_ns", 0)),
                p90_ns=int(row.get("p90_ns", 0)),
                mad_ns=int(row.get("mad_ns", 0)),
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
        "| Toolchain | Backend | Case | Operation | Median (ns) | P90 (ns) | MAD (ns) | Status |",
        "| --- | --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in sorted(rows, key=lambda item: (item.toolchain, item.backend, item.case_id)):
        lines.append(
            f"| {row.toolchain} | {row.backend} | "
            f"{row.case_id} | {row.operation} | {row.median_ns} | "
            f"{row.p90_ns} | {row.mad_ns} | {row.status} |"
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
    (RAW_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    (RESULTS_DIR / "summary.md").write_text(summarise_markdown(context, rows) + "\n", encoding="utf-8")
    (RESULTS_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def rust_build_failed_row() -> BenchmarkRow:
    return BenchmarkRow(
        toolchain="rust-nalgebra",
        backend="native",
        operation="build",
        case_id="rust-baseline",
        family="n/a",
        shape=Shape(rows=0, cols=0, rhs_cols=0),
        status="build_failed",
    )


def main() -> int:
    start_ns = time.perf_counter_ns()
    args = parse_args()
    dataset_version, cases = load_manifest()
    if args.smoke:
        cases = cases[:2]
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
    log(
        f"[bench] dataset={dataset_version} targets={','.join(args.targets)} "
        f"cases={len(cases)} mode={BENCHMARK_MODE} include_rust={args.include_rust}"
    )

    rows: list[BenchmarkRow] = []
    moon_measurements: dict[str, MeasurementMetadata] = {}
    if args.include_rust:
        try:
            build_rust_kernel_bench(cases, args.smoke)
            progress.tick("rust benchmark")
            for case in cases:
                row = rust_case_row(case)
                rows.append(row)
                detail = (
                    f"rust {case.operation}/{case.case_id} unsupported"
                    if row.status == "unsupported"
                    else f"rust {case.operation}/{case.case_id} {format_ns(row.median_ns)}"
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
        build_moon_runner_target(target, args.target_dir)
        progress.tick(f"build moon runner {target}")
        target_rows, target_measurements = collect_moonbit_rows(target, cases, args.target_dir, progress)
        rows.extend(target_rows)
        moon_measurements.update(target_measurements)
        write_summary(context, rows, moon_measurements)
    progress.finish(f"done wrote {len(rows)} rows total {format_ns(time.perf_counter_ns() - start_ns)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
