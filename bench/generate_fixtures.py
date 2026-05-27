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

DATASET_VERSION = "v3"
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


def write_if_changed(path: Path, content: str) -> bool:
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def remove_stale_files(existing: list[Path], expected: set[Path]) -> int:
    removed = 0
    for stale in existing:
        if stale not in expected:
            stale.unlink()
            removed += 1
    return removed


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


def make_symmetric(size: int, rng: SplitMix64, scale: float = 0.75) -> list[float]:
    base = dense_matrix(size, size, rng, lo=-scale, hi=scale)
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


def make_dominant_symmetric(size: int, rng: SplitMix64, noise_scale: float = 0.08) -> list[float]:
    diag = [float(size - i) * 0.4 + 1.0 for i in range(size)]
    matrix = diagonal_matrix(diag)
    noise = make_symmetric(size, rng)
    return add_matrices(matrix, scale_matrix(noise, noise_scale))


def make_dense_shifted(size: int, rng: SplitMix64, identity_scale: float = 1.25) -> list[float]:
    return add_matrices(dense_matrix(size, size, rng), identity_matrix(size, scale=identity_scale))


def make_projector_like(rows: int, cols: int, rng: SplitMix64) -> list[float]:
    data = dense_matrix(rows, cols, rng, lo=-0.25, hi=0.25)
    for row in range(rows):
        for col in range(cols):
            if row % 7 == col % 7:
                data[row * cols + col] += 1.5
    return data


