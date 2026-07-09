# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache--2.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.6 - Backend Vector And MatVec Additions

This README matches the **v0.4.6** repository state. This release keeps the
checked `0.4.x` API surface and the packed mutable matrix multiplication work
introduced in `0.4.2`, while extending the backend layer with explicit vector
and matrix-vector helpers, keeping the native OpenBLAS backend explicit, and
aligning the release baseline across code, docs, and CI.

For earlier release notes and repository history, see
[CHANGELOG.md](./CHANGELOG.md).

### Release Notes

- `immut` no longer exposes runtime backend-selection APIs. Backend choice is
  now expressed by the concrete type you use, not by a runtime ADT.
- `backends/default` now provides backend methods `scale`, `dot`, `axpy`, and
  `matvec` on its dense vector and matrix wrappers.
- `backends/openblas` now exposes both `BlasMatrix[T]` and `BlasVector[T]` for
  `Float` and `Double`, using OpenBLAS GEMM for matrix multiplication plus
  BLAS-backed `dot`, `scal`, `axpy`, and `gemv` for vector and matrix-vector
  work.
- Scalar-valued vector products and BLAS-style linear combinations remain
  backend methods. They were not promoted into new `@algebra` traits in this
  release.
- The README, localized docs, API baseline pages, install snippets, generated
  interfaces, and CI/publish workflows are all aligned to the `0.4.6` release
  baseline.

## Layered Architecture

The checked `0.4.x` line keeps runtime matrix failures explicit and exposes the
first layered capability packages for backend-independent linear algebra code.

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds small operation-only traits such as
  `ApproxEq`, `Abs`, `CheckedDiv`, `CheckedSqrt`, and `CheckedCompare`.
- **`algebra`**: Semantic mathematical structure capabilities. It defines only
  the linear-algebra-owned structure traits such as `MatrixShape`,
  `AdditiveVector`, `TransposeMatrix`, and `MatMulMatrix`.
- **`backends/default`**: The reference dense backend layer. It exposes wrapper
  types `DenseVector` / `DenseMatrix` over `mutable`, and
  `ImmutableDenseVector` / `ImmutableDenseMatrix` over `immut`, plus backend
  methods for scaling, dot products, AXPY-style combinations, and matrix-vector
  multiplication.
- **`backends/openblas`**: A native-only OpenBLAS backend. It exposes the owned
  `BlasMatrix[T]` and `BlasVector[T]` wrappers for `Float` and `Double`, uses
  OpenBLAS GEMM for matrix multiplication, BLAS vector kernels for backend
  methods like `dot` / `axpy`, and keeps backend choice explicit through the
  concrete type rather than a runtime selector.
- **Trait-driven algorithms**: New backend-independent algorithms should depend
  on the smallest capability they need, such as `MatrixShape`,
  `AdditiveVector`, `VecMulVector`, `TransposeMatrix`, or `MatMulMatrix`, not
  directly on one concrete matrix or vector type.

The default dense implementation is a backend, not the center of the ecosystem.
Algorithms should depend on minimal linear algebra traits, not concrete dense
matrix/vector types.

This repository is intended to be a linear-algebra substrate for higher-level
math, geometry, and solver-style libraries. Domain-specific solve, regression,
or optimization workflows belong in downstream packages built on these traits,
backend wrappers, and concrete matrix/vector types.

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
For OpenBLAS-backed native matrix multiplication and vector kernels, use
[`backends/openblas`](./doc/en_US/backends/openblas/api.md) explicitly; it is a
separate concrete backend, not a runtime backend option inside `@immut.Matrix`.

### Trait-Oriented Setup

If you want to write backend-independent code against the shared abstract
layers, install `linear-algebra` together with the upstream scalar abstraction
packages it builds on:

