#!/usr/bin/env python3

from __future__ import annotations

import json
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = ROOT / "bench" / "datasets"
CASES_DIR = DATASET_DIR / "cases"
MOONBIT_DIR = ROOT / "src" / "perf_support"
REGISTRY_OUT = MOONBIT_DIR / "generated_registry.mbt"
RUST_DIR = ROOT / "bench" / "rust_baseline" / "src"
RUST_OUT = RUST_DIR / "generated_cases.rs"

DATASET_VERSION = "v1"
GOLDEN_GAMMA = 0x9E3779B97F4A7C15
SPLITMIX_MULT1 = 0xBF58476D1CE4E5B9
SPLITMIX_MULT2 = 0x94D049BB133111EB


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
        width = 24
        filled = int(width * self.done / self.total)
        bar = "#" * filled + "-" * (width - filled)
        elapsed_ms = (time.perf_counter_ns() - self.start_ns) / 1_000_000
        line = f"[codegen {bar}] {self.done:>3}/{self.total}  {detail}  elapsed {elapsed_ms:.0f}ms"
        if self.is_tty:
            padding = max(0, self.last_width - len(line))
            end = "\n" if final else "\r"
            print(line + (" " * padding), end=end, flush=True)
            self.last_width = len(line)
        else:
            print(line, flush=True)


def fmt_float(value: float) -> str:
    text = format(value, ".17g")
    if "e" not in text and "." not in text:
        text += ".0"
    return text


def moon_array(values: list[float]) -> str:
    if not values:
        return "[]"
    chunks = []
    width = 4
    for i in range(0, len(values), width):
        chunk = ", ".join(fmt_float(v) for v in values[i:i + width])
        chunks.append("      " + chunk)
    return "[\n" + ",\n".join(chunks) + "\n    ]"


def rust_array(values: list[float]) -> str:
    if not values:
        return "&[]"
    chunks = []
    width = 4
    for i in range(0, len(values), width):
        chunk = ", ".join(fmt_float(v) for v in values[i:i + width])
        chunks.append("        " + chunk)
    return "&[\n" + ",\n".join(chunks) + "\n      ]"


class SplitMix64:
    def __init__(self, seed: int):
        self.state = seed & 0xFFFFFFFFFFFFFFFF

    def next_u64(self) -> int:
        self.state = (self.state + GOLDEN_GAMMA) & 0xFFFFFFFFFFFFFFFF
        z = self.state
        z = (z ^ (z >> 30)) * SPLITMIX_MULT1 & 0xFFFFFFFFFFFFFFFF
        z = (z ^ (z >> 27)) * SPLITMIX_MULT2 & 0xFFFFFFFFFFFFFFFF
        return z ^ (z >> 31)

    def unit(self) -> float:
        return ((self.next_u64() >> 11) & ((1 << 53) - 1)) / float(1 << 53)

    def uniform(self, lo: float, hi: float) -> float:
        return lo + (hi - lo) * self.unit()


def dense_matrix(rows: int, cols: int, rng: SplitMix64, lo: float = -1.0, hi: float = 1.0) -> list[float]:
    return [rng.uniform(lo, hi) for _ in range(rows * cols)]


def dense_vector(size: int, rng: SplitMix64, lo: float = -1.0, hi: float = 1.0) -> list[float]:
    return [rng.uniform(lo, hi) for _ in range(size)]


def diagonal_matrix(diag: list[float]) -> list[float]:
    size = len(diag)
    data = [0.0] * (size * size)
    for i, value in enumerate(diag):
        data[i * size + i] = value
    return data


def identity_matrix(size: int, scale: float = 1.0) -> list[float]:
    return diagonal_matrix([scale] * size)


def transpose(rows: int, cols: int, data: list[float]) -> list[float]:
    out = [0.0] * (rows * cols)
    for i in range(rows):
        for j in range(cols):
            out[j * rows + i] = data[i * cols + j]
    return out


