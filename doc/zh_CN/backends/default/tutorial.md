# backends/default 教程

当需要仓库参考 稠密 实现时，使用默认后端 wrapper。

```moonbit
let matrix : DenseMatrix[Int] = DenseMatrix::from_2d_array([
  [1, 2],
  [3, 4],
])
let shape = shape_of(matrix)
```

后端无关代码应依赖 capability 辅助函数s：

```moonbit
fn[M : @algebra.MatrixShape](matrix : M) -> (Int, Int) {
  shape_of(matrix)
}
```

如果某个后端有自己的标量值乘积、范数、求解或分解策略，除非它能表达为同类型结构运算，否则应保留在后端或专门算法层。
