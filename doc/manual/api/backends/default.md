# backends/default API

`Luna-Flow/linear-algebra/backends/default` is the reference dense backend. It
wraps the concrete `@mutable` and `@immut` types in four owned structs and
implements the [`algebra`](../algebra.md) traits for them, so that generic
code bounded by those traits runs on real dense data. It also provides three
trait-bounded helper functions and a few backend methods (`scale`, `dot`,
`axpy`, `matvec`).

Source: [`src/backends/default`](../../../../src/backends/default/types.mbt).
Why the wrappers exist is explained in the
[backends/default design](../../design/backends/default.md).

## Import

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/backends/default",
}
```

## Overview

| Wrapper | Wraps | Semantics |
| --- | --- | --- |
| `DenseVector[T]` | `@mutable.Vector[T]` | shares the wrapped vector; results of operators are new vectors |
| `DenseMatrix[T]` | `@mutable.Matrix[T]` | shares the wrapped matrix; results of operators are new matrices |
| `ImmutableDenseVector[T]` | `@immut.Vector[T]` | value semantics |
| `ImmutableDenseMatrix[T]` | `@immut.Matrix[T]` | value semantics |

All operators return a new wrapper around a new inner value; none mutates its
operands. Shape mismatches in operators abort, as in the wrapped types.

## Generic helpers

### `shape_of`

`shape_of(m)` returns `(rows, cols)` of any `MatrixShape` value.

```mbti
pub fn[M : @algebra.MatrixShape] shape_of(M) -> (Int, Int)
```

### `transpose`

`transpose(m)` returns the transpose of any `TransposeMatrix` value, of the
same type.

```mbti
pub fn[M : @algebra.TransposeMatrix] transpose(M) -> M
```

### `matmul`

`matmul(a, b)` returns `a * b` for any `MatMulMatrix` type.

```mbti
pub fn[M : @algebra.MatMulMatrix] matmul(M, M) -> M
```

The precondition $\operatorname{cols}(a) = \operatorname{rows}(b)$ and the
failure behaviour are those of the type's `*`; for the dense wrappers a
mismatch aborts.

```moonbit check
///|
test "generic helpers on dense wrappers" {
  let a = @default.DenseMatrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  debug_inspect(@default.shape_of(a), content="(2, 3)")
  let at = @default.transpose(a)
  debug_inspect(@default.shape_of(at), content="(3, 2)")
  inspect(@default.matmul(a, at).inner(), content="|14, 32|\n|32, 77|")
}
```

## `DenseVector`

### `DenseVector`

`DenseVector[T]` is the mutable dense vector wrapper.

```mbti
pub struct DenseVector[T] {
  inner : @mutable.Vector[T]
}
```

The field is readable from other packages. Implemented traits:
`Add`, `Neg`, `Sub` and `Mul` (element-wise) under the element constraints of
the methods below, `@algebra.VectorShape` for all `T`,
`@algebra.AdditiveVector` when `T : Add + Neg`, and `@algebra.VecMulVector`
when `T : Add + Neg + Mul`.

### `DenseVector::from_array`

`DenseVector::from_array(xs)` wraps a new `@mutable.Vector` built from `xs`.

```mbti
pub fn[T] DenseVector::from_array(Array[T]) -> Self[T]
```

The array is not copied: the wrapper and `xs` share storage, as with
`@mutable.Vector::from_array`.

### `DenseVector::from_backend`

`DenseVector::from_backend(v)` wraps an existing `@mutable.Vector` without
copying.

```mbti
pub fn[T] DenseVector::from_backend(@mutable.Vector[T]) -> Self[T]
```

### `DenseVector::make`

`DenseVector::make(n, x)` builds a vector of length `n` filled with `x`.

```mbti
pub fn[T] DenseVector::make(Int, T) -> Self[T]
```

### `DenseVector::inner`

`DenseVector::inner(v)` returns the wrapped `@mutable.Vector`; writes to it are
visible through the wrapper.

```mbti
pub fn[T] DenseVector::inner(Self[T]) -> @mutable.Vector[T]
```

### `DenseVector::length`

`DenseVector::length(v)` returns the number of elements.

```mbti
pub fn[T] DenseVector::length(Self[T]) -> Int
```

### `DenseVector::at`

`DenseVector::at(v, i)` returns element `i`; it backs `v[i]`.

```mbti
#alias("_[_]")
pub fn[T] DenseVector::at(Self[T], Int) -> T
```

An index outside `0..<length` aborts.

### `DenseVector::add`, `DenseVector::sub`, `DenseVector::neg`

These are the promoted operator methods behind `u + v`, `u - v` and `-v`.

```mbti
pub fn[T : Add] DenseVector::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] DenseVector::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] DenseVector::neg(Self[T]) -> Self[T]
```

Operands of different lengths abort. Subtraction is computed as $u + (-v)$.

### `DenseVector::mul`

`DenseVector::mul(u, v)` is the element-wise (Hadamard) product behind `u * v`.

```mbti
pub fn[T : Mul] DenseVector::mul(Self[T], Self[T]) -> Self[T]
```

### `DenseVector::scale`

`DenseVector::scale(v, a)` returns $(v_i \cdot a)_i$, multiplying each element
on the right by the scalar.

```mbti
pub fn[T : Mul] DenseVector::scale(Self[T], T) -> Self[T]
```

### `DenseVector::dot`

`DenseVector::dot(u, v)` returns $\sum_i u_i v_i$, summed left to right from
`Zero::zero()`.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] DenseVector::dot(Self[T], Self[T]) -> T
```

