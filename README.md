# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache--2.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.5.0 - MoonBit 0.10 Migration

This README matches the **v0.5.0** repository state. This release migrates the
module to MoonBit 0.10, makes the method surface of every public type explicit,
and temporarily withdraws the native-only OpenBLAS backend. It is a breaking
release in the `0.x` line.

For earlier release notes and repository history, see
[CHANGELOG.md](./CHANGELOG.md).

### Release Notes

- **MoonBit 0.10 toolchain required.** The module now uses `moon.mod` /
  `moon.pkg` manifests and current syntax, and builds with zero warnings under
  `moon check --target all` with `moonc` `0.10.x` or newer.
- **Explicit method promotion.** Trait methods that remain callable with
  method syntax are promoted explicitly in each package's `extends.mbt`
  (`pub extend T with Trait::{m}`): operators (`add`, `sub`, `mul`, `neg`),
  `equal`, `to_string`, and `shape` on the `immut` / `mutable` matrix and
  vector types, `shape` / `transpose` on the `backends/default` matrix
  wrappers, and `equal` on the `error` types. The method forms of
  `not_equal`, `output`, `to_repr`, and `arbitrary` are deprecated; use `!=`,
  string interpolation, `Repr(x)`, or the trait-qualified call instead.
- **Indexing via `at` / `set` aliases.** The former `op_get` / `op_set`
  methods are replaced by ordinary `at` / `set` methods (`get` / `set` on
  `RowView` / `ColView`) aliased to `_[_]` / `_[_]=_`. `x[i]` and
  `x[i] = v` work exactly as before; only explicit `x.op_get(i)` /
  `x.op_set(i, v)` calls need to change to `x.at(i)` / `x.set(i, v)`.
- **OpenBLAS backend temporarily withdrawn.** `backends/openblas`
  (`BlasMatrix[T]`, `BlasVector[T]`, and the `blas_*_ops` container adapters)
  is not published in `0.5.0` because its upstream binding
  (`Kaida-Amethyst/openblas` `0.1.3`) does not compile with MoonBit 0.10. The
  source, documentation, blocker details, and re-enable steps are preserved in
  [`contrib/openblas_backend`](./contrib/openblas_backend/README.md).
- **Need OpenBLAS today?** Stay on the previous release with
  `moon add Luna-Flow/linear-algebra@0.4.7` (and a pre-0.10 MoonBit
  toolchain), or switch to `backends/default`.
- **Documentation compiled on every target.** The `src/doc_*` documentation
  packages no longer depend on OpenBLAS, so the examples in `doc/*` build and
  run on `wasm-gc`, `js`, `native`, and `wasm` as part of `./run_test.sh`.
- `perf_support` fixture-file types (`CaseFixtureFile`, `CaseFixtureInputs`,
  `CaseFixtureShape`) are now private.

See [CHANGELOG.md](./CHANGELOG.md) for the full list of breaking changes.

### Current Capabilities

- The `container` layer exposes read, build, persistent-edit, and
  mutable-edit operation dictionaries without requiring a concrete storage
  representation.
- Generic vector/matrix map and conversion algorithms, plus matrix transpose,
  operate through container capabilities and adapters for the immutable,
  mutable, default dense, and view representations.
- Algebra integration guidance documents shape, additive, transpose,
  Hadamard, and matrix-multiplication capability levels for external types.
- Backend choice is expressed by the concrete type you use, not by a runtime
  ADT; `immut` does not expose runtime backend-selection APIs.
- `backends/default` provides backend methods `scale`, `dot`, `axpy`, and
  `matvec` on its dense vector and matrix wrappers.
- Scalar-valued vector products and BLAS-style linear combinations remain
  backend methods rather than `@algebra` traits.
- The default test gate exercises the container packages, default backend,
  `mutable`, and compiled documentation across Wasm GC, JavaScript, native,
  and Wasm targets.

## Layered Architecture

The checked API line (since `0.4.0`) keeps runtime matrix failures explicit and
exposes the first layered capability packages for backend-independent linear algebra code.

> **Experimental features:** The `algebra` and `container` capability layers
> are available for integration experiments and ecosystem feedback, but their
> trait hierarchy, operation dictionaries, error contracts, and function
> signatures are not yet stable. Downstream libraries should not treat these
> packages as compatibility-stable public boundaries until they graduate from
> experimental status. The concrete `immut`, `mutable`, and backend APIs are
> not covered by this experimental designation solely because they implement
> or provide adapters for these layers.

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds small operation-only traits such as
  `ApproxEq`, `Abs`, `CheckedDiv`, `CheckedSqrt`, and `CheckedCompare`.
- **`algebra`**: Semantic mathematical structure capabilities. It defines only
  the linear-algebra-owned structure traits such as `MatrixShape`,
  `AdditiveVector`, `TransposeMatrix`, and `MatMulMatrix`.
- **`container`**: Storage-independent read, build, persistent-edit, and
  mutable-edit operation dictionaries, plus generic map, conversion, and
  transpose algorithms. Concrete adapters live in `container/adapters`.
