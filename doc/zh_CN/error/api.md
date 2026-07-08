# `linear-algebra/error`

本文档描述当前 `0.4.1` 仓库中 `Luna-Flow/linear-algebra/error` 的公开 API。

## 职责

`error` 提供带检查线性代数 API 共用的结构化错误类型。调用者可以根据错误种类区分形状错误、非法输入域、奇异矩阵、不支持的后端和底层算术错误，而不需要解析 abort 文本。

## `LinearAlgebraErrorKind`

```moonbit
pub enum LinearAlgebraErrorKind {
  DimensionMismatch
  IndexOutOfBounds
  NegativeDimension
  InvalidLength
  RaggedRows
  NonSquareMatrix
  NegativeExponent
  EmptyMatrix
  SingularMatrix
  NonConvergence
  UnsupportedBackend
  ArithmeticFailure(@arithmetic.ArithmeticError)
} derive(Eq)
```

该枚举表示失败类型。`ArithmeticFailure` 会携带上游
`Luna-Flow/arithmetic.ArithmeticError`。

## `LinearAlgebraError`

```moonbit
pub struct LinearAlgebraError {
  kind : LinearAlgebraErrorKind
  message : String
} derive(Eq)
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
- `is_arithmetic_failure()`

这些方法用于处理带检查 API 的常见错误，不需要调用者拆开错误值。

## 使用示例

```moonbit
match matrix.inverse() {
  Ok(inv) => inv
  Err(err) => {
    if err.is_singular_matrix() {
      abort("matrix is singular")
    }
    abort("matrix inverse failed")
  }
}
```

## 边界

本包只定义错误值，不实现矩阵算法、数值恢复策略、日志或格式化策略。