Vectors of different lengths abort.

### `DenseVector::axpy`

`DenseVector::axpy(x, a, y)` returns $x a + y$, the BLAS `axpy` combination
with `self` as $x$.

```mbti
pub fn[T : Add + Mul] DenseVector::axpy(Self[T], T, Self[T]) -> Self[T]
```

The result is a new vector; `y` is not updated in place.

```moonbit check
///|
test "DenseVector backend methods" {
  let x = @default.DenseVector::from_array([1.0, 2.0, 3.0])
  let y = @default.DenseVector::make(3, 1.0)
  inspect(x.dot(y), content="6")
  inspect(x.axpy(2.0, y).inner(), content="|3, 5, 7|")
  inspect((x * x - y).inner(), content="|0, 3, 8|")
  inspect(x[2], content="3")
  inspect(@algebra.VectorShape::length(x), content="3")
}
```

## `DenseMatrix`

### `DenseMatrix`

`DenseMatrix[T]` is the mutable dense matrix wrapper.

```mbti
pub struct DenseMatrix[T] {
  inner : @mutable.Matrix[T]
}
```

Implemented traits: `Add`, `Neg`, `Sub`, `Mul` (matrix product),
`@algebra.MatrixShape` and `@algebra.TransposeMatrix` for all `T`,
`@algebra.AdditiveMatrix` when `T : Add + Neg`, and `@algebra.MatMulMatrix`
when `T : Add + Neg + AddMonoid + Mul`.

### `DenseMatrix::from_2d_array`

`DenseMatrix::from_2d_array(rows)` builds a matrix from nested row arrays.

```mbti
pub fn[T] DenseMatrix::from_2d_array(Array[Array[T]]) -> Self[T]
```

Ragged input aborts; `[]` gives a $0 \times 0$ matrix.

### `DenseMatrix::from_backend`

`DenseMatrix::from_backend(m)` wraps an existing `@mutable.Matrix` without
copying.

```mbti
pub fn[T] DenseMatrix::from_backend(@mutable.Matrix[T]) -> Self[T]
```

### `DenseMatrix::new`

`DenseMatrix::new(r, c, x)` builds an $r \times c$ matrix filled with `x`.

```mbti
pub fn[T] DenseMatrix::new(Int, Int, T) -> Self[T]
```

Negative dimensions abort.

### `DenseMatrix::inner`

`DenseMatrix::inner(m)` returns the wrapped `@mutable.Matrix`, which gives
access to the full `@mutable` API (views, decompositions, checked methods).

```mbti
pub fn[T] DenseMatrix::inner(Self[T]) -> @mutable.Matrix[T]
```

### `DenseMatrix::row`, `DenseMatrix::col`

`row` and `col` return the number of rows and columns.

```mbti
pub fn[T] DenseMatrix::row(Self[T]) -> Int
pub fn[T] DenseMatrix::col(Self[T]) -> Int
```

### `DenseMatrix::shape`

`DenseMatrix::shape(m)` returns `(rows, cols)`; it is the promoted
`@algebra.MatrixShape::shape`.

```mbti
pub fn[T] DenseMatrix::shape(Self[T]) -> (Int, Int)
```

### `DenseMatrix::transpose`

