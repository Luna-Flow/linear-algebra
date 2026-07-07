# backends/default Tutorial

Use the default backend wrappers when you want the repository's reference dense
implementation.

```moonbit
let matrix : DenseMatrix[Int] = DenseMatrix::from_2d_array([
  [1, 2],
  [3, 4],
])
let shape = shape_of(matrix)
```

Use the capability helpers for backend-independent code:

```moonbit
fn[M : @algebra.MatrixShape](matrix : M) -> (Int, Int) {
  shape_of(matrix)
}
```

If a backend has its own scalar-valued product, norm, solve strategy, or decomposition,
keep that behavior in the backend or a dedicated algorithm layer unless it can
be expressed as a same-category structural operation.