def matmul(a_rows: int, a_cols: int, b_cols: int, a: list[float], b: list[float]) -> list[float]:
    out = [0.0] * (a_rows * b_cols)
    for i in range(a_rows):
        for k in range(a_cols):
            av = a[i * a_cols + k]
            row_offset = i * b_cols
            b_offset = k * b_cols
            for j in range(b_cols):
                out[row_offset + j] += av * b[b_offset + j]
    return out


def add_matrices(a: list[float], b: list[float]) -> list[float]:
    return [x + y for x, y in zip(a, b)]


def scale_matrix(data: list[float], factor: float) -> list[float]:
    return [factor * x for x in data]


def make_symmetric(size: int, rng: SplitMix64) -> list[float]:
    base = dense_matrix(size, size, rng, lo=-0.75, hi=0.75)
    data = [0.0] * (size * size)
    for i in range(size):
        for j in range(size):
            data[i * size + j] = 0.5 * (base[i * size + j] + base[j * size + i])
    return data


def make_spd(size: int, rng: SplitMix64, diagonal_bias: float) -> list[float]:
    base = dense_matrix(size, size, rng, lo=-0.9, hi=0.9)
    gram = matmul(size, size, size, transpose(size, size, base), base)
    return add_matrices(gram, identity_matrix(size, scale=diagonal_bias))


def make_near_singular(size: int, rng: SplitMix64) -> list[float]:
    data = dense_matrix(size, size, rng, lo=-0.5, hi=0.5)
    base_row = data[0:size]
    target_row = 1
    for col, value in enumerate(base_row):
        data[target_row * size + col] = value * 0.999999 + (col + 1) * 1.0e-7
    for i in range(size):
        data[i * size + i] += 0.25
    return data


def make_rank_deficient(size: int, rng: SplitMix64) -> list[float]:
    data = dense_matrix(size, size, rng, lo=-0.8, hi=0.8)
    for col in range(size):
        data[(size - 1) * size + col] = data[col]
    return data


def make_rect_rank_deficient(rows: int, cols: int, rng: SplitMix64) -> list[float]:
    data = dense_matrix(rows, cols, rng, lo=-0.8, hi=0.8)
    for row in range(1, rows, 3):
        src = (row - 1) * cols
        dst = row * cols
        data[dst:dst + cols] = data[src:src + cols]
    return data


def make_upper_triangular(size: int, rng: SplitMix64) -> list[float]:
    data = [0.0] * (size * size)
    for i in range(size):
        for j in range(i, size):
            value = rng.uniform(-0.9, 0.9)
            if i == j:
                value += 1.5
            data[i * size + j] = value
    return data


def make_permutation(size: int) -> list[float]:
    data = [0.0] * (size * size)
    for i in range(size):
        data[i * size + ((i * 5 + 3) % size)] = 1.0
    return data


def make_dominant_symmetric(size: int, rng: SplitMix64) -> list[float]:
    diag = [float(size - i) * 0.4 + 1.0 for i in range(size)]
    matrix = diagonal_matrix(diag)
    noise = make_symmetric(size, rng)
    return add_matrices(matrix, scale_matrix(noise, 0.08))


@dataclass(frozen=True)
class Case:
    id: str
    operation: str
    family: str
    rows: int
    cols: int
    rhs_cols: int
    generator_meta: dict[str, Any]
    data_a: list[float]
    data_b: list[float]

    def manifest_entry(self) -> dict[str, Any]:
        return {
            "case_id": self.id,
            "operation": self.operation,
            "family": self.family,
            "shape": {
                "rows": self.rows,
                "cols": self.cols,
                "rhs_cols": self.rhs_cols,
            },
            "dtype": "double",
            "generator_meta": self.generator_meta,
        }

    def json_payload(self) -> dict[str, Any]:
        return {
            "dataset_version": DATASET_VERSION,
            **self.manifest_entry(),
            "inputs": {
                "data_a": self.data_a,
                "data_b": self.data_b,
            },
        }