`DenseMatrix::transpose(m)` returns a materialized transpose; it is the
promoted `@algebra.TransposeMatrix::transpose`.

```mbti
pub fn[T] DenseMatrix::transpose(Self[T]) -> Self[T]
```

### `DenseMatrix::add`, `DenseMatrix::sub`, `DenseMatrix::neg`

Entry-wise `+`, `-` and unary `-`.

```mbti
pub fn[T : Add] DenseMatrix::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] DenseMatrix::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] DenseMatrix::neg(Self[T]) -> Self[T]
```

Operands of different shapes abort.

### `DenseMatrix::mul`

`DenseMatrix::mul(a, b)` is the matrix product behind `a * b`.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] DenseMatrix::mul(Self[T], Self[T]) -> Self[T]
```

$\operatorname{cols}(a) \ne \operatorname{rows}(b)$ aborts with
`Matrix::mul: dimension mismatch`. Cost: $rcn$ multiply-adds.

### `DenseMatrix::matvec`

`DenseMatrix::matvec(a, x)` returns the matrix-vector product $A x$ as a new
`DenseVector`.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] DenseMatrix::matvec(Self[T], DenseVector[T]) -> DenseVector[T]
```

A length mismatch aborts; use `a.inner().mul_vec(x.inner())` for a checked
version.

```moonbit check
///|
test "DenseMatrix operations" {
  let a = @default.DenseMatrix::from_2d_array([[2, 0], [1, 3]])
  let x = @default.DenseVector::from_array([1, 1])
  inspect(a.matvec(x).inner(), content="|2, 4|")
  inspect((a * a).inner(), content="|4, 0|\n|5, 9|")
  inspect(a.transpose().inner(), content="|2, 1|\n|0, 3|")
  debug_inspect(a.shape(), content="(2, 2)")
  inspect(a.inner().trace().unwrap(), content="5")
}
```

## `ImmutableDenseVector`

### `ImmutableDenseVector`

`ImmutableDenseVector[T]` is the immutable dense vector wrapper.

```mbti
pub struct ImmutableDenseVector[T] {
  inner : @immut.Vector[T]
}
```

It implements the same traits as `DenseVector` under the same constraints.

### `ImmutableDenseVector::from_array`

`ImmutableDenseVector::from_array(xs)` copies `xs` into a new `@immut.Vector`.

```mbti
pub fn[T] ImmutableDenseVector::from_array(Array[T]) -> Self[T]
```

### `ImmutableDenseVector::from_backend`

`ImmutableDenseVector::from_backend(v)` wraps an existing `@immut.Vector`.

```mbti
pub fn[T] ImmutableDenseVector::from_backend(@immut.Vector[T]) -> Self[T]
```

### `ImmutableDenseVector::make`

`ImmutableDenseVector::make(n, x)` builds a vector of length `n` filled with
`x`.

```mbti
pub fn[T] ImmutableDenseVector::make(Int, T) -> Self[T]
```

### `ImmutableDenseVector::inner`

`ImmutableDenseVector::inner(v)` returns the wrapped `@immut.Vector`.

```mbti
pub fn[T] ImmutableDenseVector::inner(Self[T]) -> @immut.Vector[T]
```

### `ImmutableDenseVector::length`

`ImmutableDenseVector::length(v)` returns the number of elements.

```mbti
pub fn[T] ImmutableDenseVector::length(Self[T]) -> Int
```

### `ImmutableDenseVector::at`

`ImmutableDenseVector::at(v, i)` returns element `i`; it backs `v[i]`.

```mbti
#alias("_[_]")
pub fn[T] ImmutableDenseVector::at(Self[T], Int) -> T
```

### `ImmutableDenseVector::add`, `ImmutableDenseVector::sub`, `ImmutableDenseVector::neg`, `ImmutableDenseVector::mul`

Element-wise `+`, `-`, unary `-` and Hadamard `*`.

```mbti
pub fn[T : Add] ImmutableDenseVector::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] ImmutableDenseVector::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] ImmutableDenseVector::neg(Self[T]) -> Self[T]
pub fn[T : Mul] ImmutableDenseVector::mul(Self[T], Self[T]) -> Self[T]
```

### `ImmutableDenseVector::scale`

`ImmutableDenseVector::scale(v, a)` returns $(v_i \cdot a)_i$.

```mbti
pub fn[T : Mul] ImmutableDenseVector::scale(Self[T], T) -> Self[T]
```

### `ImmutableDenseVector::dot`

