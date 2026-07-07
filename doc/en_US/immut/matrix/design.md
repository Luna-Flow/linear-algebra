# immut/matrix Design

## Responsibilities

- Provide a value-oriented `Matrix[T]` whose transformation methods return new matrices.
- Keep matrix storage row-major through the immutable vector-backed representation.
- Keep checked matrix operations explicit: shape, exponent, and domain failures belong in `Result[..., LinearAlgebraError]`.

## Invariants

- Constructors reject negative dimensions and non-rectangular input.
- Indexed access and row/column iterators enforce the same bounds rules as the mutable matrix API.
- Matrix algebra should stay aligned with `mutable` where both packages expose the same operation, while preserving value semantics.
