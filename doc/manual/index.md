# Luna-Flow/linear-algebra

## v0.5.0 - MoonBit 0.10 migration

This overview matches the current repository baseline for **v0.5.0**. This
release migrates the module to MoonBit 0.10, makes the method surface of every
public type explicit, and temporarily withdraws the native-only OpenBLAS
backend. It is a breaking release in the `0.x` line.

The `mutable` numerical APIs use the shared `Luna-Flow/arithmetic.Sqrt`
capability, while integral embeddings follow
`Luna-Flow/luna-generic.IntegralHomomorphism`. `Tolerance` remains local to the
`mutable` package in this release. Matrix operations with runtime failure modes
use checked `Result[..., LinearAlgebraError]` APIs; the old aborting or
`Option`-returning behavior is exposed through explicit `unchecked_*` methods.

The repository provides the storage-independent `container` capability layer,
generic vector and matrix algorithms, adapters for the concrete storage
representations, and documented algebra integration levels for external types.

For earlier release notes and repository history, see
[CHANGELOG.md](../../CHANGELOG.md).

### Release notes

- **MoonBit 0.10 toolchain required.** The module uses `moon.mod` /
  `moon.pkg` manifests and current syntax, and builds with zero warnings under
  `moon check --target all` with `moonc` `0.10.x` or newer.
- **Explicit method promotion.** Trait methods that remain callable with
  method syntax are promoted explicitly in each package's `extends.mbt`
  (`pub extend T with Trait::{m}`): operators, `equal`, `to_string`, and
  `shape` on the concrete matrix and vector types, `shape` / `transpose` on
  the `backends/default` matrix wrappers, and `equal` on the `error` types.
  The method forms of `not_equal`, `output`, `to_repr`, and `arbitrary` are
  deprecated; use `!=`, string interpolation, `Repr(x)`, or the
  trait-qualified call instead.
- **Indexing via `at` / `set` aliases.** The former `op_get` / `op_set`
  methods are replaced by `at` / `set` (`get` / `set` on `RowView` /
  `ColView`) aliased to `_[_]` / `_[_]=_`. `x[i]` and `x[i] = v` are
  unchanged; explicit `x.op_get(i)` / `x.op_set(i, v)` calls become
  `x.at(i)` / `x.set(i, v)`.
