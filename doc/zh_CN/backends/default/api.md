# `linear-algebra/backends/default`

本文档描述当前 `0.4.0` 仓库中 `Luna-Flow/linear-algebra/backends/default` 的公开 API。

## 职责

`backends/default` 提供本包拥有的包装类型，用来承载现有 `mutable` 与 `immut` 的稠密矩阵/向量实现。因为包装类型属于本包，所以本包可以为它们实现外层 `@algebra` trait。

## `DenseVector[T]`

```moonbit
pub struct DenseVector[T] {
  inner : @mutable.Vector[T]
}
```

默认可变稠密向量包装类型。

公开方法：

- `from_backend(@mutable.Vector[T]) -> DenseVector[T]`
- `from_array(Array[T]) -> DenseVector[T]`
- `make(Int, T) -> DenseVector[T]`
- `inner(Self[T]) -> @mutable.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

实现的 trait：

- `Add`、`Neg`、`Sub`、`Mul`，约束来自对应元素级操作。
- 任意 `T` 上的 `@algebra.VectorShape`
- 当 `T : Add + Neg` 时实现 `@algebra.AdditiveVector`
- 当 `T : Add + Neg + Mul` 时实现 `@algebra.VecMulVector`

## `DenseMatrix[T]`

```moonbit
pub struct DenseMatrix[T] {
  inner : @mutable.Matrix[T]
}
```

默认可变稠密矩阵包装类型。

公开方法：

- `from_backend(@mutable.Matrix[T]) -> DenseMatrix[T]`
- `from_2d_array(Array[Array[T]]) -> DenseMatrix[T]`
- `new(Int, Int, T) -> DenseMatrix[T]`
- `inner(Self[T]) -> @mutable.Matrix[T]`
- `row(Self[T]) -> Int`
- `col(Self[T]) -> Int`

实现的 trait：

- `Add`、`Neg`、`Sub`、`Mul`，约束来自对应元素级操作。
- 任意 `T` 上的 `@algebra.MatrixShape` 和 `@algebra.TransposeMatrix`
- 当 `T : Add + Neg` 时实现 `@algebra.AdditiveMatrix`
- 当 `T : Add + Neg + AddMonoid + Mul` 时实现 `@algebra.MatMulMatrix`

## `ImmutableDenseVector[T]`

```moonbit
pub struct ImmutableDenseVector[T] {
  inner : @immut.Vector[T]
}
```

默认不可变稠密向量包装类型。

公开方法：

- `from_backend(@immut.Vector[T]) -> ImmutableDenseVector[T]`
- `from_array(Array[T]) -> ImmutableDenseVector[T]`
- `make(Int, T) -> ImmutableDenseVector[T]`
- `inner(Self[T]) -> @immut.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

实现的 trait：

- `Add`、`Neg`、`Sub`、`Mul`，约束来自对应元素级操作。
- 任意 `T` 上的 `@algebra.VectorShape`
- 当 `T : Add + Neg` 时实现 `@algebra.AdditiveVector`
- 当 `T : Add + Neg + Mul` 时实现 `@algebra.VecMulVector`

## `ImmutableDenseMatrix[T]`

```moonbit
pub struct ImmutableDenseMatrix[T] {
  inner : @immut.Matrix[T]
}
```

默认不可变稠密矩阵包装类型。

公开方法：

- `from_backend(@immut.Matrix[T]) -> ImmutableDenseMatrix[T]`
- `from_2d_array(Array[Array[T]]) -> ImmutableDenseMatrix[T]`
- `new(Int, Int, T) -> ImmutableDenseMatrix[T]`
- `inner(Self[T]) -> @immut.Matrix[T]`
- `row(Self[T]) -> Int`
- `col(Self[T]) -> Int`

实现的 trait：

- `Add`、`Neg`、`Sub`、`Mul`，约束来自对应元素级操作。
- 任意 `T` 上的 `@algebra.MatrixShape` 和 `@algebra.TransposeMatrix`
- 当 `T : Add + Neg` 时实现 `@algebra.AdditiveMatrix`
- 当 `T : Add + Neg + Zero + Mul` 时实现 `@algebra.MatMulMatrix`

## 泛型辅助函数

- `shape_of[M : @algebra.MatrixShape](M) -> (Int, Int)`
- `matmul[M : @algebra.MatMulMatrix](M, M) -> M`
- `transpose[M : @algebra.TransposeMatrix](M) -> M`

## 边界

本包只为默认后端包装类型实现外层 `algebra` trait，不定义新的结构 trait。标量值乘积、范数、求解和分解仍属于后端方法或未来专门算法层，除非它们能表达为结构运算或同类型闭合运算。
