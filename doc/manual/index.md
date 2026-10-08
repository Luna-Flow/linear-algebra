# linear-algebra

This manual documents release `0.5.0` of `Luna-Flow/linear-algebra`.

## Overview

`Luna-Flow/linear-algebra` is the linear-algebra layer of Luna Flow. It
provides dense matrices and vectors in two execution models, value-oriented
(`immut`) and in-place (`mutable`), numerical routines for floating-point
matrices, exact algorithms for integer matrices, and small capability layers
(`algebra`, `container`) that let generic algorithms run on any matrix or
vector type that implements them.

Release `0.5.0` centers on three changes:

- The module builds with the MoonBit 0.10 toolchain and its `moon.mod` /
  `moon.pkg` manifests.
- Indexing is provided by ordinary methods (`at`, `set`, `get`) with
  `#alias("_[_]")`; only the trait methods listed in each package's
  `extends.mbt` are callable with method syntax.
- The native OpenBLAS backend is withdrawn from the module, because its
  upstream binding does not compile with MoonBit 0.10 (see
  [Outside the module](#outside-the-module)).

## Install

```bash
moon add Luna-Flow/linear-algebra@0.5.0
```

Then import the packages you use in your `moon.pkg`:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/immut",
  "Luna-Flow/linear-algebra/mutable",
  "Luna-Flow/linear-algebra/error" @la_error,
}
```

Generic code over scalar types also needs the upstream packages
`Luna-Flow/luna-generic` (`0.3.3`) and `Luna-Flow/arithmetic` (`0.2.2`). The
module needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10) and builds
without warnings with `moon check --target all`. All packages support the
`wasm-gc`, `js`, `wasm` and `native` targets; `mutable` has a tuned kernel file
per target, and the benchmark packages run on `native`.

## Pages

Every package of the module has a tutorial, an API reference and a design
page. The package `src/doc_en_us` is not documented separately: it links every
page of this manual as a `.mbt.md` file so that the examples compile and run as
tests.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `immut`: immutable `Matrix`, `Vector`, lazy `MatrixFn`; exact determinants and powers | [tutorial](tutorial/immut.md) | [API](api/immut.md) | [design](design/immut.md) |
| `mutable`: in-place `Matrix`, `Vector`, views; LU, Cholesky, eigenvalues, statistics | [tutorial](tutorial/mutable.md) | [API](api/mutable.md) | [design](design/mutable.md) |
| `error`: `LinearAlgebraError` for every checked API | [tutorial](tutorial/error.md) | [API](api/error.md) | [design](design/error.md) |
| `arithmetic`: scalar operation traits and re-exports | [tutorial](tutorial/arithmetic.md) | [API](api/arithmetic.md) | [design](design/arithmetic.md) |
| `algebra`: structure traits for whole vectors and matrices (experimental) | [tutorial](tutorial/algebra.md) | [API](api/algebra.md) | [design](design/algebra.md) |
| `backends/default`: dense wrappers implementing the `algebra` traits | [tutorial](tutorial/backends/default.md) | [API](api/backends/default.md) | [design](design/backends/default.md) |
| `container`: storage-independent operation dictionaries and generic conversions (experimental) | [tutorial](tutorial/container.md) | [API](api/container.md) | [design](design/container.md) |
| `container/adapters`: dictionaries for every type of this repository | [tutorial](tutorial/container/adapters.md) | [API](api/container/adapters.md) | [design](design/container/adapters.md) |
| `internal`: shared shape guards (importable only inside this module) | [tutorial](tutorial/internal.md) | [API](api/internal.md) | [design](design/internal.md) |
| `consistency`: cross-package agreement tests (no public items) | [tutorial](tutorial/consistency.md) | [API](api/consistency.md) | [design](design/consistency.md) |
| `perf_support`: benchmark cases, fixtures and execution | [tutorial](tutorial/perf_support.md) | [API](api/perf_support.md) | [design](design/perf_support.md) |
| `perf`: `moon bench` entry package | [tutorial](tutorial/perf.md) | [API](api/perf.md) | [design](design/perf.md) |
| `perf_runner`: single-case benchmark executable | [tutorial](tutorial/perf_runner.md) | [API](api/perf_runner.md) | [design](design/perf_runner.md) |

Guides and chapters that span packages:

| Page | Content |
| --- | --- |
| [Architecture](architecture.md) | how the packages depend on each other, layers, targets, tests |
| [Conventions](conventions.md) | repository rules on top of the Luna Flow documentation standard |
| [Integration: algebra](integration/algebra.md) | how an external type joins the `algebra` traits |
| [Integration: container](integration/container.md) | how an external library publishes `container` dictionaries |

## Exported items

### Concrete types

- `immut`: `Matrix`, `Vector`, `MatrixFn`, the row accessor `Indexed`, the
  aliases `VecLib` and `VecCore`, and the top-level `lin_comb`
- `mutable`: `Matrix`, `Vector`, the views `RowView`, `ColView`, `Transpose`,
  the row accessor `Lens`, the trait `Tolerance`, the re-exported `Sqrt`, and
  the top-level `identity` and `lin_comb`
- `backends/default`: `DenseMatrix`, `DenseVector`, `ImmutableDenseMatrix`,
  `ImmutableDenseVector`, and the generic helpers `matmul`, `transpose`,
  `shape_of`

### Numerical routines

- Exact (`immut`, over `Int`, `Int64`, `BigInt`): `determinant` by Bareiss
  elimination, `pow` by repeated squaring, `trace`, `matmul`
- Floating point (`mutable`, over `Float`, `Double`): `determinant`,
  `inverse`, `is_invertible` and `rank` by LU with partial pivoting,
  `reduce_row_elimination`, `cholesky_decomposition`, `is_positive_definite`,
  `eigen` for symmetric matrices, `power_method`, `mean`, `variance`,
  `std_dev`, `frobenius_norm`
- Every operation with a runtime failure mode has a checked form returning
  `Result[_, LinearAlgebraError]` and an `unchecked_*` form that aborts

### Capability layers

- `algebra`: `MatrixShape`, `VectorShape`, `AdditiveVector`, `VecMulVector`,
  `TransposeMatrix`, `AdditiveMatrix`, `MatMulMatrix`
- `container`: `VectorReadOps`, `VectorBuildOps`, `VectorPersistentEditOps`,
  `VectorMutableEditOps`, their `Matrix*` counterparts, and the algorithms
  `vector_map`, `vector_convert`, `matrix_map`, `matrix_convert`,
  `matrix_transpose`
- `container/adapters`: one factory per type and capability, such as
  `mutable_matrix_read_ops`

### Scalars and errors

- `arithmetic`: `Abs`, `ApproxEq`, `CheckedDiv`, `CheckedSqrt`,
  `CheckedCompare`, and re-exports of `Zero`, `One`, `Inverse`, `Conjugate`,
  `Sqrt` and the other upstream scalar traits and types
- `error`: `LinearAlgebraError`, `LinearAlgebraErrorKind`, constructors and
  `is_*` predicates

## Numerical caveats

The numerical routines of `mutable` decide "zero" with one absolute threshold,
`Tolerance::tolerance()` $= 10^{-11}$, so their results depend on the scale of
the input; scale data to order one. The $2 \times 2$ path of `eigen` has known
accuracy defects, and `@immut.Matrix::determinant` is meant for exact scalars,
not for floating point. The [mutable design](design/mutable.md) and the
[immut design](design/immut.md) derive the algorithms and state these limits
precisely.

## Where to read next

- New to the package: start with the [mutable tutorial](tutorial/mutable.md)
  for numerical work on `Double` matrices, or the
  [immut tutorial](tutorial/immut.md) for value semantics and exact integer
  results. Read the [error tutorial](tutorial/error.md) next, since every
  operation that can fail returns a `LinearAlgebraError`.
- Using it in a library: read the [algebra tutorial](tutorial/algebra.md) and
  the [backends/default tutorial](tutorial/backends/default.md) to write
  generic code, then the [container tutorial](tutorial/container.md) for moving
  data between representations, and the integration guides
  ([algebra](integration/algebra.md), [container](integration/container.md))
  before publishing implementations for your own types. Keep the API pages at
  hand; each item lists its errors, edge cases and cost.
- Contributing: read the [architecture guide](architecture.md), the
  [conventions](conventions.md), the design pages of the package you change,
  and the [internal](tutorial/internal.md) and
  [consistency](tutorial/consistency.md) tutorials. Benchmarks are covered by
  the [perf](tutorial/perf.md) pages.

## Status in 0.5.0

- `algebra`, the trait layer of `backends/default`, and `container` are
  experimental; their signatures may change.
- Release history is in the [changelog](../../CHANGELOG.md).

## Outside the module

The native OpenBLAS backend (`backends/openblas`, with `BlasMatrix`,
`BlasVector` and its `container` adapters) is not part of this release. Its
upstream binding, `Kaida-Amethyst/openblas` `0.1.3`, does not compile with
MoonBit 0.10. The migrated source, its own documentation and a patch for the
binding are preserved in `contrib/openblas_backend`, which is not a package of
the module, is not built and is not covered by this manual. Users who need the
backend can stay on `0.4.7`.

## Validation

Recommended release checks, from the repository root:

```bash
moon check --target all
moon test
./run_test.sh
```

`run_test.sh` runs `immut` and `consistency`, and `container`,
`container/adapters`, `backends/default`, `mutable` and the documentation
package `doc_en_us` on all four targets. Set `LINEAR_ALGEBRA_TEST_BENCH=1` to
add the benchmark packages.