`ImmutableDenseVector::dot(u, v)` returns $\sum_i u_i v_i$.

```mbti
pub fn[T : @luna-generic.Zero + Add + Mul] ImmutableDenseVector::dot(Self[T], Self[T]) -> T
```

Vectors of different lengths abort.

### `ImmutableDenseVector::axpy`

`ImmutableDenseVector::axpy(x, a, y)` returns $x a + y$.

```mbti
pub fn[T : Add + Mul] ImmutableDenseVector::axpy(Self[T], T, Self[T]) -> Self[T]
```

## `ImmutableDenseMatrix`

### `ImmutableDenseMatrix`

`ImmutableDenseMatrix[T]` is the immutable dense matrix wrapper.

```mbti
pub struct ImmutableDenseMatrix[T] {
  inner : @immut.Matrix[T]
}
```

It implements the same traits as `DenseMatrix`; `@algebra.MatMulMatrix` needs
`T : Add + Neg + Zero + Mul`.

### `ImmutableDenseMatrix::from_2d_array`

`ImmutableDenseMatrix::from_2d_array(rows)` builds a matrix from nested rows;
ragged input aborts.

```mbti
pub fn[T] ImmutableDenseMatrix::from_2d_array(Array[Array[T]]) -> Self[T]
```

### `ImmutableDenseMatrix::from_backend`

`ImmutableDenseMatrix::from_backend(m)` wraps an existing `@immut.Matrix`.

```mbti
pub fn[T] ImmutableDenseMatrix::from_backend(@immut.Matrix[T]) -> Self[T]
```

### `ImmutableDenseMatrix::new`

`ImmutableDenseMatrix::new(r, c, x)` builds an $r \times c$ matrix filled with
`x`.

```mbti
pub fn[T] ImmutableDenseMatrix::new(Int, Int, T) -> Self[T]
```

### `ImmutableDenseMatrix::inner`

`ImmutableDenseMatrix::inner(m)` returns the wrapped `@immut.Matrix`.

```mbti
pub fn[T] ImmutableDenseMatrix::inner(Self[T]) -> @immut.Matrix[T]
```

### `ImmutableDenseMatrix::row`, `ImmutableDenseMatrix::col`, `ImmutableDenseMatrix::shape`

Row count, column count and `(rows, cols)`; `shape` is the promoted
`@algebra.MatrixShape::shape`.

```mbti
pub fn[T] ImmutableDenseMatrix::row(Self[T]) -> Int
pub fn[T] ImmutableDenseMatrix::col(Self[T]) -> Int
pub fn[T] ImmutableDenseMatrix::shape(Self[T]) -> (Int, Int)
```

### `ImmutableDenseMatrix::transpose`

`ImmutableDenseMatrix::transpose(m)` returns the transpose; it is the promoted
`@algebra.TransposeMatrix::transpose`.

```mbti
pub fn[T] ImmutableDenseMatrix::transpose(Self[T]) -> Self[T]
```

### `ImmutableDenseMatrix::add`, `ImmutableDenseMatrix::sub`, `ImmutableDenseMatrix::neg`, `ImmutableDenseMatrix::mul`

Entry-wise `+`, `-`, unary `-`, and the matrix product.

```mbti
pub fn[T : Add] ImmutableDenseMatrix::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] ImmutableDenseMatrix::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] ImmutableDenseMatrix::neg(Self[T]) -> Self[T]
pub fn[T : Add + @luna-generic.Zero + Mul] ImmutableDenseMatrix::mul(Self[T], Self[T]) -> Self[T]
```

Shape mismatches abort.

### `ImmutableDenseMatrix::matvec`

`ImmutableDenseMatrix::matvec(a, x)` returns $A x$ as a new
`ImmutableDenseVector`; a length mismatch aborts.

```mbti
pub fn[T : Add + @luna-generic.Zero + Mul] ImmutableDenseMatrix::matvec(Self[T], ImmutableDenseVector[T]) -> ImmutableDenseVector[T]
```

```moonbit check
///|
test "immutable wrappers" {
  let a = @default.ImmutableDenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let x = @default.ImmutableDenseVector::from_array([1, -1])
  inspect(a.matvec(x).inner(), content="|-1, -1|")
  inspect((a - a.transpose()).inner(), content="|0, -1|\n|1, 0|")
  inspect(x.dot(x), content="2")
  inspect(x.scale(3).inner(), content="|3, -3|")
}
```
