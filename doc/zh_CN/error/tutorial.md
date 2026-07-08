# error 教程

调用返回 `Result[..., @error.LinearAlgebraError]` 的带检查线性代数 API 时，
使用 `linear-algebra/error`。

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

当调用者可以从某类失败中恢复时，优先使用 `is_dimension_mismatch`、
`is_negative_exponent`、`is_empty_matrix` 等判断方法。`message` 适合用于诊断、
日志或最后的兜底错误，不要解析它来决定控制流。

把 `ArithmeticFailure` 当作下层算术包传播出来的标量算术错误边界。只有当调用者能做出有意义的数值恢复决策时，才单独处理它。
