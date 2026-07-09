# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.2 - Packed Kernels and Fixture Recovery

This README matches the **v0.4.2** repository state. The release keeps the
checked matrix API surface introduced in `0.4.0` and the public unchecked
multiplication entry point added in `0.4.1`, while focusing on large-matrix
throughput and benchmark fixture recovery.

### Maintenance Changes

- `mutable.Matrix::unchecked_matmul` now switches between the existing
  unrolled kernel and a packed-right-hand-side kernel, depending on matrix
  shape and total work.
- The packed kernel is available on Native, JS, Wasm, and Wasm GC, so larger
  dense matrix products can reuse right-hand-side columns with fewer repeated
  cache-unfriendly reads.
- Checked `mutable.Matrix` multiplication still validates dimensions first and
  then delegates to `unchecked_matmul`, so the optimized hot path stays in one
  place.
- `perf_support` and `perf_runner` now recreate missing
  `bench/datasets/cases/*.json` fixtures on demand from the tracked dataset
  registry, which keeps direct local tests and runner commands working on a
  clean checkout.
- Bulk benchmark generation still flows through
  `bench/generate_fixtures.py`, so tracked metadata and generated registries
  remain aligned.

## v0.4.0 - Checked Matrix APIs and Layered Capabilities

The `0.4.0` release made matrix failure modes explicit with checked `Result`
APIs and added the first layered capability packages for backend-independent
linear algebra code.

### Breaking Changes

These source-incompatible API changes established the `0.4.x` line.

- `immut.Matrix::{matmul, trace, determinant, pow}` now return
  `Result[..., @error.LinearAlgebraError]`.
- `mutable.Matrix::{trace, determinant, inverse, is_invertible, mul_vec, pow,
  matrix_power, mean, variance, std_dev, max_element, min_element}` now return
  `Result[..., @error.LinearAlgebraError]`.
- The old aborting or `Option`-returning behavior remains available through the
  matching `unchecked_*` methods for callers that intentionally want the legacy
  contract.
- New code should handle `Ok` / `Err`; migration code can usually replace
  direct value calls with `.unwrap()` or the corresponding `unchecked_*` method
  where the old preconditions are already guaranteed.

### Layered Architecture

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds small operation-only traits such as
  `ApproxEq`, `Abs`, `CheckedDiv`, `CheckedSqrt`, and `CheckedCompare`.
- **`algebra`**: Semantic mathematical structure capabilities. It defines only
  the linear-algebra-owned structure traits such as `MatrixShape`,
  `AdditiveVector`, `TransposeMatrix`, and `MatMulMatrix`.
- **`backends/default`**: The reference dense backend layer. It exposes wrapper
  types `DenseVector` / `DenseMatrix` over `mutable`, and
  `ImmutableDenseVector` / `ImmutableDenseMatrix` over `immut`.
- **Trait-driven algorithms**: New backend-independent algorithms should depend
  on the smallest capability they need, such as `MatrixShape`, `AdditiveVector`,
  `VecMulVector`, `TransposeMatrix`, or `MatMulMatrix`, not directly on one
  concrete matrix or vector type.

The default dense implementation is a backend, not the center of the ecosystem.
Algorithms should depend on minimal linear algebra traits, not concrete dense
matrix/vector types.

### Package Positioning

- **`immut`**: Immutable, value-oriented `Matrix`, `Vector`, and `MatrixFn` types for persistent data and explicit copy-on-update semantics.
- **`mutable`**: Execution-oriented `Matrix` and `Vector` types with in-place updates, `Transpose` views, `RowView` / `ColView`, and backend-specific implementations for `js`, `wasm`, `wasm-gc`, and `native`.
- **Shared Core, Different Execution Model**: Constructors and core algebraic operators remain aligned across packages, but mutation and access semantics are intentionally different.

The default backend wrappers are built on top of these concrete types:
`backends/default.DenseVector` and `backends/default.DenseMatrix` wrap
`mutable.Vector` and `mutable.Matrix`, while
`backends/default.ImmutableDenseVector` and
`backends/default.ImmutableDenseMatrix` wrap `immut.Vector` and
`immut.Matrix`. If you want the trait-oriented default backend entry point, see
[the `backends/default` docs](./doc/en_US/backends/default/api.md).

### Trait-Oriented Setup

If you want to write backend-independent code against the shared abstract
layers, install `linear-algebra` together with the upstream scalar abstraction
packages it builds on:

```sh
moon add Luna-Flow/linear-algebra@0.4.2
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Then import the packages with explicit aliases in your `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

