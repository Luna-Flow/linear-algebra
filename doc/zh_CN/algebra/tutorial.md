# algebra 教程

## 项目配置

如果你想直接使用抽象线性代数能力层，先把完整依赖装好：

```sh
moon add Luna-Flow/linear-algebra@0.4.3
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推荐的 `moon.pkg` 导入写法：

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

这样分工会很清楚：`@algebra` 负责线性代数结构 trait，`@la_arithmetic` 负责线性代数操作 trait，`@lf_alg` 负责共享上游代数抽象，`@lf_arith` 负责共享上游算术类型。

## 小案例：构造一个与后端无关的 Gram 步骤

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] gram_step(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "algebra tutorial uses linear-algebra traits with a real backend" {
  let features : @default.ImmutableDenseMatrix[Int] = @default.ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  let gram = gram_step(features)
  let (rows, cols) = @algebra.MatrixShape::shape(gram)

  inspect(rows, content="2")
  inspect(cols, content="2")
  inspect(gram.inner(), content="|10, 14|\n|14, 20|")
}
```

这个例子展示了，怎样只用本包拥有的线性代数结构 trait 来表达一个与后端无关的步骤：

1. 用 `MatMulMatrix` 说明算法确实需要矩阵式乘法。
2. 通过 `MatMulMatrix` 继承到的 `TransposeMatrix` 能力调用转置，而不是直接写死某个稠密后端 API。
3. 用 `MatrixShape` 读取结果形状，不依赖具体存储形式。
4. 最后拿真实的默认后端包装类型跑一遍，确认这些 trait 不只是抽象命名，而是能直接承载实际能力。

这样写出来的算法既保留了线代语义，也不会被某个具体后端绑定住。

## 建议流程

1. 当算法更关心“它需要什么数学结构”而不是“它跑在哪个后端上”时，优先从 `algebra` 开始。
2. 用 `AdditiveVector`、`MatrixShape`、`TransposeMatrix`、`MatMulMatrix` 这类 trait 表达结构需求。
3. 只有在算法确实需要某个可计算操作时，再补充更窄的 arithmetic 约束。

## 实践建议

- 优先选择能准确表达算法意义的最小结构约束。
- 内积、范数、求解等后端或算法特化行为，不要随便塞进核心结构层。
