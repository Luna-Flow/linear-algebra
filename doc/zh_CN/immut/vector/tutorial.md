# immut/vector 教程

## 小案例：重建一份已发布的特征向量

```moonbit check
///|
fn rebuild_release_vector(
  base : @immut.Vector[Int],
  manual_override : Int,
) -> @immut.Matrix[Int] {
  let corrected = base.set(1, manual_override)
  let expanded = @immut.lin_comb(
    2,
    corrected,
    1,
    @immut.Vector::from_array([1, 0, 1]),
  )
  expanded.tensor_product(@immut.Vector::from_array([1, 0]))
}

///|
test "immut vector tutorial case" {
  let base = @immut.Vector::from_array([2, 4, 6])
  let result = rebuild_release_vector(base, 9)

  inspect(base, content="|2, 4, 6|")
  inspect(result, content="|5, 0|\n|18, 0|\n|13, 0|")
}
```

这个案例可以看成一个很小的发布前处理流程：

1. 从一份已经发布的基础向量开始。
2. 用 `set` 对一个位置做显式修正。
3. 用 `lin_comb` 组合出新的加权结果。
4. 用 `tensor_product` 把它扩展成矩阵形态的输出。

整个过程不会修改原始向量，所以旧值仍然可以安全复用。

## 建议流程

1. 使用 `Vector::from_array`、`Vector::make` 或 `Vector::makei` 创建向量。
2. 需要新向量时，使用 `set`、`map`、`left_scale` 和 `right_scale`。
3. 需要矩阵相关转换时，使用 `tensor_product`、`scaled_matrix`、`to_row_matrix` 和 `to_col_matrix`。

## 实践建议

- 当下游代码需要明确的值语义时，选择 `@immut.Vector`。
- 当工作负载包含大量原地更新，或者需要公开的 `dot()` 辅助函数时，选择 `@mutable.Vector`。
- 如果你希望每一次结构变化都返回一个新值，并把旧值安全地继续传递下去，优先选择这条不可变路径。