Use `@algebra` for linear-algebra structure traits, `@la_arithmetic` for
linear-algebra-facing operation traits, `@lf_alg` for shared upstream algebraic
abstractions, and `@lf_arith` for shared upstream arithmetic types such as
`ArithmeticContext`.

### What Defines v0.4.0

- **Checked Matrix Contracts**: Shape, exponent, empty-matrix, and singular
  matrix failures are now represented by `LinearAlgebraError` on the checked
  matrix APIs.
- **Legacy Behavior Is Explicit**: `unchecked_*` methods preserve the previous
  aborting behavior, and `unchecked_inverse` preserves the previous
  `Option`-returning inverse contract.
- **Public Error Package**: `linear-algebra/error` exposes
  `LinearAlgebraError`, `LinearAlgebraErrorKind`, constructors, and `is_*`
  predicates for callers that need structured error handling.
- **Shared Square-Root Capability**: Numerical matrix APIs now use `Luna-Flow/arithmetic.Sqrt` instead of a package-local trait. `mutable` re-exports the shared trait for source-level discoverability.
- **Target-Side Integral Embedding**: Generic integer conversions use `IntegralHomomorphism::from_integral`, matching the current `Luna-Flow/luna-generic` algebraic model.
- **Ecosystem-Oriented Constraints**: Custom scalar types can implement the shared Luna Flow traits once and use them across compatible ecosystem packages.
- **Backend Consistency**: Native, JS, Wasm, and Wasm GC matrix implementations use the same arithmetic capability identity and explicit trait invocation.
- **Compatibility Boundary**: `Tolerance` remains a `mutable` package trait in this release; it has not yet moved to `arithmetic`.

### API Guidance & Performance

- **Core Algebraic API**: Shared operations such as `make`, `transpose`, `+`, `-`, `*`, `trace`, and matrix/vector conversions are intended to stay semantically aligned across `immut` and `mutable`.
- **Checked vs. Unchecked**: Prefer checked methods in user-facing code. Use
  `unchecked_*` only when shape and domain preconditions are already enforced by
  surrounding logic.
- **Random Access**: In `mutable`, for high-performance random access, prefer `.get(i, j)` and `.set(i, j, val)` directly.
- **Structured Views**: For repeated row or column work in `mutable`, prefer `row_view()` / `col_view()` instead of relying on `matrix[row]` convenience syntax.
- **Strict Bounds**: Public matrix, view, and transpose accessors consistently reject out-of-bounds indices, including `0xN` and `Nx0` edge cases.
- **MatrixFn Alignment**: `immut.MatrixFn` now shares the same non-negative dimension and empty-matrix semantics as the concrete matrix implementations.
- **Public Surface**: Internal decomposition helpers remain implementation details. Package users should rely on the documented public matrix methods instead.

### Key Features

- **Mutable & Immutable Support**: Full `Matrix` and `Vector` suites with distinct semantics for value-oriented and execution-oriented workloads.
- **Advanced Operations**: Includes determinant, inverse, rank, Cholesky decomposition, eigen-related routines, row elimination, transpose views, and matrix/vector conversions.
- **Shared Data Model, Backend-Tuned Kernels**: `mutable` still ships backend-tuned execution paths for Native, Wasm, JS, and Wasm GC targets, but the core matrix storage model is now unified.
- **Benchmark Infrastructure**: `bench/`, `src/perf_support`, and `src/perf_runner` now form a full steady-state benchmarking subsystem for backend comparison and diagnostic replay.
- **Correctness First**: Coverage now includes immutable laws, cross-package consistency checks, determinant/rank/inverse alignment, and regression tests for numerical behavior.
- **Auditable Public Contracts**: Bounds behavior, swap semantics, benchmark fixtures, and documentation are now tracked more explicitly as part of the repository’s correctness story.

### Benchmark Packages

- **`perf`**: Benchmark entry package used by `moon bench` for the steady-state matrix suite.
- **`perf_support`**: Public fixture metadata, case registry, runtime loaders, and checksum-oriented execution helpers for benchmark cases.
- **`perf_runner`**: Single-case diagnostic and sampling runner used for replay, local investigation, and richer benchmark artifact generation.

These benchmark-facing packages are part of the local performance-analysis
tooling. They are not part of the default CI or publish acceptance gate unless
you explicitly opt in with `LINEAR_ALGEBRA_TEST_BENCH=1`.

### Quick Start

```moonbit check
///|
test "linear-algebra basic workflow" {
  let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let imm_updated = imm.set(0, 1, 9)
  inspect(imm_updated, content="|1, 9|\n|3, 4|")

  let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  m.set(0, 1, 9.0)

  inspect(m.determinant().unwrap(), content="-23")
  inspect(m.inverse() is Ok(_), content="true")
  inspect(m.row_view(0)[1], content="9")
}
```

