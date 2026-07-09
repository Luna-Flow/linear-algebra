# mutable/matrix 教程

## 小案例：校准一份稠密数值矩阵

```moonbit check
///|
fn calibrate_dense_matrix(matrix : @mutable.Matrix[Double]) -> Double {
  let first_row = matrix.row_view(0)
  first_row[1] = 9.0
  let first_col = matrix.col_view(0)
  first_col[1] = 5.0
  matrix.determinant().unwrap()
}

///|
test "mutable matrix tutorial case" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let det = calibrate_dense_matrix(matrix)

  inspect(matrix, content="|1, 9|\n|5, 4|")
  inspect(det, content="-41")
  inspect(matrix.inverse() is Ok(_), content="true")
}
```

这类模式很适合把矩阵当作一个活的工作缓冲区：

1. 先构造好具体矩阵。
2. 用 `row_view` 和 `col_view` 直接修改热点区域。
3. 编辑完成后，再调用 `determinant()`、`inverse()` 这样的带检查数值 API。

当矩阵是执行对象而不是历史值时，这条路径通常最直接。

## 建议流程

1. 使用 `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new` 或 `Matrix::from_array` 构造矩阵。
2. 用 `get` 和 `set` 直接访问元素；需要反复处理某行或某列时，使用 `row_view` / `col_view`。
3. 当输入可能在运行时失败时，使用带检查的 `trace`、`determinant`、`inverse`、`mul_vec` 和 `pow`。

## 实践建议

- 需要连接到底层矩阵的转置视图时使用 `to_transpose()`；需要物化矩阵时使用 `transpose()`。
- 只有在已经保证形状、非空和非奇异等前置条件时，才使用 `unchecked_*`。
- 如果某一行或某一列会被重复读取或更新，优先使用行/列视图而不是反复手写索引。
