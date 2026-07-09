# immut/vector Design

## Responsibilities

- Provide a value-oriented `Vector[T]` backed by the core persistent vector storage alias.
- Keep shared vector algebra aligned with `@mutable.Vector` where the observable operation is the same.
- Exclude in-place mutation APIs from the immutable package.
- Keep scalar-reducing helpers such as `dot()` out of this package's public surface.

## Invariants

- `set`, `map`, and scale operations return new vectors.
- Indexing follows the underlying immutable vector bounds behavior.
- Matrix conversion helpers produce row or column matrices without exposing mutable storage.
- Shared element-wise operations stay aligned with `@mutable.Vector`, but the immutable package remains focused on value-producing transforms.
