# immut/matrix 教程

## 建议流程

1. 使用 `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new` 或 `Matrix::from_array` 构造矩阵。
2. 把 `set`、`swap_rows`、`swap_cols`、`map` 和 `transpose` 当作返回新矩阵的操作。
3. 当形状或输入域可能来自运行时数据时，优先使用带检查的 `matmul`、`trace`、`determinant` 和 `pow`。

## 实践建议

- 只有在外层逻辑已经保证前置条件时，才使用 `unchecked_*`。
- 当惰性的函数式矩阵表示比物化存储更合适时，使用 `MatrixFn`。
