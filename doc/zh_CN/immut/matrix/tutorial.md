# immut/matrix 教程

## 小案例：修补并重新导出一份布局矩阵

```moonbit check
///|
fn rebuild_layout(matrix : @immut.Matrix[Int]) -> @immut.Matrix[Int] {
  matrix.set(0, 1, 9).swap_rows(0, 1).transpose()
}

///|
test "immut matrix tutorial case" {
  let original = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let exported = rebuild_layout(original)

  inspect(original, content="|1, 2|\n|3, 4|")
  inspect(exported, content="|3, 1|\n|4, 9|")
  inspect(exported.determinant().unwrap(), content="23")
}
```

这个案例展示的是值语义矩阵的典型处理流程：

1. 用 `set` 修补一个单元格。
2. 用 `swap_rows` 调整展示顺序。
3. 用 `transpose` 生成最终导出的矩阵。
4. 在最终值上运行 `determinant()` 这类带检查数值 API。

因为每一步都会返回新矩阵，所以最初那份布局不会被覆盖。

## 建议流程

1. 使用 `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new` 或 `Matrix::from_array` 构造矩阵。
2. 把 `set`、`swap_rows`、`swap_cols`、`map` 和 `transpose` 当作返回新矩阵的操作。
3. 当形状或输入域可能来自运行时数据时，优先使用带检查的 `matmul`、`trace`、`determinant` 和 `pow`。

## 实践建议

- 只有在外层逻辑已经保证前置条件时，才使用 `unchecked_*`。
- 当惰性的函数式矩阵表示比物化存储更合适时，使用 `MatrixFn`。
- 当更新需要保持显式、而旧矩阵值还要在后续步骤中保留时，优先采用不可变矩阵路径。
