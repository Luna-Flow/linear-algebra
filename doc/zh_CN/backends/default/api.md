# `linear-algebra/backends/default`

本页记录当前 `0.4.2` 仓库中 `Luna-Flow/linear-algebra/backends/default` 的公开 API 基线。

## 职责

`backends/default` 提供本包拥有的包装类型，用来承载现有 `mutable` 与 `immut` 的稠密矩阵/向量实现。因为这些包装类型属于本包，所以这里可以为它们实现外层 `@algebra` trait。

## `DenseVector[T]`

```moonbit check
///|
test "DenseVector wraps a mutable vector backend" {
  let vector : @default.DenseVector[Int] = @default.DenseVector::from_array([
    1, 2, 3,
  ])
  inspect(vector.length(), content="3")
  inspect(vector[1], content="2")
}
```

默认可变稠密向量后端的自有包装类型。

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

```moonbit check
///|
test "DenseMatrix wraps a mutable matrix backend" {
  let matrix : @default.DenseMatrix[Int] = @default.DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

默认可变稠密矩阵后端的自有包装类型。

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

```moonbit check
///|
test "ImmutableDenseVector wraps an immutable vector backend" {
  let vector : @default.ImmutableDenseVector[Int] = @default.ImmutableDenseVector::from_array([
      1, 2, 3,
    ],
  )
  inspect(vector.length(), content="3")
  inspect(vector[2], content="3")
}
```

默认不可变稠密向量后端的自有包装类型。

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

```moonbit check
///|
test "ImmutableDenseMatrix wraps an immutable matrix backend" {
  let matrix : @default.ImmutableDenseMatrix[Int] = @default.ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

默认不可变稠密矩阵后端的自有包装类型。

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
