#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import math
import os
import re
import shlex
import statistics
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = ROOT / "bench" / "datasets"
RESULTS_DIR = ROOT / "bench" / "results"
RAW_DIR = RESULTS_DIR / "raw"
RUST_DIR = ROOT / "bench" / "rust_baseline"
RUST_BIN = RUST_DIR / "target" / "release" / "linear-algebra-bench-baseline"
MOONBIT_TARGETS = ("native", "js", "wasm", "wasm-gc")
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


BENCH_LINE = re.compile(
    r"^(?P<name>\S+)\s+(?P<mean>[0-9.]+)\s*(?P<unit>ns|µs|ms|s)\s+±"
)


def log(message: str) -> None:
    print(message, flush=True)


def format_ns(ns: int) -> str:
    if ns >= 1_000_000_000:
        return f"{ns / 1_000_000_000:.2f}s"
    if ns >= 1_000_000:
        return f"{ns / 1_000_000:.2f}ms"
    if ns >= 1_000:
        return f"{ns / 1_000:.2f}us"
    return f"{ns}ns"


def step_label(prefix: str, index: int, total: int, detail: str) -> str:
    width = max(2, len(str(total)))
    return f"[{prefix} {index:>{width}}/{total}] {detail}"


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
class CaseMeta:
    case_id: str
    operation: str
    family: str
    rows: int
    cols: int
    rhs_cols: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run MoonBit backend benchmarks.")
    parser.add_argument(
        "--targets",
        nargs="+",
        default=list(MOONBIT_TARGETS),
        choices=MOONBIT_TARGETS,
    )
    parser.add_argument("--cold-runs", type=int, default=15)
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
            rows=item["shape"]["rows"],
            cols=item["shape"]["cols"],
            rhs_cols=item["shape"]["rhs_cols"],
        )
        for item in manifest["cases"]
    ]
    return manifest["dataset_version"], cases


def convert_to_ns(value: float, unit: str) -> int:
    factor = {
        "ns": 1.0,
        "µs": 1_000.0,
        "ms": 1_000_000.0,
        "s": 1_000_000_000.0,
    }[unit]
    return int(round(value * factor))


def parse_bench_output(output: str) -> dict[str, int]:
    results: dict[str, int] = {}
    for line in output.splitlines():
        stripped = line.strip()
        match = BENCH_LINE.match(stripped)
        if match:
            results[match.group("name")] = convert_to_ns(
                float(match.group("mean")),
                match.group("unit"),
            )
    return results


def mad_ns(samples: list[int], median_value: int) -> int:
    return int(statistics.median(abs(sample - median_value) for sample in samples))


def trimmed_stats(samples: list[int]) -> tuple[int, int, int]:
    trimmed = sorted(samples)
    if len(trimmed) > 5:
        trimmed = trimmed[2:-2]
    median_value = int(statistics.median(trimmed))
    p90_value = trimmed[min(len(trimmed) - 1, math.ceil(0.9 * len(trimmed)) - 1)]
    return median_value, p90_value, mad_ns(trimmed, median_value)


def moon_runner_cmd(target: str, case_id: str, target_dir: str) -> list[str]:
    build_dir = Path(target_dir) if target_dir else ROOT
    if target == "native":
        runner = build_dir / "native" / "release" / "build" / "perf_runner" / "perf_runner.exe"
        return [str(runner), case_id]
    if target == "js":
        runner = build_dir / "js" / "release" / "build" / "perf_runner" / "perf_runner.js"
        return ["node", str(runner), case_id]
    if target in ("wasm", "wasm-gc"):
        runner = build_dir / target / "release" / "build" / "perf_runner" / "perf_runner.wasm"
        return ["moonrun", str(runner), case_id]
    raise ValueError(f"unsupported moonbit target: {target}")


def moon_runner_payload(target: str, case_id: str, target_dir: str) -> dict[str, Any]:
    cmd = moon_runner_cmd(target, case_id, target_dir)
    started = time.perf_counter_ns()
    completed = run(cmd)
    elapsed_ns = time.perf_counter_ns() - started
    payload = extract_json_payload(completed.stdout, completed.stderr, cmd, case_id, target)
    payload["elapsed_ns"] = elapsed_ns
    payload["toolchain"] = "moonbit"
    payload["backend"] = target
    payload["phase"] = "cold"
    return payload


def extract_json_payload(
    stdout: str,
    stderr: str,
    cmd: list[str],
    case_id: str,
    target: str,
) -> dict[str, Any]:
    for line in reversed(stdout.splitlines()):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("{") and stripped.endswith("}"):
            return json.loads(stripped)
    raise RuntimeError(
        "moon runner did not emit JSON for "
        f"{target}:{case_id}\n"
        f"command: {' '.join(cmd)}\n"
        f"stdout:\n{stdout[-4000:]}\n"
        f"stderr:\n{stderr[-4000:]}"
    )