def make_cases() -> list[Case]:
    cases: list[Case] = []

    def add_case(
        case_id: str,
        operation: str,
        family: str,
        rows: int,
        cols: int,
        rhs_cols: int,
        seed: int,
        data_a: list[float],
        data_b: list[float],
        **meta: Any,
    ) -> None:
        generator_meta = {"seed": seed, **meta}
        cases.append(
            Case(
                id=case_id,
                operation=operation,
                family=family,
                rows=rows,
                cols=cols,
                rhs_cols=rhs_cols,
                generator_meta=generator_meta,
                data_a=data_a,
                data_b=data_b,
            )
        )

    rng = SplitMix64(0x1001)
    add_case(
        "mul_dense_32",
        "mul",
        "dense_uniform",
        32,
        32,
        32,
        0x1001,
        dense_matrix(32, 32, rng),
        dense_matrix(32, 32, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x1002)
    add_case(
        "mul_dense_64",
        "mul",
        "dense_uniform",
        64,
        64,
        64,
        0x1002,
        dense_matrix(64, 64, rng),
        dense_matrix(64, 64, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x1003)
    add_case(
        "mul_rect_48x32x48",
        "mul",
        "dense_rectangular",
        48,
        32,
        48,
        0x1003,
        dense_matrix(48, 32, rng),
        dense_matrix(32, 48, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x1004)
    add_case(
        "mul_rect_72x48x72",
        "mul",
        "dense_rectangular",
        72,
        48,
        72,
        0x1004,
        dense_matrix(72, 48, rng),
        dense_matrix(48, 72, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x2001)
    add_case(
        "mul_vec_dense_128",
        "mul_vec",
        "dense_uniform",
        128,
        128,
        1,
        0x2001,
        dense_matrix(128, 128, rng),
        dense_vector(128, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x2002)
    add_case(
        "mul_vec_dense_192",
        "mul_vec",
        "dense_uniform",
        192,
        192,
        1,
        0x2002,
        dense_matrix(192, 192, rng),
        dense_vector(192, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x2003)
    add_case(
        "mul_vec_dense_256",
        "mul_vec",
        "dense_uniform",
        256,
        256,
        1,
        0x2003,
        dense_matrix(256, 256, rng),
        dense_vector(256, rng),
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x3001)
    add_case(
        "det_dense_8",
        "determinant",
        "dense_uniform",
        8,
        8,
        0,
        0x3001,
        dense_matrix(8, 8, rng),
        [],
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x3002)
    add_case(
        "det_near_singular_16",
        "determinant",
        "near_singular",
        16,
        16,
        0,
        0x3002,
        make_near_singular(16, rng),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x3003)
    add_case(
        "det_upper_tri_16",
        "determinant",
        "upper_triangular",
        16,
        16,
        0,
        0x3003,
        make_upper_triangular(16, rng),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x3004)
    add_case(
        "det_dense_24",
        "determinant",
        "dense_uniform",
        24,
        24,
        0,
        0x3004,
        dense_matrix(24, 24, rng),
        [],
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x4001)
    add_case(
        "inverse_dense_8",
        "inverse",
        "dense_shifted",
        8,
        8,
        0,
        0x4001,
        add_matrices(dense_matrix(8, 8, rng), identity_matrix(8, scale=1.75)),
        [],
        distribution="uniform[-1,1]+I",
    )

    rng = SplitMix64(0x4002)
    add_case(
        "inverse_spd_16",
        "inverse",
        "spd",
        16,
        16,
        0,
        0x4002,
        make_spd(16, rng, diagonal_bias=4.0),
        [],
        distribution="gram+lambdaI",
    )

    add_case(
        "inverse_perm_16",
        "inverse",
        "permutation",
        16,
        16,
        0,
        0x4003,
        make_permutation(16),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x4004)
    add_case(
        "inverse_spd_24",
        "inverse",
        "spd",
        24,
        24,
        0,
        0x4004,
        make_spd(24, rng, diagonal_bias=4.25),
        [],
        distribution="gram+lambdaI",
    )

    rng = SplitMix64(0x5001)
    add_case(
        "rank_rect_32x24",
        "rank",
        "dense_rectangular",
        32,
        24,
        0,
        0x5001,
        dense_matrix(32, 24, rng),
        [],
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x5002)
    add_case(
        "rank_rect_def_64x48",
        "rank",
        "rank_deficient_rect",
        64,
        48,
        0,
        0x5002,
        make_rect_rank_deficient(64, 48, rng),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x5003)
    add_case(
        "rank_square_near_singular_64",
        "rank",
        "near_singular",
        64,
        64,
        0,
        0x5003,
        make_near_singular(64, rng),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x6001)
    add_case(
        "rref_rect_32x24",
        "reduce_row_elimination",
        "dense_rectangular",
        32,
        24,
        0,
        0x6001,
        dense_matrix(32, 24, rng),
        [],
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x6002)
    add_case(
        "rref_rank_def_64",
        "reduce_row_elimination",
        "rank_deficient_square",
        64,
        64,
        0,
        0x6002,
        make_rank_deficient(64, rng),
        [],
        distribution="structured",
    )

    rng = SplitMix64(0x6003)
    add_case(
        "rref_rect_48x36",
        "reduce_row_elimination",
        "dense_rectangular",
        48,
        36,
        0,
        0x6003,
        dense_matrix(48, 36, rng),
        [],
        distribution="uniform[-1,1]",
    )

    rng = SplitMix64(0x7001)
    add_case(
        "chol_spd_16",
        "cholesky_decomposition",
        "spd",
        16,
        16,
        0,
        0x7001,
        make_spd(16, rng, diagonal_bias=3.5),
        [],
        distribution="gram+lambdaI",
    )

    rng = SplitMix64(0x7002)
    add_case(
        "chol_spd_32",
        "cholesky_decomposition",
        "spd",
        32,
        32,
        0,
        0x7002,
        make_spd(32, rng, diagonal_bias=4.5),
        [],
        distribution="gram+lambdaI",
    )

    rng = SplitMix64(0x7003)
    add_case(
        "chol_spd_48",
        "cholesky_decomposition",
        "spd",
        48,
        48,
        0,
        0x7003,
        make_spd(48, rng, diagonal_bias=5.0),
        [],
        distribution="gram+lambdaI",
    )

    rng = SplitMix64(0x8001)
    add_case(
        "eigen_sym_16",
        "eigen",
        "symmetric",
        16,
        16,
        0,
        0x8001,
        make_symmetric(16, rng),
        [],
        distribution="symmetric_uniform",
    )

    rng = SplitMix64(0x8002)
    add_case(
        "eigen_sym_24",
        "eigen",
        "symmetric",
        24,
        24,
        0,
        0x8002,
        make_symmetric(24, rng),
        [],
        distribution="symmetric_uniform",
    )

    rng = SplitMix64(0x8003)
    add_case(
        "eigen_sym_32",
        "eigen",
        "symmetric",
        32,
        32,
        0,
        0x8003,
        make_symmetric(32, rng),
        [],
        distribution="symmetric_uniform",
    )

    rng = SplitMix64(0x9001)
    add_case(
        "power_dom_24",
        "power_method",
        "dominant_symmetric",
        24,
        24,
        0,
        0x9001,
        make_dominant_symmetric(24, rng),
        [],
        distribution="diagonal_plus_symmetric_noise",
    )

    rng = SplitMix64(0x9002)
    add_case(
        "power_dom_32",
        "power_method",
        "dominant_symmetric",
        32,
        32,
        0,
        0x9002,
        make_dominant_symmetric(32, rng),
        [],
        distribution="diagonal_plus_symmetric_noise",
    )

    rng = SplitMix64(0x9003)
    add_case(
        "power_dom_48",
        "power_method",
        "dominant_symmetric",
        48,
        48,
        0,
        0x9003,
        make_dominant_symmetric(48, rng),
        [],
        distribution="diagonal_plus_symmetric_noise",
    )

    return cases


def write_json(cases: list[Case], progress: Progress) -> None:
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    for stale in CASES_DIR.glob("*.json"):
        stale.unlink()
    manifest = {
        "dataset_version": DATASET_VERSION,
        "dtype": "double",
        "cases": [case.manifest_entry() for case in cases],
    }
    (DATASET_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    progress.tick("wrote manifest")
    for case in cases:
        (CASES_DIR / f"{case.id}.json").write_text(
            json.dumps(case.json_payload(), indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        progress.tick(f"wrote case {case.id}")


def write_moonbit(cases: list[Case], progress: Progress) -> None:
    for stale in MOONBIT_DIR.glob("generated_case_*.mbt"):
        stale.unlink()
    legacy = MOONBIT_DIR / "datasets_generated.mbt"
    if legacy.exists():
        legacy.unlink()

    lines = [
        "// Generated by bench/generate_fixtures.py. Do not edit by hand.",
        "",
        "///|",
        f"pub let dataset_version : String = \"{DATASET_VERSION}\"",
    ]
    names = []
    for case in cases:
        symbol = "case_" + case.id.replace("-", "_").replace("/", "_")
        names.append(symbol)
        lines.extend(
            [
                "",
                "///|",
                f"let {symbol} : Case = {{",
                f"  id: \"{case.id}\",",
                f"  operation: \"{case.operation}\",",
                f"  family: \"{case.family}\",",
                f"  rows: {case.rows},",
                f"  cols: {case.cols},",
                f"  rhs_cols: {case.rhs_cols},",
                f"  data_a: {moon_array(case.data_a)},",
                f"  data_b: {moon_array(case.data_b)},",
                "}",
            ]
        )
    lines.extend(
        [
            "",
            "///|",
            "pub let cases : Array[Case] = [",
            *(f"  {symbol}," for symbol in names),
            "]",
        ]
    )
    REGISTRY_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    progress.tick("wrote MoonBit registry")


def write_rust(cases: list[Case], progress: Progress) -> None:
    lines = [
        "// Generated by bench/generate_fixtures.py. Do not edit by hand.",
        "",
        "use crate::{CaseFile, Inputs, Shape};",
        "",
        "pub const DATASET_VERSION: &str = "
        f"\"{DATASET_VERSION}\";",
        "",
        "pub static CASES: &[CaseFile] = &[",
    ]
    for case in cases:
        lines.extend(
            [
                "    CaseFile {",
                f"        case_id: \"{case.id}\",",
                f"        operation: \"{case.operation}\",",
                f"        family: \"{case.family}\",",
                "        shape: Shape {",
                f"            rows: {case.rows},",
                f"            cols: {case.cols},",
                f"            rhs_cols: {case.rhs_cols},",
                "        },",
                "        inputs: Inputs {",
                f"            data_a: {rust_array(case.data_a)},",
                f"            data_b: {rust_array(case.data_b)},",
                "        },",
                "    },",
            ]
        )
    lines.extend(
        [
            "];",
            "",
            "pub fn find_case(case_id: &str) -> Option<&'static CaseFile> {",
            "    CASES.iter().find(|case_file| case_file.case_id == case_id)",
            "}",
        ]
    )
    RUST_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    progress.tick("wrote Rust registry")


def main() -> None:
    cases = make_cases()
    progress = Progress(len(cases) + 4)
    progress.tick(f"generated {len(cases)} cases")
    DATASET_DIR.mkdir(parents=True, exist_ok=True)
    write_json(cases, progress)
    write_moonbit(cases, progress)
    write_rust(cases, progress)
    progress.finish(f"done generated {len(cases)} cases")


if __name__ == "__main__":
    main()