### Find Your Entry Point

Start with the concrete `immut` / `mutable` types when you want to use the
repository directly. Start with the capability layers when you want
backend-independent generic code.

- **I want concrete immutable types**:
  [`immut.Matrix` API](./doc/en_US/immut/matrix/api.md),
  [`immut.Matrix` tutorial](./doc/en_US/immut/matrix/tutorial.md),
  [`immut.Vector` API](./doc/en_US/immut/vector/api.md),
  [`immut.Vector` tutorial](./doc/en_US/immut/vector/tutorial.md)
- **I want concrete mutable types**:
  [`mutable.Matrix` API](./doc/en_US/mutable/matrix/api.md),
  [`mutable.Matrix` tutorial](./doc/en_US/mutable/matrix/tutorial.md),
  [`mutable.Vector` API](./doc/en_US/mutable/vector/api.md),
  [`mutable.Vector` tutorial](./doc/en_US/mutable/vector/tutorial.md)
- **I want abstract capability layers for generic algorithms**:
  [`arithmetic` API](./doc/en_US/arithmetic/api.md),
  [`algebra` API](./doc/en_US/algebra/api.md),
  [`backends/default` API](./doc/en_US/backends/default/api.md),
  [`error` API](./doc/en_US/error/api.md)

### How To Choose

- Choose **`mutable`** when you want direct execution-oriented dense matrix or
  vector work, in-place updates, views, and the full concrete numerical API.
- Choose **`immut`** when you want value semantics, copy-on-update behavior,
  and concrete dense matrix/vector types without mutation.
- Choose **`arithmetic`** and **`algebra`** when you are defining algorithm
  requirements and want code that is not tied to one concrete backend.
- Choose **`backends/default`** when you want the repository's default dense
  backend exposed through the public algebra traits.

### Documentation

Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

We provide documentation in multiple languages:

- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

Localized README files:

- 🇺🇸 [README.md](./README.md)
- 🇨🇳 [README.md](./doc/zh_CN/README.md)
- 🇯🇵 [README.md](./doc/ja_JP/README.md)

## Version History

| Version | Date | Status | Notes |
| --- | --- | --- | --- |
| `0.4.2` | 2026-07-09 | current repository release | Added packed mutable matmul kernels for larger products and automatic benchmark fixture recovery for clean checkouts |
| `0.4.1` | 2026-07-07 | previous release baseline | Refined benchmark measurement, added public unchecked mutable matmul, optimized mutable hot loops, and simplified publishing |
| `0.4.0` | 2026-07-07 | previous release baseline | Introduced checked matrix APIs, structured linear-algebra errors, layered capability packages, and default backend wrappers |
| `0.3.0` | 2026-06-14 | published on mooncakes | Adopted shared `arithmetic.Sqrt`, current `luna-generic` homomorphisms, and ecosystem-wide numeric capability identities |
| `0.2.12` | 2026-06-06 | published on mooncakes | Strict bounds unification, semantic correctness fixes, benchmark diagnostics expansion, and documentation/audit refresh |
| `0.2.11` | 2026-05-27 | previous release baseline | Performance-tuned mutable kernels, dedicated wasm-gc backend, benchmark/reporting expansion, and API/doc alignment |
| `0.2.10` | 2026-05-27 | previous release baseline | Unified flattened mutable storage, matrix views, consistency coverage, benchmark coverage, and release-process alignment |
| `0.2.9` | 2026-02-03 | published on mooncakes | Published from the earlier `3328195` release state |
| `0.2.8` | 2026-02-03 | historical baseline | Algorithms and stability milestone used as the comparison baseline for later work |

## Current Repository Highlights

- **Current Release Narrative (0.4.2)**:
  - Mutable matrix multiplication now adds a packed right-hand-side kernel for
    larger dense products while keeping the smaller unrolled path for light
    workloads.
  - The packed matmul path is implemented consistently across Native, JS, Wasm,
    and Wasm GC backends.
  - `perf_support` and `perf_runner` can rebuild a missing benchmark fixture
    from tracked metadata before executing a direct test or runner command.
  - Bulk benchmark generation still goes through `bench/generate_fixtures.py`,
    so the tracked manifest and generated registries remain the source of truth.

- **Previous Release Narrative (0.4.1)**:
  - Mutable matrix multiplication exposes `unchecked_matmul` for validated call
    sites and benchmark hot paths.
  - Matrix multiplication, LU trailing updates, and Cholesky accumulation have
    backend-aligned loop unrolling.
  - Benchmark fixture documentation now makes per-case JSON generation an
    on-demand local artifact.
  - Publishing uses the version in `moon.mod` directly.

