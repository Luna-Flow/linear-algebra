# error Tutorial

Use `linear-algebra/error` when calling checked linear-algebra APIs that return
`Result[..., @error.LinearAlgebraError]`.

```moonbit
match matrix.inverse() {
  Ok(inv) => inv
  Err(err) => {
    if err.is_non_square_matrix() {
      abort("inverse requires a square matrix")
    }
    if err.is_singular_matrix() {
      abort("matrix is singular")
    }
    abort(err.message)
  }
}
```

Prefer predicates such as `is_dimension_mismatch`,
`is_negative_exponent`, and `is_empty_matrix` when the caller can recover from
specific failures. Use `message` for diagnostics, logs, or final fallback
errors; do not parse it to decide control flow.

Keep `ArithmeticFailure` as a boundary for scalar arithmetic errors propagated
from lower-level arithmetic packages. Handle it separately only when the caller
can make a meaningful numeric recovery decision.
