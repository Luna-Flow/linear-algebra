# Luna-Flow/linear-algebra

This overview matches the current repository baseline for **v0.4.7**.

The `mutable` numerical APIs use the shared `Luna-Flow/arithmetic.Sqrt`
capability, while integral embeddings follow
`Luna-Flow/luna-generic.IntegralHomomorphism`. `Tolerance` remains local to the
`mutable` package in this release. Matrix operations with runtime failure modes
now use checked `Result[..., LinearAlgebraError]` APIs; the old aborting or
`Option`-returning behavior is exposed through explicit `unchecked_*` methods.

The `0.4.7` baseline adds the storage-independent `container` capability layer,
generic vector and matrix algorithms, adapters for the concrete storage
representations, and documented algebra integration levels for external types.

For earlier release notes and repository history, see
[CHANGELOG.md](../../CHANGELOG.md).

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
- **`backends/default`**: The reference dense backend layer. It exposes mutable
  dense wrappers `DenseVector` / `DenseMatrix` and immutable dense wrappers
  `ImmutableDenseVector` / `ImmutableDenseMatrix`.
- **`backends/openblas`**: A native-only OpenBLAS backend. It exposes the owned
  `BlasMatrix[T]` and `BlasVector[T]` wrappers for `Float` and `Double`, uses
  OpenBLAS GEMM for matrix multiplication, and provides backend methods backed
  by BLAS vector and matrix-vector kernels.
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
For OpenBLAS-backed native matrix multiplication and vector kernels, choose
[`backends/openblas`](./api/backends/openblas.md) explicitly. It is a separate
concrete backend, not a runtime backend option inside `@immut.Matrix`.

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
  [backends/openblas](./api/backends/openblas.md) ->
  [immut / mutable](./api/immut/matrix.md).
  Start from operation capabilities, then structure capabilities, then the
  default backend wrappers, then the optional OpenBLAS native wrapper, and
  finally the concrete implementations. This is the intended entry path if you
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
moon add Luna-Flow/linear-algebra@0.4.7
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

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
- **`backends/openblas`**: Implemented around `src/backends/openblas`.
- **`error`**: Implemented around `src/error`.
