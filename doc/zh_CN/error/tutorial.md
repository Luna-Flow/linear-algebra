# error 教程

## 小案例：给失败的求逆请求分类

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

这个例子模拟的是：调用方希望根据不同失败原因采取不同恢复策略。

1. 调用一个返回 `Result[..., LinearAlgebraError]` 的带检查 API。
2. 通过错误谓词分支，而不是去猜测错误消息字符串。
3. 只有在不属于已知恢复路径时，才退回到通用诊断消息。

这样即使人类可读的错误文案以后调整，控制流本身仍然稳定。

## 建议流程

1. 面向用户输入或运行时数据的代码，优先使用带检查矩阵 API。
2. 尽量在真正需要恢复决策的地方就地匹配 `Ok` / `Err`。
3. 用 `is_dimension_mismatch`、`is_negative_exponent`、`is_empty_matrix`、`is_non_square_matrix` 等方法驱动控制流。

## 实践建议

- `message` 适合做诊断、日志和兜底提示，不适合做控制流解析。
- 把 `ArithmeticFailure` 当作下层算术包传播出来的边界错误。
- 只有在外围逻辑已经保证前置条件时，才退回 `unchecked_*`。
