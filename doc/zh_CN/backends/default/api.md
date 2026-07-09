# `linear-algebra/backends/default`

本页记录当前 `0.4.6` 仓库中 `Luna-Flow/linear-algebra/backends/default`
的公开 API 基线。

## 职责

`backends/default` 为现有的稠密 `mutable` 与 `immut` 实现提供本包拥有的包装类型。
因为这些包装类型属于默认后端包，所以这里可以为它们实现公开的 `@algebra`
trait，而不会违反 MoonBit 的 foreign trait / foreign type 规则。

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

### 构造与访问

- `DenseVector::from_backend(inner : @mutable.Vector[T]) -> DenseVector[T]`
  包装一个已有的可变向量。
- `DenseVector::from_array(data : Array[T]) -> DenseVector[T]`
  从数组构造一个可变稠密向量。
- `DenseVector::make(length : Int, value : T) -> DenseVector[T]`
  构造一个所有元素都为 `value` 的向量。
- `DenseVector::inner(self) -> @mutable.Vector[T]`
  返回内部包装的可变向量。
- `DenseVector::length(self) -> Int`
  返回向量长度。
- `DenseVector::op_get(self, index : Int) -> T`
  支持只读索引访问。

### 后端方法

- `DenseVector::scale(self, scalar : T) -> DenseVector[T]`
  对向量做逐元素缩放并返回新的默认后端值。
- `DenseVector::dot(self, other : DenseVector[T]) -> T`
  计算标量点积。
- `DenseVector::axpy(self, alpha : T, other : DenseVector[T]) -> DenseVector[T]`
  计算 BLAS 风格的 `alpha * self + other`。

### trait 实现

- `Add`、`Neg`、`Sub` 和 `Mul`，并带有对应的元素级操作约束。
- 任意 `T` 上的 `@algebra.VectorShape`
- 当 `T : Add + Neg` 时的 `@algebra.AdditiveVector`
- 当 `T : Add + Neg + Mul` 时的 `@algebra.VecMulVector`

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

### 构造与访问

- `DenseMatrix::from_backend(inner : @mutable.Matrix[T]) -> DenseMatrix[T]`
  包装一个已有的可变矩阵。
- `DenseMatrix::from_2d_array(data : Array[Array[T]]) -> DenseMatrix[T]`
  从按行组织的二维数组构造矩阵。
- `DenseMatrix::new(row : Int, col : Int, value : T) -> DenseMatrix[T]`
  构造一个所有元素都为 `value` 的矩阵。
- `DenseMatrix::inner(self) -> @mutable.Matrix[T]`
  返回内部包装的可变矩阵。
- `DenseMatrix::row(self) -> Int`
  返回行数。
- `DenseMatrix::col(self) -> Int`
  返回列数。

### 后端方法

- `DenseMatrix::matvec(self, vector : DenseVector[T]) -> DenseVector[T]`
  计算矩阵与默认后端稠密向量的乘积，并返回新的稠密向量包装类型。

### trait 实现

- `Add`、`Neg`、`Sub` 和 `Mul`，并带有对应的元素级操作约束。
- 任意 `T` 上的 `@algebra.MatrixShape` 和 `@algebra.TransposeMatrix`
- 当 `T : Add + Neg` 时的 `@algebra.AdditiveMatrix`
- 当 `T : Add + Neg + AddMonoid + Mul` 时的 `@algebra.MatMulMatrix`

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

### 构造与访问

- `ImmutableDenseVector::from_backend(inner : @immut.Vector[T])`
- `ImmutableDenseVector::from_array(data : Array[T])`
- `ImmutableDenseVector::make(length : Int, value : T)`
- `ImmutableDenseVector::inner(self) -> @immut.Vector[T]`
- `ImmutableDenseVector::length(self) -> Int`
- `ImmutableDenseVector::op_get(self, index : Int) -> T`

### 后端方法

- `ImmutableDenseVector::scale(self, scalar : T) -> ImmutableDenseVector[T]`
- `ImmutableDenseVector::dot(self, other : ImmutableDenseVector[T]) -> T`
- `ImmutableDenseVector::axpy(self, alpha : T, other : ImmutableDenseVector[T]) -> ImmutableDenseVector[T]`

### trait 实现

- `Add`、`Neg`、`Sub` 和 `Mul`，并带有对应的元素级操作约束。
- 任意 `T` 上的 `@algebra.VectorShape`
- 当 `T : Add + Neg` 时的 `@algebra.AdditiveVector`
- 当 `T : Add + Neg + Mul` 时的 `@algebra.VecMulVector`

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

### 构造与访问

- `ImmutableDenseMatrix::from_backend(inner : @immut.Matrix[T])`
- `ImmutableDenseMatrix::from_2d_array(data : Array[Array[T]])`
- `ImmutableDenseMatrix::new(row : Int, col : Int, value : T)`
- `ImmutableDenseMatrix::inner(self) -> @immut.Matrix[T]`
- `ImmutableDenseMatrix::row(self) -> Int`
- `ImmutableDenseMatrix::col(self) -> Int`

### 后端方法

- `ImmutableDenseMatrix::matvec(self, vector : ImmutableDenseVector[T]) -> ImmutableDenseVector[T]`
  计算矩阵与不可变稠密向量的乘积，并返回新的不可变稠密向量包装类型。

### trait 实现

- `Add`、`Neg`、`Sub` 和 `Mul`，并带有对应的元素级操作约束。
- 任意 `T` 上的 `@algebra.MatrixShape` 和 `@algebra.TransposeMatrix`
- 当 `T : Add + Neg` 时的 `@algebra.AdditiveMatrix`
- 当 `T : Add + Neg + Zero + Mul` 时的 `@algebra.MatMulMatrix`

## 泛型辅助函数

- `shape_of[M : @algebra.MatrixShape](matrix : M) -> (Int, Int)`
  返回对象的形状。
- `matmul[M : @algebra.MatMulMatrix](left : M, right : M) -> M`
  通过显式的乘法能力分发矩阵乘法。
- `transpose[M : @algebra.TransposeMatrix](matrix : M) -> M`
  通过 algebra trait 分发闭合转置。

## 边界

本包只为默认后端包装类型实现外层 `algebra` trait。它不定义新的结构 trait。
这里记录的标量点积与矩阵-向量交互仍然属于后端方法，而不是新的 `@algebra`
trait；范数、求解和分解也仍然属于后端方法，或未来专门的算法层 API。只有在它们
能够表示成结构 trait 或同类型闭合运算时，才应提升到这一层。