- **Previous Release Narrative (0.4.0)**:
  - Matrix operations with runtime failure modes now return `Result[..., LinearAlgebraError]`.
  - Legacy matrix behavior is available through explicit `unchecked_*` methods.
  - `linear-algebra/error` documents the shared error vocabulary for checked APIs.
  - `arithmetic`, `algebra`, and `backends/default` provide the new trait-oriented layering for generic algorithms.

- **Previous Release Narrative (0.3.0)**:
  - Square-root-dependent matrix algorithms now require the shared `arithmetic.Sqrt` capability.
  - `mutable.Sqrt` is a public re-export of `arithmetic.Sqrt`; the old package-local trait and scalar implementations were removed.
  - Integral test fixtures and conversion helpers now use target-side `IntegralHomomorphism::from_integral`.
  - Custom numeric types should implement capabilities in `luna-generic` and `arithmetic` rather than package-specific linear-algebra traits.

- **Earlier Release Narrative (0.2.12)**:
  - Public matrix, view, and transpose accessors enforce explicit bounds contracts, including zero-row and zero-column edge shapes.
  - `immut.Matrix` and `mutable.Matrix` are aligned on shared correctness semantics while preserving their value-vs-mutation execution split.
  - Benchmark diagnostics and the tracked correctness audit reflect the exported `0.2.12` surface.

- **Earlier Release Narrative (0.2.11)**:
  - `mutable.Matrix` now combines the shared flat storage model from `0.2.10` with follow-up backend kernel optimizations and a dedicated `wasm-gc` implementation.
  - Public numerical signatures are aligned around `Field` / `Num` / `Tolerance`, and immutable determinant documentation matches the simplified post-`0.2.10` constraint set.
  - The benchmark stack now includes runtime-loaded fixtures, expanded case metadata, richer summary reporting, a local dashboard, optional Rust comparison runs, and diagnostic replay via `perf_runner`.
  - The release checklist, benchmark docs, package overview, and localized READMEs are aligned to the `0.2.11` release story.

- **Algorithms & Stability (0.2.8)**:
  - Added LU- and QR-related decomposition support used by determinant, inverse, rank, and eigen routines.
  - Shifted determinant and rank behavior toward more stable elimination-based implementations.

- **Native Optimization (0.2.7)**:
  - Implemented transposition + dot-product strategy for Native matrix multiplication, outperforming naive implementations by more than 2x.
  - Optimized `make`, `new`, and `transpose` to remove expensive integer division in hot loops.

- **Performance Overhaul (0.2.4)**:
  - Optimized secondary utilities such as `mapi` and `each_row_col`.
  - Improved hybrid matrix multiplication and vector linear-combination performance.

- **Other Fixes & Renames**:
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - Corrected determinant behavior for `0x0` matrices.
  - Fixed copy-on-conversion behavior between vectors and matrices.

## Development

Useful local commands:

```bash
moon fmt
moon info
moon check
moon test -p perf_support
moon test -p perf_runner
moon test --enable-coverage
./run_test.sh
LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh
```

`run_test.sh` runs the default repository gate: `immut`, `consistency`, and
`mutable` on `wasm-gc`, `js`, `native`, and `wasm`.

`perf_support` and `perf_runner` stay opt-in for local fixture-recovery checks
and performance diagnostics. Run them explicitly with `moon test -p ...` or use
`LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh` when you want that path.

Runnable entry points:

```bash
# This repository is primarily a library, so use an explicit package target.
moon run src/perf_runner mul_baseline_dense_64

# Optional: materialize benchmark fixtures ahead of time.
python3 bench/generate_fixtures.py

# Full benchmark flow.
just bench
```

`moon run src/perf_runner ...` defaults to `bench/datasets/cases/<case-id>.json`.
If that fixture file is missing on a clean checkout, `perf_support` will
recreate it automatically from the tracked dataset registry before executing the
case.

## Release Checklist

Before triggering the publish workflow:

1. Bump `moon.mod` to the intended next release version before publishing.
2. Update `README.md` so the release notes and version history match the package contents.
3. Run `moon check --target all` and `./run_test.sh`; both are required before publishing.
4. If the change touches benchmark fixtures, fixture recovery, or diagnostic runners, also run `LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh`.
5. Trigger `publish-package`; it will publish the version currently declared in `moon.mod`.

If the workflow reports a duplicate version, the package manager already contains that version and a new version bump is required.

Contribution guidance is available in [CONTRIBUTING.md](./CONTRIBUTING.md).
