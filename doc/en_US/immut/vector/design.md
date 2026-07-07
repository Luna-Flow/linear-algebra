# immut/vector Design

## Responsibilities

- Provide a value-oriented `Vector[T]` backed by the core persistent vector storage alias.
- Keep shared vector algebra aligned with `@mutable.Vector` where the observable operation is the same.
- Exclude in-place mutation APIs from the immutable package.

## Invariants

- `set`, `map`, and scale operations return new vectors.
- Indexing follows the underlying immutable vector bounds behavior.
- Matrix conversion helpers produce row or column matrices without exposing mutable storage.
