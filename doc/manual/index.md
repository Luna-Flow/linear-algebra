# linear-algebra

`Luna-Flow/linear-algebra` is the linear-algebra layer of Luna Flow. It
provides dense matrices and vectors in two execution models, value-oriented
(`immut`) and in-place (`mutable`), numerical routines for floating-point
matrices, exact algorithms for integer matrices, and small capability layers
(`algebra`, `container`) that let generic algorithms run on any matrix or
vector type that implements them. This manual describes release `0.5.0`.

## Packages

| Package | Purpose | Pages |
| --- | --- | --- |
| `immut` | immutable `Matrix`, `Vector`, lazy `MatrixFn`; exact determinants and powers | [API](api/immut.md) · [tutorial](tutorial/immut.md) · [design](design/immut.md) |
| `mutable` | in-place `Matrix`, `Vector`, views; LU, Cholesky, eigenvalues, statistics | [API](api/mutable.md) · [tutorial](tutorial/mutable.md) · [design](design/mutable.md) |
| `error` | `LinearAlgebraError` for every checked API | [API](api/error.md) · [tutorial](tutorial/error.md) · [design](design/error.md) |
| `arithmetic` | scalar operation traits and re-exports | [API](api/arithmetic.md) · [tutorial](tutorial/arithmetic.md) · [design](design/arithmetic.md) |
| `algebra` | structure traits for whole vectors and matrices (experimental) | [API](api/algebra.md) · [tutorial](tutorial/algebra.md) · [design](design/algebra.md) |
| `backends/default` | dense wrappers implementing the `algebra` traits | [API](api/backends/default.md) · [tutorial](tutorial/backends/default.md) · [design](design/backends/default.md) |
| `container` | storage-independent operation dictionaries and generic conversions (experimental) | [API](api/container.md) · [tutorial](tutorial/container.md) · [design](design/container.md) |
| `container/adapters` | dictionaries for every type of this repository | [API](api/container/adapters.md) · [tutorial](tutorial/container/adapters.md) · [design](design/container/adapters.md) |
| `internal` | shared shape guards (importable only inside this module) | [API](api/internal.md) · [tutorial](tutorial/internal.md) · [design](design/internal.md) |
| `consistency` | cross-package agreement tests (no public items) | [API](api/consistency.md) · [tutorial](tutorial/consistency.md) · [design](design/consistency.md) |
| `perf_support` | benchmark cases, fixtures and execution | [API](api/perf_support.md) · [tutorial](tutorial/perf_support.md) · [design](design/perf_support.md) |
| `perf` | `moon bench` entry package | [API](api/perf.md) · [tutorial](tutorial/perf.md) · [design](design/perf.md) |
| `perf_runner` | single-case benchmark executable | [API](api/perf_runner.md) · [tutorial](tutorial/perf_runner.md) · [design](design/perf_runner.md) |

The package `src/doc_en_us` is not documented separately: it links every page
of this manual as a `.mbt.md` file so that the examples compile and run as
tests. The [architecture guide](architecture.md) shows how the packages depend
on each other. The [integration chapter](integration/algebra.md) explains how
external libraries join the `algebra` and [`container`](integration/container.md)
layers.

## Reading paths

**Application developers.** Start with the [mutable tutorial](tutorial/mutable.md)
for numerical work on `Double` matrices, or the [immut tutorial](tutorial/immut.md)
for value semantics and exact integer results. Read the
[error tutorial](tutorial/error.md) next, since every operation that can fail
returns a `LinearAlgebraError`.

**Library and algorithm authors.** Read the [algebra tutorial](tutorial/algebra.md)
and the [backends/default tutorial](tutorial/backends/default.md) to write
generic code, then the [container tutorial](tutorial/container.md) for moving
data between representations, and the integration guides before publishing
implementations for your own types.

**Contributors.** Read the [architecture guide](architecture.md), the
[conventions](conventions.md), the design pages of the package you change, and
the [internal](tutorial/internal.md) and [consistency](tutorial/consistency.md)
tutorials. Benchmarks are covered by the [perf](tutorial/perf.md) pages.

## Install

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

Import the packages you use in `moon.pkg`:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/immut",
  "Luna-Flow/linear-algebra/mutable",
  "Luna-Flow/linear-algebra/error" @la_error,
}
```

Generic code over scalar types also needs the upstream packages
`Luna-Flow/luna-generic` (`0.3.3`) and `Luna-Flow/arithmetic` (`0.2.2`).

## Toolchain

The module requires MoonBit with `moonc` 0.10 or newer and builds without
warnings with `moon check --target all`. All packages support the `wasm-gc`,
`js`, `wasm` and `native` targets; `mutable` has a tuned kernel file per
target. The benchmark packages are run on `native`.

## Status in 0.5.0

- `algebra`, `backends/default`'s trait layer and `container` are
  experimental; their signatures may change.
- The native OpenBLAS backend is withdrawn in this release because its
  upstream binding does not compile with MoonBit 0.10. Its source is preserved
  outside the manual in `contrib/openblas_backend`; users who need it can stay
  on `0.4.7`.
- Release history is in the [changelog](../../CHANGELOG.md).