- **OpenBLAS backend temporarily withdrawn.** `backends/openblas` is not
  published in `0.5.0` because its upstream binding
  (`Kaida-Amethyst/openblas` `0.1.3`) does not compile with MoonBit 0.10. The
  source, documentation, and re-enable steps are preserved in
  [`contrib/openblas_backend`](https://github.com/Luna-Flow/linear-algebra/blob/main/contrib/openblas_backend/README.md).
- **Need OpenBLAS today?** Stay on `Luna-Flow/linear-algebra@0.4.7` (with a
  pre-0.10 MoonBit toolchain), or switch to `backends/default`.

See [CHANGELOG.md](../../CHANGELOG.md) for the full list of breaking changes.

## Layered architecture

> **Experimental features:** The `algebra` and `container` capability layers
> are available for integration experiments and ecosystem feedback, but their
> trait hierarchy, operation dictionaries, error contracts, and function
> signatures are not yet compatibility-stable. Downstream libraries should
> not use these packages as stable public boundaries yet. This status does not
> make the concrete `immut`, `mutable`, or backend APIs experimental merely
> because they implement or adapt these capabilities.

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds operation-only traits where needed.
- **`algebra`**: Semantic mathematical structure capabilities. It defines only
  the linear-algebra-owned structure traits.
- **`container`**: Storage-independent read/build, persistent-edit, and
  mutable-edit operation dictionaries, plus map, conversion, and transpose
  algorithms. Concrete adapters live in `container/adapters`.
- **`backends/default`**: The reference dense backend layer. It exposes mutable
  dense wrappers `DenseVector` / `DenseMatrix` and immutable dense wrappers
  `ImmutableDenseVector` / `ImmutableDenseMatrix`.
- **`backends/openblas`** (temporarily withdrawn): The native-only OpenBLAS
  backend is not built in the current line because its upstream binding does
  not compile with MoonBit 0.10. See
  [`contrib/openblas_backend`](https://github.com/Luna-Flow/linear-algebra/blob/main/contrib/openblas_backend/README.md).
- **`error`**: Shared error vocabulary for checked linear-algebra APIs,
  including shape, exponent, empty-matrix, singular-matrix, non-convergence, and
  arithmetic failures.
- **Trait-driven algorithms**: Backend-independent code should depend on the
  smallest capability it needs, such as `MatrixShape`, `AdditiveVector`,
  `VecMulVector`, `TransposeMatrix`, or `MatMulMatrix`.

Mappings from vector or matrix objects into scalar-like categories, such as
inner products or norms, are backend or algorithm details. They are not part of
the core structure trait layer.

The default dense implementation is a backend, not the center of the ecosystem.
Algorithms should depend on minimal linear algebra traits, not concrete dense
matrix/vector types.

This repository is intended to be the linear-algebra substrate for higher-level
math, geometry, and solver-style libraries. Domain-specific solve, regression,
or optimization workflows should live in downstream packages built on these
traits, backend wrappers, and concrete matrix/vector types.

The concrete `immut` / `mutable` matrix and vector types are the
implementations wrapped by `backends/default`. `DenseVector` and `DenseMatrix`
wrap `@mutable.Vector` and `@mutable.Matrix`, while
`ImmutableDenseVector` and `ImmutableDenseMatrix` wrap `@immut.Vector` and
`@immut.Matrix`.
The OpenBLAS-backed native backend is currently withdrawn. When it returns,
it will again be a separate concrete backend, not a runtime backend option
inside `@immut.Matrix`.

## Reader guide

- **General application developers**:
  start with [mutable](./api/mutable/matrix.md) and
  [immut](./api/immut/matrix.md). These are the concrete APIs for application
  code such as business tools, utilities, numeric processing, small games, and
  visualization logic.
- **Math library / general algorithm developers**:
  read in this order:
  [arithmetic](./api/arithmetic.md) ->
  [algebra](./integration/algebra.md) ->
  [container](./integration/container.md) ->
  [backends/default](./api/backends/default.md) ->
  [immut / mutable](./api/immut/matrix.md).
  Start from operation capabilities, then structure capabilities, then the
  default backend wrappers, and finally the concrete implementations. This is the intended entry path if you
  are building a higher-level application library or solver-oriented package on
  top of this repository.

## Used in

- **[`Luna-Flow/geometry3d`](https://github.com/Luna-Flow/geometry3d)**:
  a compact MoonBit 3D geometry foundation built on
  `Luna-Flow/linear-algebra`. It adds core geometry, camera/view math,
  backend-neutral rendering, and TUI / Canvas / GSAP backends on top.
  Its [documentation](https://luna-flow.github.io/en/geometry3d/)
  is a good concrete downstream entry point.

## Trait-oriented project setup

If you want to write backend-independent code with the abstract capability
layers, add the shared upstream abstraction packages explicitly:

```sh
moon add Luna-Flow/linear-algebra@0.5.0
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

Use `@algebra` for linear-algebra structure traits, `@la_arithmetic` for
linear-algebra-facing operation traits, `@lf_alg` for shared upstream algebraic
abstractions, and `@lf_arith` for shared upstream arithmetic types.

## Repository positioning

Matrix and vector infrastructure with both mutable and immutable execution
models.

## Module overview

- **`immut/matrix`**: Implemented around `src/immut`.
- **`immut/vector`**: Implemented around `src/immut`.
- **`mutable/matrix`**: Implemented around `src/mutable`.
- **`mutable/vector`**: Implemented around `src/mutable`.
- **`arithmetic`**: Implemented around `src/arithmetic`.
- **`algebra`**: Implemented around `src/algebra`.
- **`container`**: Implemented around `src/container` and `src/container/adapters`.
- **`backends/default`**: Implemented around `src/backends/default`.
- **`backends/openblas`**: Withdrawn; preserved in `contrib/openblas_backend`.
- **`error`**: Implemented around `src/error`.
