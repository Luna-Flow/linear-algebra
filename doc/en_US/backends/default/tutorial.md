# backends/default Tutorial

## Small Case: Accept The Default Dense Backend Without Hard-Wiring The Algorithm

```moonbit check
///|
fn[M : @algebra.MatrixShape] matrix_shape(matrix : M) -> (Int, Int) {
  @default.shape_of(matrix)
}

///|
test "shape_of dispatches through MatrixShape" {
  let matrix : @default.DenseMatrix[Int] = @default.DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  let (rows, cols) = matrix_shape(matrix)
  inspect(rows, content="2")
  inspect(cols, content="2")
}
```

This case demonstrates the intended role of the default backend layer:

1. Construct a concrete dense matrix with `DenseMatrix`.
2. Pass it into a helper that asks only for `MatrixShape`.
3. Let `@default.shape_of` bridge the concrete wrapper and the public trait-oriented view.

That gives users a ready-to-use dense backend while still keeping new
algorithms portable.

## Suggested Flow

1. Start with `DenseMatrix`, `DenseVector`, `ImmutableDenseMatrix`, or `ImmutableDenseVector` when you want the repository's reference backend immediately.
2. Write new reusable helpers against `algebra` traits such as `MatrixShape`.
3. Keep the backend wrapper at the boundary where concrete storage is actually chosen.

## Practical Guidance

- Use the default backend wrappers when you want a public dense implementation with straightforward constructors.
- Keep backend-specific products, norms, solve strategies, or decompositions in the backend or a dedicated algorithm layer unless they can be expressed as same-category structural operations.
- Treat `backends/default` as a bridge layer, not as the only place where generic linear algebra code should live.
