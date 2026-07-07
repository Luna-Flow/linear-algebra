# `linear-algebra/algebra`

本文档描述当前 `0.4.0` 仓库中 `Luna-Flow/linear-algebra/algebra` 的公开 API。

## 职责

`algebra` 拥有线性代数结构 traits。后端包为自己的具体数据类型实现这些 traits。这里的 traits 按最小能力拆分，避免泛型算法无意依赖 Hadamard 乘法、矩阵乘法或精确浮点域公理。

## 重导出的标量和代数 traits

- `Zero`、`One`、`Conjugate`
- `AddMonoid`、`AddGroup`
- `MulMonoid`、`MulGroup`
- `Semiring`、`Ring`、`Field`
- `Integral`、`Nat`、`Num`
- `NatHomomorphism`、`IntegralHomomorphism`
- `Abs`、`ApproxEq`、`Sqrt`

这些名称保持上游语义；`algebra` 不重新定义其代数律。

## Matrix Shape Traits

```moonbit
pub(open) trait MatrixShape {
  fn shape(Self) -> (Int, Int)
}

pub(open) trait VectorShape {
  fn length(Self) -> Int
}
```

`MatrixShape` 表示可观测二维形状的对象；`VectorShape` 表示可观测长度的向量式对象。它们不声明任何代数运算。

## `AdditiveVector`

```moonbit
pub(open) trait AdditiveVector: VectorShape + Add + Neg + Sub {}
```

表示具有加法线性结构的向量式对象。它不要求逐元素乘法、内积、范数或全局零元。

只有算法确实需要 Hadamard 乘法时才使用：

```moonbit
pub(open) trait VecMulVector: AdditiveVector + Mul {}
```

## `TransposeMatrix`

```moonbit
pub(open) trait TransposeMatrix: MatrixShape {
  fn transpose(Self) -> Self
}
```

表示具有可观测形状和同类型转置操作的矩阵式对象。它不要求矩阵乘法，因为动态矩形矩阵乘法只在运行时形状兼容时才有定义。该 trait 不要求稠密表示、连续存储、直接索引或可变操作。

只有算法确实需要对应运算时才使用更强 traits：

```moonbit
pub(open) trait AdditiveMatrix: TransposeMatrix + Add + Neg + Sub {}
pub(open) trait MatMulMatrix: AdditiveMatrix + Mul {}
```

## 更强的代数 traits

这些可选 trait 面向能合法提供 `luna-generic` 全局单位元的承载类型：

- `AdditiveVectorGroup: AdditiveVector + AddGroup`
- `VecMulSemiringVector: VecMulVector + Semiring`
- `VecMulRingVector: VecMulVector + Ring`
- `SquareMatrixSemiring: MatMulMatrix + Semiring`
- `SquareMatrixRing: MatMulMatrix + Ring`

动态矩形矩阵和运行时长度向量通常不应该实现这些强结构，除非它们的类型级表示确实固定了需要的形状和单位元。

## `FloatingScalarOps`

```moonbit
pub(open) trait FloatingScalarOps: Field + Num + ApproxEq {}
```

表示数值算法需要的浮点标量操作能力。继承的 `Field` 来自现有 Luna Flow 生态的操作依赖；这个 trait 不应被理解为 IEEE 浮点数满足精确域公理。当前实现给 `Float` 和 `Double`。

## 边界

不要在这里加入返回标量值的乘积、`norm` 或内积 trait，除非显式建模其标量映射。核心 `algebra` 包只放最小结构和同类型闭合运算。