```sh
moon add Luna-Flow/linear-algebra@0.4.6
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

### Checked Contracts

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
- **Backend Choice**: `@immut.Matrix` does not expose a runtime backend
  selector. Choose `backends/default` for the repository dense wrappers or
  `backends/openblas` for the native-only OpenBLAS matrix wrapper.

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

### Reader Guide

- **General application developers**: Start with
  [`mutable`](./doc/en_US/mutable/matrix/api.md) and
  [`immut`](./doc/en_US/immut/matrix/api.md). These are the concrete APIs for
  application code such as business tools, utilities, numeric processing,
  small games, and visualization logic.
- **Math library / general algorithm developers**: Read in this order:
  [`arithmetic`](./doc/en_US/arithmetic/api.md) ->
  [`algebra`](./doc/en_US/algebra/api.md) ->
  [`backends/default`](./doc/en_US/backends/default/api.md) ->
  [`backends/openblas`](./doc/en_US/backends/openblas/api.md) ->
  [`immut` / `mutable`](./doc/en_US/immut/matrix/api.md). Start from operation
  capabilities, then structure capabilities, then the default backend wrappers,
  then the optional OpenBLAS native wrapper, and finally the concrete
  implementations. This is the intended entry path if
  you are building a higher-level linear-algebra application library, geometry
  package, or solver-style library on top of this repository.

### Documentation Entry Points

- **`immut` concrete API**:
  [`immut.Matrix` API](./doc/en_US/immut/matrix/api.md),
  [`immut.Matrix` tutorial](./doc/en_US/immut/matrix/tutorial.md),
  [`immut.Vector` API](./doc/en_US/immut/vector/api.md),
  [`immut.Vector` tutorial](./doc/en_US/immut/vector/tutorial.md)
- **`mutable` concrete API**:
  [`mutable.Matrix` API](./doc/en_US/mutable/matrix/api.md),
  [`mutable.Matrix` tutorial](./doc/en_US/mutable/matrix/tutorial.md),
  [`mutable.Vector` API](./doc/en_US/mutable/vector/api.md),
  [`mutable.Vector` tutorial](./doc/en_US/mutable/vector/tutorial.md)
- **Capability and backend layers**:
  [`arithmetic` API](./doc/en_US/arithmetic/api.md),
  [`algebra` API](./doc/en_US/algebra/api.md),
  [`backends/default` API](./doc/en_US/backends/default/api.md),
  [`backends/openblas` API](./doc/en_US/backends/openblas/api.md),
  [`backends/openblas` tutorial](./doc/en_US/backends/openblas/tutorial.md),
  [`error` API](./doc/en_US/error/api.md)

### Used In

- **[`Luna-Flow/geometry3d`](https://github.com/Luna-Flow/geometry3d)**:
  a compact MoonBit 3D geometry foundation built on
  `Luna-Flow/linear-algebra`, with core geometry, camera/view math,
  backend-neutral frontend rendering, and TUI / Canvas / GSAP backends. See
  its [English docs](https://github.com/Luna-Flow/geometry3d/blob/main/doc/en_US/README.md)
  for a concrete downstream package layout built on this repository.

### Documentation

Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

We provide documentation in multiple languages:

- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

`doc/*` is the hand-written documentation source. The `src/doc_*` packages are
MoonBit documentation exposure layers made of symlinks back to `doc/*`.

Localized README files:

- 🇺🇸 [README.md](./README.md)
- 🇨🇳 [README.md](./doc/zh_CN/README.md)
- 🇯🇵 [README.md](./doc/ja_JP/README.md)

## Changelog

Older release notes, historical version summaries, and pre-`0.4.6` repository
highlights now live in [CHANGELOG.md](./CHANGELOG.md). This README keeps the
current baseline and entry points front and center.

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
2. Update `README.md` and `CHANGELOG.md` so the current release notes and historical version notes match the package contents.
3. Run `moon check --target all` and `./run_test.sh`; both are required before publishing.
4. If the change touches benchmark fixtures, fixture recovery, or diagnostic runners, also run `LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh`.
5. Trigger `publish-package`; it will publish the version currently declared in `moon.mod`.

If the workflow reports a duplicate version, the package manager already contains that version and a new version bump is required.

Contribution guidance is available in [CONTRIBUTING.md](./CONTRIBUTING.md).
