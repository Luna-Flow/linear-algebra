# mutable/matrix 教程

## 建议流程

1. 使用 `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new` 或 `Matrix::from_array` 构造矩阵。
2. 用 `get` 和 `set` 直接访问元素；需要反复处理某行或某列时，使用 `row_view` / `col_view`。
3. 当输入可能在运行时失败时，使用带检查的 `trace`、`determinant`、`inverse`、`mul_vec` 和 `pow`。

## 实践建议

- 需要连接到底层矩阵的转置视图时使用 `to_transpose()`；需要物化矩阵时使用 `transpose()`。
- 只有在已经保证形状、非空和非奇异等前置条件时，才使用 `unchecked_*`。
