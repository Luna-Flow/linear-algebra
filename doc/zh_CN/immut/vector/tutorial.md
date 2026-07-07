# immut/vector 教程

## 建议流程

1. 使用 `Vector::from_array`、`Vector::make` 或 `Vector::makei` 创建向量。
2. 需要新向量时，使用 `set`、`map`、`left_scale` 和 `right_scale`。
3. 需要代数转换时，使用 `dot`、`tensor_product`、`to_row_matrix` 和 `to_col_matrix`。

## 实践建议

- 当下游代码需要明确的值语义时，选择 `@immut.Vector`。
- 当工作负载包含大量原地更新时，选择 `@mutable.Vector`。
