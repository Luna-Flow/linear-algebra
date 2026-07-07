# mutable/matrix Design

## Responsibilities

- Provide an execution-oriented `Matrix[T]` with row-major `Array[T]` storage across supported backends.
- Keep live row, column, and transpose views connected to the underlying matrix.
- Keep checked APIs for runtime failures while preserving explicit `unchecked_*` methods for legacy contracts.

## Invariants

- Backend-specific files may tune kernels, but they must expose the same public semantics.
- Bounds checks are explicit for matrix, view, iterator, and transpose access.
- Shared algebraic operations should stay semantically aligned with `immut` where both packages expose them.