def make_block_pattern(rows: int, cols: int, rng: SplitMix64) -> list[float]:
    data = dense_matrix(rows, cols, rng, lo=-0.15, hi=0.15)
    block_rows = 8
    block_cols = 8
    for row in range(rows):
        for col in range(cols):
            if (row // block_rows + col // block_cols) % 2 == 0:
                data[row * cols + col] += rng.uniform(0.6, 1.0)
    return data


def make_clustered_symmetric(size: int, rng: SplitMix64) -> list[float]:
    diag = []
    for i in range(size):
        cluster = 1.0 + (i % 4) * 0.03
        diag.append(cluster + i * 0.0005)
    matrix = diagonal_matrix(diag)
    noise = make_symmetric(size, rng, scale=0.2)
    return add_matrices(matrix, scale_matrix(noise, 0.05))


def make_small_gap_symmetric(size: int, rng: SplitMix64) -> list[float]:
    diag = [1.0 + i * 0.002 for i in range(size)]
    matrix = diagonal_matrix(diag)
    noise = make_symmetric(size, rng, scale=0.25)
    return add_matrices(matrix, scale_matrix(noise, 0.1))


def size_tier(size: int) -> str:
    if size <= 32:
        return "small"
    if size <= 96:
        return "medium"
    return "large"


def operation_cost_model(operation: str) -> str:
    if operation == "mul":
        return "gemm_flops"
    if operation == "mul_vec":
        return "gemv_flops"
    if operation in {"determinant", "inverse", "rank", "reduce_row_elimination", "cholesky_decomposition", "eigen", "power_method"}:
        return "estimated_dense_work"
    return "elements"


def mutation_policy(operation: str) -> str:
    if operation in {"reduce_row_elimination", "determinant", "inverse", "rank", "cholesky_decomposition", "eigen"}:
        return "scratch_per_sample"
    return "reusable_input"


@dataclass(frozen=True)
class Case:
    id: str
    operation: str
    family: str
    workload_tier: str
    structure: str
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
            "workload_tier": self.workload_tier,
            "structure": self.structure,
            "shape": {
                "rows": self.rows,
                "cols": self.cols,
                "rhs_cols": self.rhs_cols,
            },
            "dtype": "double",
            "timing_scope": "kernel_only",
            "input_layout": "row_major_dense",
            "mutation_policy": mutation_policy(self.operation),
            "size_tier": size_tier(max(self.rows, self.cols, self.rhs_cols)),
            "cost_model": operation_cost_model(self.operation),
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
        workload_tier: str,
        structure: str,
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
                workload_tier=workload_tier,
                structure=structure,
                rows=rows,
                cols=cols,
                rhs_cols=rhs_cols,
                generator_meta=generator_meta,
                data_a=data_a,
                data_b=data_b,
            )
        )

    for seed, size in zip((0x1001, 0x1002, 0x1003), (64, 128, 256)):
        rng = SplitMix64(seed)
        add_case(
            f"mul_baseline_dense_{size}",
            "mul",
            "dense_square",
            "baseline",
            "dense",
            size,
            size,
            size,
            seed,
            dense_matrix(size, size, rng),
            dense_matrix(size, size, rng),
            distribution="uniform[-1,1]",
        )

    for seed, dims in zip((0x1011, 0x1012), ((256, 64, 256), (384, 96, 384))):
        rows, cols, rhs_cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"mul_structured_rect_{rows}x{cols}x{rhs_cols}",
            "mul",
            "dense_rectangular",
            "structured",
            "rectangular_dense",
            rows,
            cols,
            rhs_cols,
            seed,
            dense_matrix(rows, cols, rng),
            dense_matrix(cols, rhs_cols, rng),
            distribution="uniform[-1,1]",
        )

    rng = SplitMix64(0x1013)
    add_case(
        "mul_pathological_rect_256x128x64",
        "mul",
        "dense_rectangular",
        "pathological",
        "shape_mismatch_dense",
        256,
        128,
        64,
        0x1013,
        dense_matrix(256, 128, rng),
        dense_matrix(128, 64, rng),
        distribution="uniform[-1,1]",
    )

    for seed, size in zip((0x2001, 0x2002, 0x2003), (256, 512, 1024)):
        rng = SplitMix64(seed)
        add_case(
            f"mul_vec_baseline_dense_{size}",
            "mul_vec",
            "dense_square",
            "baseline",
            "dense",
            size,
            size,
            1,
            seed,
            dense_matrix(size, size, rng),
            dense_vector(size, rng),
            distribution="uniform[-1,1]",
        )

    rng = SplitMix64(0x2011)
    add_case(
        "mul_vec_structured_dom_512",
        "mul_vec",
        "dense_square",
        "structured",
        "diagonal_dominant",
        512,
        512,
        1,
        0x2011,
        make_dominant_symmetric(512, rng, noise_scale=0.03),
        dense_vector(512, rng),
        distribution="dominant_symmetric",
    )

    rng = SplitMix64(0x2012)
    add_case(
        "mul_vec_pathological_projector_1024x256",
        "mul_vec",
        "dense_rectangular",
        "pathological",
        "projector_like",
        1024,
        256,
        1,
        0x2012,
        make_projector_like(1024, 256, rng),
        dense_vector(256, rng),
        distribution="projector_like",
    )

    for seed, size in zip((0x3001, 0x3002, 0x3003), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"det_baseline_shifted_{size}",
            "determinant",
            "dense_shifted_square",
            "baseline",
            "dense_shifted",
            size,
            size,
            0,
            seed,
            make_dense_shifted(size, rng),
            [],
            distribution="uniform[-1,1]+I",
        )

    for seed, size in zip((0x3011, 0x3012, 0x3013), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"det_structured_upper_tri_{size}",
            "determinant",
            "upper_triangular_square",
            "structured",
            "upper_triangular",
            size,
            size,
            0,
            seed,
            make_upper_triangular(size, rng),
            [],
            distribution="structured",
        )

    for seed, size in zip((0x3021, 0x3022, 0x3023), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"det_pathological_near_singular_{size}",
            "determinant",
            "near_singular_square",
            "pathological",
            "near_singular",
            size,
            size,
            0,
            seed,
            make_near_singular(size, rng),
            [],
            distribution="structured",
        )

    for seed, size in zip((0x4001, 0x4002, 0x4003), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"inverse_baseline_shifted_{size}",
            "inverse",
            "dense_shifted_square",
            "baseline",
            "dense_shifted",
            size,
            size,
            0,
            seed,
            make_dense_shifted(size, rng),
            [],
            distribution="uniform[-1,1]+I",
        )

    for seed, size in zip((0x4011, 0x4012, 0x4013), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"inverse_structured_spd_{size}",
            "inverse",
            "spd_square",
            "structured",
            "spd",
            size,
            size,
            0,
            seed,
            make_spd(size, rng, diagonal_bias=float(size) * 0.75),
            [],
            distribution="gram+lambdaI",
        )

    for seed, size in zip((0x4021, 0x4022, 0x4023), (16, 32, 48)):
        rng = SplitMix64(seed)
        add_case(
            f"inverse_pathological_small_gap_{size}",
            "inverse",
            "near_singular_square",
            "pathological",
            "ill_conditioned",
            size,
            size,
            0,
            seed,
            add_matrices(make_near_singular(size, rng), identity_matrix(size, scale=1.0)),
            [],
            distribution="near_singular+I",
        )

    for seed, dims in zip((0x5001, 0x5002, 0x5003), ((64, 48), (128, 96), (192, 128))):
        rows, cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"rank_baseline_dense_{rows}x{cols}",
            "rank",
            "dense_rectangular",
            "baseline",
            "dense_rectangular",
            rows,
            cols,
            0,
            seed,
            dense_matrix(rows, cols, rng),
            [],
            distribution="uniform[-1,1]",
        )

    for seed, dims in zip((0x5011, 0x5012, 0x5013), ((64, 48), (128, 96), (192, 128))):
        rows, cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"rank_structured_block_{rows}x{cols}",
            "rank",
            "dense_rectangular",
            "structured",
            "block_pattern",
            rows,
            cols,
            0,
            seed,
            make_block_pattern(rows, cols, rng),
            [],
            distribution="block_pattern",
        )

    for seed, dims in zip((0x5021, 0x5022, 0x5023), ((64, 48), (128, 96), (192, 128))):
        rows, cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"rank_pathological_def_{rows}x{cols}",
            "rank",
            "rank_deficient_rectangular",
            "pathological",
            "rank_deficient",
            rows,
            cols,
            0,
            seed,
            make_rect_rank_deficient(rows, cols, rng),
            [],
            distribution="structured",
        )

    for seed, dims in zip((0x6001, 0x6002, 0x6003), ((64, 48), (128, 96), (192, 128))):
        rows, cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"rref_baseline_dense_{rows}x{cols}",
            "reduce_row_elimination",
            "dense_rectangular",
            "baseline",
            "dense_rectangular",
            rows,
            cols,
            0,
            seed,
            dense_matrix(rows, cols, rng),
            [],
            distribution="uniform[-1,1]",
        )

    for seed, dims in zip((0x6011, 0x6012, 0x6013), ((64, 48), (128, 96), (192, 128))):
        rows, cols = dims
        rng = SplitMix64(seed)
        add_case(
            f"rref_structured_block_{rows}x{cols}",
            "reduce_row_elimination",
            "dense_rectangular",
            "structured",
            "block_pattern",
            rows,
            cols,
            0,
            seed,
            make_block_pattern(rows, cols, rng),
            [],
            distribution="block_pattern",
        )

    for seed, size in zip((0x6021, 0x6022, 0x6023), (64, 96, 128)):
        rng = SplitMix64(seed)
        add_case(
            f"rref_pathological_def_{size}",
            "reduce_row_elimination",
            "rank_deficient_square",
            "pathological",
            "rank_deficient",
            size,
            size,
            0,
            seed,
            make_rank_deficient(size, rng),
            [],
            distribution="structured",
        )

    for seed, size in zip((0x7001, 0x7002, 0x7003), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"chol_baseline_spd_{size}",
            "cholesky_decomposition",
            "spd_square",
            "baseline",
            "spd",
            size,
            size,
            0,
            seed,
            make_spd(size, rng, diagonal_bias=float(size)),
            [],
            distribution="gram+lambdaI",
        )

    for seed, size in zip((0x7011, 0x7012, 0x7013), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"chol_structured_spd_{size}",
            "cholesky_decomposition",
            "spd_square",
            "structured",
            "well_conditioned_spd",
            size,
            size,
            0,
            seed,
            make_spd(size, rng, diagonal_bias=float(size) * 1.5),
            [],
            distribution="gram+large_lambdaI",
        )

    for seed, size in zip((0x7021, 0x7022, 0x7023), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"chol_pathological_spd_{size}",
            "cholesky_decomposition",
            "spd_square",
            "pathological",
            "weakly_spd",
            size,
            size,
            0,
            seed,
            make_spd(size, rng, diagonal_bias=1.0),
            [],
            distribution="gram+small_lambdaI",
        )

    for seed, size in zip((0x8001, 0x8002, 0x8003), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"eigen_baseline_sym_{size}",
            "eigen",
            "symmetric_square",
            "baseline",
            "symmetric",
            size,
            size,
            0,
            seed,
            make_symmetric(size, rng),
            [],
            distribution="symmetric_uniform",
        )

    for seed, size in zip((0x8011, 0x8012, 0x8013), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"eigen_structured_clustered_{size}",
            "eigen",
            "symmetric_square",
            "structured",
            "clustered_spectrum",
            size,
            size,
            0,
            seed,
            make_clustered_symmetric(size, rng),
            [],
            distribution="clustered_symmetric",
        )

    for seed, size in zip((0x8021, 0x8022, 0x8023), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"eigen_pathological_small_gap_{size}",
            "eigen",
            "symmetric_square",
            "pathological",
            "close_eigenvalues",
            size,
            size,
            0,
            seed,
            make_small_gap_symmetric(size, rng),
            [],
            distribution="small_gap_symmetric",
        )

    for seed, size in zip((0x9001, 0x9002, 0x9003), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"power_baseline_dom_{size}",
            "power_method",
            "dominant_symmetric_square",
            "baseline",
            "dominant_symmetric",
            size,
            size,
            0,
            seed,
            make_dominant_symmetric(size, rng, noise_scale=0.08),
            [],
            distribution="diagonal_plus_symmetric_noise",
        )

    for seed, size in zip((0x9011, 0x9012, 0x9013), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"power_structured_gap_{size}",
            "power_method",
            "dominant_symmetric_square",
            "structured",
            "large_spectral_gap",
            size,
            size,
            0,
            seed,
            make_dominant_symmetric(size, rng, noise_scale=0.02),
            [],
            distribution="large_gap_dominant",
        )

    for seed, size in zip((0x9021, 0x9022, 0x9023), (32, 64, 96)):
        rng = SplitMix64(seed)
        add_case(
            f"power_pathological_gap_{size}",
            "power_method",
            "dominant_symmetric_square",
            "pathological",
            "small_spectral_gap",
            size,
            size,
            0,
            seed,
            make_small_gap_symmetric(size, rng),
            [],
            distribution="small_gap_symmetric",
        )

    return cases