def collect_cold(target: str, case: CaseMeta, runs: int, target_dir: str) -> dict[str, Any]:
    started = time.perf_counter_ns()
    samples = [moon_runner_payload(target, case.case_id, target_dir) for _ in range(runs)]
    checksums = {sample["checksum"] for sample in samples}
    if len(checksums) != 1:
        raise RuntimeError(f"checksum mismatch for {target}:{case.case_id}: {checksums}")
    durations = [sample["elapsed_ns"] for sample in samples]
    median_value, p90_value, mad_value = trimmed_stats(durations)
    result = {
        "toolchain": "moonbit",
        "backend": target,
        "phase": "cold",
        "operation": case.operation,
        "case_id": case.case_id,
        "family": case.family,
        "shape": {
            "rows": case.rows,
            "cols": case.cols,
            "rhs_cols": case.rhs_cols,
        },
        "samples": durations,
        "median_ns": median_value,
        "p90_ns": p90_value,
        "mad_ns": mad_value,
        "checksum": checksums.pop(),
        "status": "ok",
    }
    result["wall_ns"] = time.perf_counter_ns() - started
    return result


def build_moon_target(target: str, target_dir: str) -> None:
    run(with_target_dir(["moon", "bench", "-p", "perf", "--target", target, "--release", "--build-only"], target_dir))
    run(with_target_dir(["moon", "run", "src/perf_runner", "--target", target, "--release", "--build-only"], target_dir))


def collect_warm(target: str, cases: list[CaseMeta], target_dir: str) -> list[dict[str, Any]]:
    completed = run(
        with_target_dir([
            "moon",
            "bench",
            "-p",
            "perf",
            "--target",
            target,
            "--release",
            "--no-parallelize",
            "-j",
            "1",
        ], target_dir)
    )
    parsed = parse_bench_output(completed.stdout)
    rows = []
    for case in cases:
        bench_name = f"{case.operation}/{case.case_id}"
        if bench_name not in parsed:
            raise RuntimeError(f"missing warm benchmark result for {bench_name} on {target}")
        rows.append(
            {
                "toolchain": "moonbit",
                "backend": target,
                "phase": "warm",
                "operation": case.operation,
                "case_id": case.case_id,
                "family": case.family,
                "shape": {
                    "rows": case.rows,
                    "cols": case.cols,
                    "rhs_cols": case.rhs_cols,
                },
                "samples": [],
                "median_ns": parsed[bench_name],
                "p90_ns": parsed[bench_name],
                "mad_ns": 0,
                "checksum": "",
                "status": "ok",
            }
        )
    return rows


def rust_runner_payload(case_id: str) -> dict[str, Any]:
    completed = run(
        [str(RUST_BIN), case_id],
        cwd=RUST_DIR,
    )
    return json.loads(completed.stdout.strip())


def rust_warm_payload(case_id: str) -> dict[str, Any]:
    completed = run(
        [str(RUST_BIN), "--warm", case_id],
        cwd=RUST_DIR,
    )
    return json.loads(completed.stdout.strip())


def build_rust() -> None:
    run(["cargo", "build", "--release"], cwd=RUST_DIR)


def collect_rust(
    cases: list[CaseMeta],
    cold_runs: int,
    progress: Progress,
    rows: list[dict[str, Any]],
    dataset_version: str,
    started_at: str,
    targets: list[str],
    include_rust: bool,
) -> None:
    build_rust()
    progress.tick("rust build")
    for case in cases:
        if case.operation not in RUST_SUPPORTED_OPS:
            rows.append(
                {
                    "toolchain": "rust-nalgebra",
                    "backend": "native",
                    "phase": "warm",
                    "operation": case.operation,
                    "case_id": case.case_id,
                    "family": case.family,
                    "shape": {
                        "rows": case.rows,
                        "cols": case.cols,
                        "rhs_cols": case.rhs_cols,
                    },
                    "samples": [],
                    "median_ns": 0,
                    "p90_ns": 0,
                    "mad_ns": 0,
                    "checksum": "",
                    "status": "unsupported",
                }
            )
            write_summary(dataset_version, started_at, targets, include_rust, rows)
            rows.append(
                {
                    "toolchain": "rust-nalgebra",
                    "backend": "native",
                    "phase": "cold",
                    "operation": case.operation,
                    "case_id": case.case_id,
                    "family": case.family,
                    "shape": {
                        "rows": case.rows,
                        "cols": case.cols,
                        "rhs_cols": case.rhs_cols,
                    },
                    "samples": [],
                    "median_ns": 0,
                    "p90_ns": 0,
                    "mad_ns": 0,
                    "checksum": "",
                    "status": "unsupported",
                }
            )
            write_summary(dataset_version, started_at, targets, include_rust, rows)
            progress.tick(f"rust warm {case.operation}/{case.case_id} unsupported")
            progress.tick(f"rust cold {case.operation}/{case.case_id} unsupported")
            continue
        warm = rust_warm_payload(case.case_id)
        rows.append(
            {
                "toolchain": "rust-nalgebra",
                "backend": "native",
                "phase": "warm",
                "operation": case.operation,
                "case_id": case.case_id,
                "family": case.family,
                "shape": {
                    "rows": case.rows,
                    "cols": case.cols,
                    "rhs_cols": case.rhs_cols,
                },
                "samples": [],
                "median_ns": warm["median_ns"],
                "p90_ns": warm["p90_ns"],
                "mad_ns": warm["mad_ns"],
                "checksum": warm["checksum"],
                "status": "ok",
            }
        )
        write_summary(dataset_version, started_at, targets, include_rust, rows)
        progress.tick(f"rust warm {case.operation}/{case.case_id} {format_ns(warm['median_ns'])}")
        samples = []
        checksums = set()
        for _ in range(cold_runs):
            started = time.perf_counter_ns()
            payload = rust_runner_payload(case.case_id)
            samples.append(time.perf_counter_ns() - started)
            checksums.add(payload["checksum"])
        median_value, p90_value, mad_value = trimmed_stats(samples)
        rows.append(
            {
                "toolchain": "rust-nalgebra",
                "backend": "native",
                "phase": "cold",
                "operation": case.operation,
                "case_id": case.case_id,
                "family": case.family,
                "shape": {
                    "rows": case.rows,
                    "cols": case.cols,
                    "rhs_cols": case.rhs_cols,
                },
                "samples": samples,
                "median_ns": median_value,
                "p90_ns": p90_value,
                "mad_ns": mad_value,
                "checksum": checksums.pop(),
                "status": "ok",
            }
        )
        write_summary(dataset_version, started_at, targets, include_rust, rows)
        progress.tick(f"rust cold {case.operation}/{case.case_id} {format_ns(median_value)}")


