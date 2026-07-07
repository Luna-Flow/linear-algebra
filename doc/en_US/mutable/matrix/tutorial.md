# mutable/matrix Tutorial

## Suggested Flow

1. Build matrices with `Matrix::from_2d_array`, `Matrix::make`, `Matrix::new`, or `Matrix::from_array`.
2. Use `get` and `set` for direct element access, and `row_view` / `col_view` for repeated row or column work.
3. Use checked methods such as `trace`, `determinant`, `inverse`, `mul_vec`, and `pow` when inputs may fail at runtime.

## Practical Guidance

- Use `to_transpose()` when you need a live transposed view; use `transpose()` when you need a materialized matrix.
- Use `unchecked_*` only after shape, non-emptiness, and singularity preconditions have already been enforced.
