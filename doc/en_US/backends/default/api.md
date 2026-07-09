# `linear-algebra/backends/default`

API baseline for `Luna-Flow/linear-algebra/backends/default` in the current
`0.4.2` repository state.

## Purpose

`backends/default` provides owned wrapper types around the existing dense
`mutable` and `immut` implementations. Because these wrappers are owned by the
default backend package, the package can implement the public `@algebra` traits
for them without violating MoonBit's foreign trait / foreign type rule.

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

Owned wrapper for the default mutable dense vector backend.

### Constructors And Accessors

- `DenseVector::from_backend(inner : @mutable.Vector[T]) -> DenseVector[T]`
  wraps an existing mutable vector.
- `DenseVector::from_array(data : Array[T]) -> DenseVector[T]`
  builds a mutable dense vector from an array.
- `DenseVector::make(length : Int, value : T) -> DenseVector[T]`
  builds a vector filled with `value`.
- `DenseVector::inner(self) -> @mutable.Vector[T]`
  returns the wrapped mutable vector.
- `DenseVector::length(self) -> Int`
  returns vector length.
- `DenseVector::op_get(self, index : Int) -> T`
  supports read indexing.

### Trait Implementations

- `Add`, `Neg`, `Sub`, and `Mul` with the matching element-level operation
  constraints.
- `@algebra.VectorShape` for all `T`
- `@algebra.AdditiveVector` when `T : Add + Neg`
- `@algebra.VecMulVector` when `T : Add + Neg + Mul`

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

Owned wrapper for the default mutable dense matrix backend.

### Constructors And Accessors

- `DenseMatrix::from_backend(inner : @mutable.Matrix[T]) -> DenseMatrix[T]`
  wraps an existing mutable matrix.
- `DenseMatrix::from_2d_array(data : Array[Array[T]]) -> DenseMatrix[T]`
  builds a matrix from row-major nested arrays.
- `DenseMatrix::new(row : Int, col : Int, value : T) -> DenseMatrix[T]`
  builds a matrix filled with `value`.
- `DenseMatrix::inner(self) -> @mutable.Matrix[T]`
  returns the wrapped mutable matrix.
- `DenseMatrix::row(self) -> Int`
  returns row count.
- `DenseMatrix::col(self) -> Int`
  returns column count.

### Trait Implementations

- `Add`, `Neg`, `Sub`, and `Mul` with the matching element-level operation
  constraints.
- `@algebra.MatrixShape` and `@algebra.TransposeMatrix` for all `T`
- `@algebra.AdditiveMatrix` when `T : Add + Neg`
- `@algebra.MatMulMatrix` when `T : Add + Neg + AddMonoid + Mul`

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

Owned wrapper for the default immutable dense vector backend.

### Constructors And Accessors

- `ImmutableDenseVector::from_backend(inner : @immut.Vector[T])`
- `ImmutableDenseVector::from_array(data : Array[T])`
- `ImmutableDenseVector::make(length : Int, value : T)`
- `ImmutableDenseVector::inner(self) -> @immut.Vector[T]`
- `ImmutableDenseVector::length(self) -> Int`
- `ImmutableDenseVector::op_get(self, index : Int) -> T`

### Trait Implementations

- `Add`, `Neg`, `Sub`, and `Mul` with the matching element-level operation
  constraints.
- `@algebra.VectorShape` for all `T`
- `@algebra.AdditiveVector` when `T : Add + Neg`
- `@algebra.VecMulVector` when `T : Add + Neg + Mul`

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

Owned wrapper for the default immutable dense matrix backend.

### Constructors And Accessors

- `ImmutableDenseMatrix::from_backend(inner : @immut.Matrix[T])`
- `ImmutableDenseMatrix::from_2d_array(data : Array[Array[T]])`
- `ImmutableDenseMatrix::new(row : Int, col : Int, value : T)`
- `ImmutableDenseMatrix::inner(self) -> @immut.Matrix[T]`
- `ImmutableDenseMatrix::row(self) -> Int`
- `ImmutableDenseMatrix::col(self) -> Int`

### Trait Implementations

- `Add`, `Neg`, `Sub`, and `Mul` with the matching element-level operation
  constraints.
- `@algebra.MatrixShape` and `@algebra.TransposeMatrix` for all `T`
- `@algebra.AdditiveMatrix` when `T : Add + Neg`
- `@algebra.MatMulMatrix` when `T : Add + Neg + Zero + Mul`

## Generic Helper Functions

- `shape_of[M : @algebra.MatrixShape](matrix : M) -> (Int, Int)`
  returns an object's shape.
- `matmul[M : @algebra.MatMulMatrix](left : M, right : M) -> M`
  dispatches matrix multiplication through the explicit multiplication
  capability.
- `transpose[M : @algebra.TransposeMatrix](matrix : M) -> M`
  dispatches closed transpose through the algebra trait.

## Boundary

This package implements outer `algebra` traits for the default backend wrapper
types. It does not define new structure traits. Scalar-valued products, norms,
solves, and decompositions remain backend methods or future dedicated
algorithm-layer APIs unless they can be represented as structure traits or
closed operations.
