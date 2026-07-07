# `linear-algebra/backends/default`

This page documents the public API exported by
`Luna-Flow/linear-algebra/backends/default` in the current `0.4.0` repository
state.

## Purpose

`backends/default` provides owned wrapper types around the existing dense
`mutable` and `immut` implementations. Because these wrappers are owned by the
default backend package, the package can implement the public `@algebra` traits
for them without violating MoonBit's foreign trait / foreign type rule.

## `DenseVector[T]`

```moonbit
pub struct DenseVector[T] {
  inner : @mutable.Vector[T]
}
```

Default mutable dense vector wrapper.

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

```moonbit
pub struct DenseMatrix[T] {
  inner : @mutable.Matrix[T]
}
```

Default mutable dense matrix wrapper.

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

```moonbit
pub struct ImmutableDenseVector[T] {
  inner : @immut.Vector[T]
}
```

Default immutable dense vector wrapper.

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

```moonbit
pub struct ImmutableDenseMatrix[T] {
  inner : @immut.Matrix[T]
}
```

Default immutable dense matrix wrapper.

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

This package implements outer `algebra` traits for default backend wrapper
types. It does not define new structure traits. Scalar-valued products, norms,
solves, and decompositions remain backend methods or future dedicated
algorithm-layer APIs unless they can be represented as structure or closed
operations.
