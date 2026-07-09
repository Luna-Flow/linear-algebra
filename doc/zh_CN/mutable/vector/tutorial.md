# mutable/vector 教程

## 小案例：用工作副本给候选项打分

```moonbit check
///|
fn score_candidate(
  raw_features : @mutable.Vector[Int],
  weights : @mutable.Vector[Int],
) -> Int {
  let working = raw_features.copy()
  working.map_inplace(fn(x) { x + 1 })
  working.left_scale_inplace(2)
  working.dot(weights)
}

///|
test "mutable vector tutorial case" {
  let raw = @mutable.Vector::from_array([1, 2, 3])
  let weights = @mutable.Vector::from_array([3, 4, 5])
  let score = score_candidate(raw, weights)

  inspect(raw, content="|1, 2, 3|")
  inspect(score, content="76")
}
```

这是一个很典型的可变向量工作流：

1. 先保留调用方传进来的原始向量。
2. 用 `copy()` 拿一个工作副本。
3. 在副本上用 `map_inplace` 和 `left_scale_inplace` 做归一化与放大。
4. 最后再用 `dot` 算出分数。

## 建议流程

1. 使用 `Vector::from_array`、`Vector::make` 或 `Vector::makei` 创建向量。
2. 使用 `v[i]` 和 `v[i] = x` 直接访问或更新元素。
3. 确实需要修改原值时，使用 `map_inplace`、`left_scale_inplace` 和 `right_scale_inplace`。
4. 需要做归约、线性组合或矩阵转换时，使用 `dot`、`lin_comb`、`tensor_product`、`to_row_matrix` 和 `to_col_matrix`。

## 实践建议

- 需要保留原向量时，使用那些不带 `inplace` 后缀的辅助函数。
- 如果后续还要继续修改同一个值，先调用 `copy()` 再进行原地操作。
- 当向量开始参与更大的数值流程时，可以继续往 `dot`、`lin_comb` 和矩阵转换辅助函数走。