def manifest_json(cases: list[Case]) -> str:
    payload = {
        "dataset_version": DATASET_VERSION,
        "dtype": "double",
        "cases": [case.manifest_entry() for case in cases],
    }
    return json.dumps(payload, indent=2, sort_keys=False) + "\n"


def case_json(case: Case) -> str:
    return json.dumps(case.json_payload(), indent=2, sort_keys=False) + "\n"


def moon_registry(cases: list[Case]) -> str:
    lines = [
        "// Generated by bench/generate_fixtures.py. Do not edit by hand.",
        "",
        "///|",
        f'pub let dataset_version : String = "{DATASET_VERSION}"',
        "",
    ]
    for case in cases:
        lines.extend(
            [
                "///|",
                f"let case_{case.id} : Case = {{",
                f'  id: "{case.id}",',
                f'  operation: "{case.operation}",',
                f'  family: "{case.family}",',
                f'  workload_tier: "{case.workload_tier}",',
                f'  structure: "{case.structure}",',
                '  timing_scope: "kernel_only",',
                '  input_layout: "row_major_dense",',
                f'  mutation_policy: "{mutation_policy(case.operation)}",',
                f'  size_tier: "{size_tier(max(case.rows, case.cols, case.rhs_cols))}",',
                f'  cost_model: "{operation_cost_model(case.operation)}",',
                f"  rows: {case.rows},",
                f"  cols: {case.cols},",
                f"  rhs_cols: {case.rhs_cols},",
                "}",
                "",
            ]
        )
    lines.extend(
        [
            "///|",
            "pub let cases : Array[Case] = [",
            *[f"  case_{case.id}," for case in cases],
            "]",
            "",
        ]
    )
    return "\n".join(lines)


