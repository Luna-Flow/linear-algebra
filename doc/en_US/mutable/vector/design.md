# mutable/vector Design

## Responsibilities

- Provide an execution-oriented `Vector[T]` backed by `Array[T]`.
- Support direct indexed reads and writes for workloads that need in-place updates.
- Keep non-`inplace` algebraic helpers available for value-producing transforms.
- Keep scalar-reducing and aggregate helpers such as `dot()` in the mutable package.

## Invariants

- `*_inplace` methods mutate the existing vector and return `Unit`.
- `map`, scale helpers, `zip_with`, and matrix conversion helpers return new values.
- Vector algebra should stay aligned with `@immut.Vector` for the shared operation subset.
- Length-sensitive helpers such as `dot()` and `lin_comb(...)` reject inconsistent inputs explicitly.
