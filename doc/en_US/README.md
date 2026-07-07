# Luna-Flow/linear-algebra

This documentation tracks the current repository baseline for **v0.4.0**.

The `mutable` numerical APIs use the shared `Luna-Flow/arithmetic.Sqrt`
capability, while integral embeddings follow
`Luna-Flow/luna-generic.IntegralHomomorphism`. `Tolerance` remains local to the
`mutable` package in this release. Matrix operations with runtime failure modes
now use checked `Result[..., LinearAlgebraError]` APIs; the old aborting or
`Option`-returning behavior is exposed through explicit `unchecked_*` methods.

## Layered Architecture

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds operation-only traits where needed.
- **`algebra`**: Semantic mathematical structure capabilities. It re-exports
  existing Luna Flow algebraic structures and adds linear-algebra-facing
  traits such as `MatrixShape`, `AdditiveVector`, `TransposeMatrix`, and `FloatingScalarOps`.
- **`backends/default`**: The reference dense backend layer. It exposes mutable
  dense wrappers `DenseVector` / `DenseMatrix` and immutable dense wrappers
  `ImmutableDenseVector` / `ImmutableDenseMatrix`.
- **`error`**: Shared error vocabulary for checked linear-algebra APIs,
  including shape, exponent, empty-matrix, singular-matrix, and backend errors.
- **Trait-driven algorithms**: Backend-independent code should depend on the
  smallest same-category capability it needs, such as `MatrixShape`, `AdditiveVector`,
  `VecMulVector`, `TransposeMatrix`, or `MatMulMatrix`.

Mappings from vector or matrix objects into scalar-like categories, such as
inner products or norms, are backend or algorithm details. They are not part of
the core structure trait layer.

The default dense implementation is a backend, not the center of the ecosystem.
Algorithms should depend on minimal linear algebra traits, not concrete dense
matrix/vector types.

## Repository Positioning

Matrix and vector infrastructure with mutable and immutable execution models.

## Documentation Layout

- `README.md` for the repository narrative and release baseline.
- `doc_standard.md` for the documentation contract.
- Module or subsystem folders with `api.md`, `tutorial.md`, and `design.md`.

## Module Overview

- **`immut/matrix`**: Implemented around `src/immut`.
- **`immut/vector`**: Implemented around `src/immut`.
- **`mutable/matrix`**: Implemented around `src/mutable`.
- **`mutable/vector`**: Implemented around `src/mutable`.
- **`arithmetic`**: Implemented around `src/arithmetic`.
- **`algebra`**: Implemented around `src/algebra`.
- **`backends/default`**: Implemented around `src/backends/default`.
- **`error`**: Implemented around `src/error`.

## Documentation Entry Points

- API Reference: [arithmetic](./arithmetic/api.md)
- API Reference: [algebra](./algebra/api.md)
- API Reference: [backends/default](./backends/default/api.md)
- API Reference: [error](./error/api.md)
- API Reference: [immut/matrix](./immut/matrix/api.md)
- API Reference: [immut/vector](./immut/vector/api.md)
- API Reference: [mutable/matrix](./mutable/matrix/api.md)
- API Reference: [mutable/vector](./mutable/vector/api.md)