- **`backends/default`**: The reference dense backend layer. It exposes wrapper
  types `DenseVector` / `DenseMatrix` over `mutable`, and
  `ImmutableDenseVector` / `ImmutableDenseMatrix` over `immut`, plus backend
  methods for scaling, dot products, AXPY-style combinations, and matrix-vector
  multiplication.
- **`backends/openblas`** (temporarily withdrawn): The native-only OpenBLAS
  backend is not part of the current build because its upstream binding does
  not compile with MoonBit 0.10. The preserved source, the blocker, and the
  re-enable steps live in
  [`contrib/openblas_backend`](./contrib/openblas_backend/README.md).
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
[the `backends/default` docs](./doc/manual/api/backends/default.md).
An OpenBLAS-backed native backend is currently withdrawn; see
[`contrib/openblas_backend`](./contrib/openblas_backend/README.md). When it
returns, it will again be a separate concrete backend, not a runtime backend
option inside `@immut.Matrix`.

### Trait-Oriented Setup

If you want to write backend-independent code against the shared abstract
layers, install `linear-algebra` together with the upstream scalar abstraction
packages it builds on:

```sh
moon add Luna-Flow/linear-algebra@0.5.0
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
  selector. Choose `backends/default` for the repository dense wrappers. The
  native-only `backends/openblas` wrapper is temporarily withdrawn.

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
  [`mutable`](./doc/manual/api/mutable/matrix.md) and
  [`immut`](./doc/manual/api/immut/matrix.md). These are the concrete APIs for
  application code such as business tools, utilities, numeric processing,
  small games, and visualization logic.
- **Math library / general algorithm developers**: Read in this order:
  [`arithmetic`](./doc/manual/api/arithmetic.md) ->
  [`algebra`](./doc/manual/integration/algebra.md) ->
  [`container`](./doc/manual/integration/container.md) ->
  [`backends/default`](./doc/manual/api/backends/default.md) ->
  [`immut` / `mutable`](./doc/manual/api/immut/matrix.md). Start from operation
  capabilities, then structure capabilities, then the default backend wrappers,
  and finally the concrete implementations. This is the intended entry path if
  you are building a higher-level linear-algebra application library, geometry
  package, or solver-style library on top of this repository.

### Documentation Entry Points

- **`immut` concrete API**:
  [`immut.Matrix` API](./doc/manual/api/immut/matrix.md),
  [`immut.Matrix` tutorial](./doc/manual/tutorial/immut/matrix.md),
  [`immut.Vector` API](./doc/manual/api/immut/vector.md),
  [`immut.Vector` tutorial](./doc/manual/tutorial/immut/vector.md)
- **`mutable` concrete API**:
  [`mutable.Matrix` API](./doc/manual/api/mutable/matrix.md),
  [`mutable.Matrix` tutorial](./doc/manual/tutorial/mutable/matrix.md),
  [`mutable.Vector` API](./doc/manual/api/mutable/vector.md),
  [`mutable.Vector` tutorial](./doc/manual/tutorial/mutable/vector.md)
- **Capability and backend layers**:
  [`arithmetic` API](./doc/manual/api/arithmetic.md),
  [`algebra` API](./doc/manual/api/algebra.md),
  [`algebra` ecosystem integration](./doc/manual/integration/algebra.md),
  [`algebra` tutorial](./doc/manual/tutorial/algebra.md),
  [`container` API](./doc/manual/api/container.md),
  [`container` tutorial](./doc/manual/tutorial/container.md),
  [`container` ecosystem integration](./doc/manual/integration/container.md),
  [`backends/default` API](./doc/manual/api/backends/default.md),
  [`backends/openblas` (withdrawn)](./contrib/openblas_backend/README.md),
  [`error` API](./doc/manual/api/error.md)

### Used In

- **[`Luna-Flow/geometry3d`](https://github.com/Luna-Flow/geometry3d)**:
  a compact MoonBit 3D geometry foundation built on
  `Luna-Flow/linear-algebra`, with core geometry, camera/view math,
  backend-neutral frontend rendering, and TUI / Canvas / GSAP backends. See
  its [documentation](https://luna-flow.github.io/en/geometry3d/)
  for a concrete downstream package layout built on this repository.

### Documentation

Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

The manual is published in English, Chinese and Japanese at
<https://luna-flow.github.io/en/linear-algebra/>. Its English source is in
[`doc/manual`](./doc/manual/index.md); the Chinese and Japanese translations
are gettext catalogs in `doc/locale`, so every language shares one page
structure.

## Changelog

Older release notes, historical version summaries, and pre-`0.5.0` repository
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

`run_test.sh` runs the default repository gate: `immut`, `consistency`,
`container`, `container/adapters`, `backends/default`, `mutable`, and the
compiled documentation packages `doc_en_us` / `doc_zh_cn` / `doc_ja_jp`, with
the container, default-backend, mutable, and documentation packages covered on
`wasm-gc`, `js`, `native`, and `wasm`.

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
