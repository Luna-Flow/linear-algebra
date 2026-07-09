# immut/matrix Tutorial

## Small Case: Patch And Re-export A Layout Matrix

```moonbit check
///|
fn rebuild_layout(matrix : @immut.Matrix[Int]) -> @immut.Matrix[Int] {
  matrix.set(0, 1, 9).swap_rows(0, 1).transpose()
}

///|
test "immut matrix tutorial case" {
  let original = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let exported = rebuild_layout(original)

  inspect(original, content="|1, 2|\n|3, 4|")
  inspect(exported, content="|3, 1|\n|4, 9|")
  inspect(exported.determinant().unwrap(), content="23")
}
```

This case shows a value-oriented matrix workflow:

1. Patch one cell with `set`.
2. Reorder presentation with `swap_rows`.
3. Emit the final layout with `transpose`.
4. Run a checked numeric operation such as `determinant()` on the final value.

Because each step returns a new matrix, the original layout is preserved.

## Suggested Flow

1. Build matrices with `Matrix::from_2d_array`, `Matrix::make`, `Matrix::new`, or `Matrix::from_array`.
2. Use `set`, `swap_rows`, `swap_cols`, `map`, and `transpose` as value-producing operations.
3. Prefer checked `matmul`, `trace`, `determinant`, and `pow` when shape or domain failures can come from runtime data.

## Practical Guidance

- Use `unchecked_*` only when surrounding code has already enforced the required preconditions.
- Use `MatrixFn` when a lazy functional matrix representation is more appropriate than materialized storage.
- Prefer the immutable path when updates should remain explicit and old matrix
  values still need to be preserved for later steps.