def summarise_markdown(dataset_version: str, rows: list[dict[str, Any]]) -> str:
    lines = [
        "# Benchmark Summary",
        "",
        f"- Dataset version: `{dataset_version}`",
        f"- Generated at: `{time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}`",
        "",
        "| Toolchain | Backend | Phase | Case | Operation | Median (ns) | P90 (ns) | Status |",
        "| --- | --- | --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in sorted(rows, key=lambda item: (item["toolchain"], item["backend"], item["phase"], item["case_id"])):
        lines.append(
            f"| {row['toolchain']} | {row['backend']} | {row['phase']} | "
            f"{row['case_id']} | {row['operation']} | {row['median_ns']} | "
            f"{row['p90_ns']} | {row['status']} |"
        )
    lines.append("")
    return "\n".join(lines)


def write_summary(
    dataset_version: str,
    started_at: str,
    targets: list[str],
    include_rust: bool,
    rows: list[dict[str, Any]],
) -> None:
    summary = {
        "started_at": started_at,
        "finished_at": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        "dataset_version": dataset_version,
        "include_rust": include_rust,
        "targets": targets,
        "rows": rows,
    }
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    (RAW_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    (RESULTS_DIR / "summary.md").write_text(summarise_markdown(dataset_version, rows) + "\n", encoding="utf-8")
    (RESULTS_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    start_ns = time.perf_counter_ns()
    args = parse_args()
    started_at = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    dataset_version, cases = load_manifest()
    if args.smoke:
        cases = cases[:2]
        args.cold_runs = 3
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    total_steps = len(args.targets) * (2 + len(cases))
    if args.include_rust:
        total_steps += 1 + 2 * len(cases)
    progress = Progress(total_steps)
    log(
        f"[bench] dataset={dataset_version} targets={','.join(args.targets)} "
        f"cases={len(cases)} cold_runs={args.cold_runs} include_rust={args.include_rust}"
    )

    rows: list[dict[str, Any]] = []
    write_summary(dataset_version, started_at, args.targets, args.include_rust, rows)
    for target in args.targets:
        build_moon_target(target, args.target_dir)
        progress.tick(f"build {target}")
        rows.extend(collect_warm(target, cases, args.target_dir))
        write_summary(dataset_version, started_at, args.targets, args.include_rust, rows)
        progress.tick(f"warm {target}")
        for case in cases:
            row = collect_cold(target, case, args.cold_runs, args.target_dir)
            rows.append(row)
            write_summary(dataset_version, started_at, args.targets, args.include_rust, rows)
            progress.tick(
                f"cold {target} {case.operation}/{case.case_id} "
                f"{format_ns(row['median_ns'])}"
            )

    if args.include_rust:
        try:
            collect_rust(
                cases,
                5 if args.smoke else args.cold_runs,
                progress,
                rows,
                dataset_version,
                started_at,
                args.targets,
                args.include_rust,
            )
        except subprocess.CalledProcessError as exc:
            error_path = RAW_DIR / "rust_error.txt"
            error_path.write_text(exc.stdout + "\n--- stderr ---\n" + exc.stderr, encoding="utf-8")
            rows.append(
                {
                    "toolchain": "rust-nalgebra",
                    "backend": "native",
                    "phase": "cold",
                    "operation": "build",
                    "case_id": "rust-baseline",
                    "family": "n/a",
                    "shape": {"rows": 0, "cols": 0, "rhs_cols": 0},
                    "samples": [],
                    "median_ns": 0,
                    "p90_ns": 0,
                    "mad_ns": 0,
                    "checksum": "",
                    "status": "build_failed",
                }
            )
            write_summary(dataset_version, started_at, args.targets, args.include_rust, rows)
    progress.finish(f"done wrote {len(rows)} rows total {format_ns(time.perf_counter_ns() - start_ns)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
