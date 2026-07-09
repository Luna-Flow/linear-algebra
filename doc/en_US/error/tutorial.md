# error Tutorial

## Small Case: Classify A Failed Inverse Request

```moonbit check
///|
fn classify_inverse_request(matrix : @mutable.Matrix[Double]) -> String {
  match matrix.inverse() {
    Ok(_) => "ok"
    Err(err) =>
      if err.is_non_square_matrix() {
        "non-square"
      } else if err.is_singular_matrix() {
        "singular"
      } else {
        err.message
      }
  }
}

///|
test "inverse handling branches on error kind" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  inspect(classify_inverse_request(matrix), content="non-square")
}
```

This case models a caller that wants to recover differently from different
matrix failures:

1. Call a checked API that returns `Result[..., LinearAlgebraError]`.
2. Branch on the error predicates instead of guessing from a message string.
3. Return a fallback diagnostic only when the failure does not match a known recovery path.

That keeps control flow stable even if the human-readable message changes.

## Suggested Flow

1. Use checked matrix APIs in user-facing or data-dependent code.
2. Match on `Ok` / `Err` as close as possible to the place where recovery decisions are made.
3. Use `is_dimension_mismatch`, `is_negative_exponent`, `is_empty_matrix`, `is_non_square_matrix`, and related predicates to drive control flow.

## Practical Guidance

- Use `message` for diagnostics, logs, or a final fallback error, not for control-flow parsing.
- Treat `ArithmeticFailure` as a boundary for scalar arithmetic errors coming from lower-level arithmetic packages.
- Fall back to `unchecked_*` only when surrounding code has already guaranteed the required preconditions.
