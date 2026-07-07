# immut/matrix Tutorial

## Suggested Flow

1. Build matrices with `Matrix::from_2d_array`, `Matrix::make`, `Matrix::new`, or `Matrix::from_array`.
2. Use `set`, `swap_rows`, `swap_cols`, `map`, and `transpose` as value-producing operations.
3. Prefer checked `matmul`, `trace`, `determinant`, and `pow` when shape or domain failures can come from runtime data.

## Practical Guidance

- Use `unchecked_*` only when surrounding code has already enforced the required preconditions.
- Use `MatrixFn` when a lazy functional matrix representation is more appropriate than materialized storage.
