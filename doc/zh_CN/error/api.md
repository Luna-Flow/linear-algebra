# `linear-algebra/error`

本页记录当前 `0.4.4` 仓库中 `Luna-Flow/linear-algebra/error` 的公开 API 基线。

## 职责

`error` 提供带检查线性代数 API 共用的结构化错误类型。调用者可以根据错误种类区分形状错误、非法输入域、奇异矩阵、不支持的后端、已经预留但暂未接线的后端，以及底层算术错误，而不需要解析 abort 文本。

## `LinearAlgebraErrorKind`

```moonbit check
///|
test "LinearAlgebraErrorKind distinguishes failure categories" {
  let kind = @la_error.LinearAlgebraError::singular_matrix("matrix is singular").kind
  let label = match kind {
    @la_error.LinearAlgebraErrorKind::SingularMatrix => "singular"
    _ => "other"
  }
  inspect(label, content="singular")
}
```

该枚举用来表示失败类型。`ArithmeticFailure` 会携带上游
`Luna-Flow/arithmetic.ArithmeticError`。

## `LinearAlgebraError`

```moonbit check
///|
test "LinearAlgebraError stores kind and message" {
  let err = @la_error.LinearAlgebraError::singular_matrix("matrix is singular")
  inspect(err.is_singular_matrix(), content="true")
  inspect(err.message, content="matrix is singular")
}
```

该结构同时保存机器可判断的错误种类和给人阅读的消息。

## 构造函数

- `LinearAlgebraError::dimension_mismatch(message)`
- `LinearAlgebraError::index_out_of_bounds(message)`
- `LinearAlgebraError::negative_dimension(message)`
- `LinearAlgebraError::invalid_length(message)`
- `LinearAlgebraError::ragged_rows(message)`
- `LinearAlgebraError::non_square_matrix(message)`
- `LinearAlgebraError::negative_exponent(message)`
- `LinearAlgebraError::empty_matrix(message)`
- `LinearAlgebraError::singular_matrix(message)`
- `LinearAlgebraError::non_convergence(message)`
- `LinearAlgebraError::unsupported_backend(message)`
- `LinearAlgebraError::backend_not_impl(message)`
- `LinearAlgebraError::arithmetic_failure(error)`

## 判断方法

- `is_dimension_mismatch()`
- `is_index_out_of_bounds()`
- `is_negative_dimension()`
- `is_invalid_length()`
- `is_ragged_rows()`
- `is_non_square_matrix()`
- `is_negative_exponent()`
- `is_empty_matrix()`
- `is_singular_matrix()`
- `is_non_convergence()`
- `is_unsupported_backend()`
- `is_backend_not_impl()`
- `is_arithmetic_failure()`

这些方法用于处理带检查 API 的常见错误，不需要调用者拆开错误值。

`unsupported_backend` 和 `backend_not_impl` 是两个不同层次的信号。
前者表示某个后端不在当前支持契约内；后者表示 API 已经预留了后端选择项，
例如 `BlasBackend`，但当前仓库版本还没有把它真正接到实现上。

## 使用示例

```moonbit check
///|
test "checked callers can branch on structured linear-algebra errors" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let status = match matrix.inverse() {
    Ok(_) => "ok"
    Err(err) => if err.is_singular_matrix() { "singular" } else { "other" }
  }
  inspect(status, content="singular")
}
```

## 边界

本包只定义错误值，不实现矩阵算法、数值恢复策略、日志或格式化策略。
