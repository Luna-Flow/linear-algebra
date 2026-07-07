# `linear-algebra/algebra`

This page documents the public API exported by `Luna-Flow/linear-algebra/algebra`
in the current `0.4.1` repository state.

## Purpose

`algebra` owns the linear-algebra structure traits. Backend packages implement
these traits for their own concrete data types. The traits in this package are
split by the minimum capability they require so generic algorithms do not
accidentally depend on Hadamard multiplication, matrix multiplication, or exact
floating-point field laws.

## Re-exported Scalar And Algebra Traits

The package re-exports existing Luna Flow scalar/algebra traits so linear
algebra packages can depend on one import surface:

- `Zero`, `One`, `Conjugate`
- `AddMonoid`, `AddGroup`
- `MulMonoid`, `MulGroup`
- `Semiring`, `Ring`, `Field`
- `Integral`, `Nat`, `Num`
- `NatHomomorphism`, `IntegralHomomorphism`
- `Abs`, `ApproxEq`, `Sqrt`

These names keep their upstream semantics. `algebra` does not redefine their
laws.

## Matrix Shape Traits

```moonbit
pub(open) trait MatrixShape {
  fn shape(Self) -> (Int, Int)
}

pub(open) trait VectorShape {
  fn length(Self) -> Int
}
```

`MatrixShape` is for matrix-like or tensor-like objects with observable dimensions.
`VectorShape` is for vector-like objects with observable length. These traits do
not claim any algebraic operation.

## `AdditiveVector`

```moonbit
pub(open) trait AdditiveVector: VectorShape + Add + Neg + Sub {}
```

Represents vector-like objects with additive linear structure. It does not
require element-wise multiplication, dot product, norm, or a global zero.

Use `VecMulVector` only when an algorithm really needs element-wise
multiplication:

```moonbit
pub(open) trait VecMulVector: AdditiveVector + Mul {}
```

## `TransposeMatrix`

```moonbit
pub(open) trait TransposeMatrix: MatrixShape {
  fn transpose(Self) -> Self
}
```

Represents matrix-like objects with observable shape and same-category
transpose. It does not require matrix multiplication because multiplication of
dynamic rectangular matrices is only defined for compatible runtime shapes.

The trait does not require dense storage, contiguous memory, direct element
indexing, or mutation support.

Use the stronger traits only when the operation is actually required:

```moonbit
pub(open) trait AdditiveMatrix: TransposeMatrix + Add + Neg + Sub {}
pub(open) trait MatMulMatrix: AdditiveMatrix + Mul {}
```

## Stronger Algebra Traits

These optional traits are for carriers that can lawfully provide the inherited
global identities from `luna-generic`:

- `AdditiveVectorGroup: AdditiveVector + AddGroup`
- `VecMulSemiringVector: VecMulVector + Semiring`
- `VecMulRingVector: VecMulVector + Ring`
- `SquareMatrixSemiring: MatMulMatrix + Semiring`
- `SquareMatrixRing: MatMulMatrix + Ring`

Dynamic rectangular matrices and runtime-length vectors usually should not
implement these stronger traits unless their type-level representation really
fixes the required shape and identities.

## `FloatingScalarOps`

```moonbit
pub(open) trait FloatingScalarOps: Field + Num + ApproxEq {}
```

Marks floating scalar operation support for numerical algorithms. The inherited
`Field` member is an operation dependency from the existing Luna Flow ecosystem;
this trait should not be read as a claim that IEEE floating-point values satisfy
exact field laws.

Implemented for:

- `Float`
- `Double`

## Boundary

Do not add `dot`, `norm`, or inner-product traits here unless the scalar mapping
is modeled explicitly. The core algebra package is for minimal structure and
same-category operations.
