# backends/default 教程

## 小案例：使用默认稠密后端，但不把算法写死在具体实现上

```moonbit check
///|
fn[M : @algebra.MatrixShape] matrix_shape(matrix : M) -> (Int, Int) {
  @default.shape_of(matrix)
}

///|
test "shape_of dispatches through MatrixShape" {
  let matrix : @default.DenseMatrix[Int] = @default.DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  let (rows, cols) = matrix_shape(matrix)
  inspect(rows, content="2")
  inspect(cols, content="2")
}
```

这个例子体现了默认后端层的正确用法：

1. 用 `DenseMatrix` 构造一个可直接上手的具体稠密矩阵。
2. 把它传给一个只要求 `MatrixShape` 能力的辅助函数。
3. 通过 `@default.shape_of` 把具体包装类型和公开 trait 视图连起来。

这样既给用户提供了开箱即用的默认后端，也保留了后续把算法迁移到其他后端的空间。

## 建议流程

1. 当你想马上用仓库自带的参考实现时，从 `DenseMatrix`、`DenseVector`、`ImmutableDenseMatrix`、`ImmutableDenseVector` 开始。
2. 当你在写可复用算法时，优先让函数依赖 `MatrixShape` 这类 `algebra` trait。
3. 把具体存储和具体后端的选择，尽量留在最外层边界。

## 实践建议

- 当你需要一个公开、直接、稠密的默认实现时，使用这些 default backend 包装类型。
- 标量值乘积、范数、求解策略、分解策略这类后端特化行为，除非能表达成同类结构操作，否则应留在后端层或专门算法层。
- 把 `backends/default` 视作桥接层，而不是所有泛型线性代数代码的归宿。