def rust_registry(cases: list[Case]) -> str:
    lines = [
        "// Generated by bench/generate_fixtures.py. Do not edit by hand.",
        "",
        f'pub const DATASET_VERSION: &str = "{DATASET_VERSION}";',
        "",
        "pub struct Shape {",
        "    pub rows: usize,",
        "    pub cols: usize,",
        "    pub rhs_cols: usize,",
        "}",
        "",
        "pub struct CaseFile {",
        "    pub case_id: &'static str,",
        "    pub operation: &'static str,",
        "    pub family: &'static str,",
        "    pub workload_tier: &'static str,",
        "    pub structure: &'static str,",
        "    pub timing_scope: &'static str,",
        "    pub input_layout: &'static str,",
        "    pub mutation_policy: &'static str,",
        "    pub size_tier: &'static str,",
        "    pub cost_model: &'static str,",
                "    pub shape: Shape,",
        "    pub case_path: &'static str,",
        "}",
        "",
    ]
    for case in cases:
        lines.extend(
            [
                f"const CASE_{case.id.upper()}: CaseFile = CaseFile {{",
                f'    case_id: "{case.id}",',
                f'    operation: "{case.operation}",',
                f'    family: "{case.family}",',
                f'    workload_tier: "{case.workload_tier}",',
                f'    structure: "{case.structure}",',
                '    timing_scope: "kernel_only",',
                '    input_layout: "row_major_dense",',
                f'    mutation_policy: "{mutation_policy(case.operation)}",',
                f'    size_tier: "{size_tier(max(case.rows, case.cols, case.rhs_cols))}",',
                f'    cost_model: "{operation_cost_model(case.operation)}",',
                "    shape: Shape {",
                f"        rows: {case.rows},",
                f"        cols: {case.cols},",
                f"        rhs_cols: {case.rhs_cols},",
                "    },",
                f'    case_path: "../datasets/cases/{case.id}.json",',
                "};",
                "",
            ]
        )
    lines.extend(
        [
            "pub const CASES: &[&CaseFile] = &[",
            *[f"    &CASE_{case.id.upper()}," for case in cases],
            "];",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    cases = make_cases()
    progress = Progress(len(cases) + 3)

    DATASET_DIR.mkdir(parents=True, exist_ok=True)
    CASES_DIR.mkdir(parents=True, exist_ok=True)

    write_if_changed(DATASET_DIR / "manifest.json", manifest_json(cases))
    progress.tick("manifest")

    expected_case_files: set[Path] = set()
    for case in cases:
        case_path = CASES_DIR / f"{case.id}.json"
        expected_case_files.add(case_path)
        write_if_changed(case_path, case_json(case))
        progress.tick(case.id)

    remove_stale_files(list(CASES_DIR.glob("*.json")), expected_case_files)
    write_if_changed(REGISTRY_OUT, moon_registry(cases))
    progress.tick("moon registry")
    write_if_changed(RUST_OUT, rust_registry(cases))
    progress.tick("rust registry")
    progress.finish(f"dataset {DATASET_VERSION} cases={len(cases)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
