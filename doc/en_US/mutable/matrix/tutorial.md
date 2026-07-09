# mutable/matrix Tutorial

## Small Case: Calibrate A Dense Numeric Matrix

```moonbit check
///|
fn calibrate_dense_matrix(matrix : @mutable.Matrix[Double]) -> Double {
  let first_row = matrix.row_view(0)
  first_row[1] = 9.0
  let first_col = matrix.col_view(0)
  first_col[1] = 5.0
  matrix.determinant().unwrap()
}

///|
test "mutable matrix tutorial case" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let det = calibrate_dense_matrix(matrix)

  inspect(matrix, content="|1, 9|\n|5, 4|")
  inspect(det, content="-41")
  inspect(matrix.inverse() is Ok(_), content="true")
}
```

This pattern works well when a matrix is a live working buffer:

1. Build the matrix once.
2. Use `row_view` and `col_view` to patch the hot regions directly.
3. Run checked numeric APIs like `determinant()` and `inverse()` after the
   edits are complete.

That combination is the fastest path when the matrix is a concrete execution
object rather than a historical value.

## Suggested Flow

1. Build matrices with `Matrix::from_2d_array`, `Matrix::make`, `Matrix::new`, or `Matrix::from_array`.
2. Use `get` and `set` for direct element access, and `row_view` / `col_view` for repeated row or column work.
3. Use checked methods such as `trace`, `determinant`, `inverse`, `mul_vec`, and `pow` when inputs may fail at runtime.

## Practical Guidance

- Use `to_transpose()` when you need a live transposed view; use `transpose()` when you need a materialized matrix.
- Use `unchecked_*` only after shape, non-emptiness, and singularity preconditions have already been enforced.
- Reach for row/column views when one region of the matrix will be updated or
  inspected repeatedly.
