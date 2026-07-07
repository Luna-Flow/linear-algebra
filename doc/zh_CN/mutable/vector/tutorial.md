# mutable/vector 教程

## 建议流程

1. 使用 `Vector::from_array`、`Vector::make` 或 `Vector::makei` 创建向量。
2. 使用 `v[i]` 和 `v[i] = x` 直接访问或更新元素。
3. 确实需要修改原值时，使用 `map_inplace`、`left_scale_inplace` 和 `right_scale_inplace`。

## 实践建议

- 需要保留原向量时，使用非 `inplace` 辅助函数。
- 需要代数转换时，使用 `dot`、`tensor_product`、`to_row_matrix` 和 `to_col_matrix`。
