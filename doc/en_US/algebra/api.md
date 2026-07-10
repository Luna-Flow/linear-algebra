# `linear-algebra/algebra`

API baseline for `Luna-Flow/linear-algebra/algebra` in the current `0.4.6`
repository state.

## Experimental Status

`algebra` is an experimental feature. It is ready for backend-integration
experiments and feedback, but its trait hierarchy, supertrait requirements,
operator commitments, and function signatures may change incompatibly before
stabilization. Downstream libraries should depend on the smallest capability
they need and should not re-export this package as a compatibility-stable
public boundary yet.

## Purpose

`algebra` owns the linear-algebra structure traits. Backend packages implement
these traits for their own concrete data types. The traits in this package are
split by the minimum capability they require so generic algorithms do not
accidentally depend on Hadamard multiplication, matrix multiplication, or exact
floating-point field laws.

External type authors should start with the
[ecosystem integration guide](./integration.md) to select the smallest valid
trait level and understand its operator commitments.

## Project Setup

`algebra` is the structure layer only. If you also need the shared upstream
scalar abstractions, add them explicitly:

```sh
moon add Luna-Flow/linear-algebra@0.4.6
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

Use `@algebra` for linear-algebra structure traits. Import `@lf_alg` and
`@lf_arith` directly when your code also needs the shared upstream abstractions.

## Matrix Shape Traits

```moonbit check
///|
struct ToyMatrix {
  rows : Int
  cols : Int
}

///|
struct ToyVector {
  size : Int
}

///|
impl @algebra.MatrixShape for ToyMatrix with fn shape(self) {
  (self.rows, self.cols)
}

///|
impl @algebra.VectorShape for ToyVector with fn length(self) {
  self.size
}

///|
test "shape traits report dimensions" {
  let matrix : ToyMatrix = { rows: 2, cols: 3 }
  let vector : ToyVector = { size: 4 }
  let (rows, cols) = @algebra.MatrixShape::shape(matrix)
  inspect(rows, content="2")
  inspect(cols, content="3")
  inspect(@algebra.VectorShape::length(vector), content="4")
}
```

`MatrixShape` is for matrix-like or tensor-like objects with observable dimensions.
`VectorShape` is for vector-like objects with observable length. These traits do
not claim any algebraic operation.

## `AdditiveVector`

```moonbit check
///|
struct AddVec {
  value : Int
}

///|
impl @algebra.VectorShape for AddVec with fn length(_) {
  1
}

///|
impl Add for AddVec with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for AddVec with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for AddVec with fn sub(left, right) {
  left + -right
}

///|
impl @algebra.AdditiveVector for AddVec

///|
fn[T : @algebra.AdditiveVector] add_vectors(left : T, right : T) -> T {
  left + right
}

///|
test "AdditiveVector packages vector addition and subtraction" {
  let left : AddVec = { value: 7 }
  let right : AddVec = { value: 2 }
  inspect(add_vectors(left, right).value, content="9")
  inspect(add_vectors(left, -right).value, content="5")
}
```

Represents vector-like objects with additive linear structure. It does not
require element-wise multiplication, dot product, norm, or a global zero.

Reach for `VecMulVector` only when an algorithm really needs element-wise
multiplication:

```moonbit check
///|
struct MulVec {
  value : Int
}

///|
impl @algebra.VectorShape for MulVec with fn length(_) {
  1
}

///|
impl Add for MulVec with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for MulVec with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for MulVec with fn sub(left, right) {
  left + -right
}

///|
impl Mul for MulVec with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveVector for MulVec

///|
impl @algebra.VecMulVector for MulVec

///|
fn[T : @algebra.VecMulVector] hadamard_product(left : T, right : T) -> T {
  left * right
}

///|
test "VecMulVector adds element-wise multiplication" {
  let left : MulVec = { value: 3 }
  let right : MulVec = { value: 4 }
  inspect(hadamard_product(left, right).value, content="12")
}
```

## `TransposeMatrix`

```moonbit check
///|
struct Flip2x2 {
  a11 : Int
  a12 : Int
  a21 : Int
  a22 : Int
}

///|
impl @algebra.MatrixShape for Flip2x2 with fn shape(_) {
  (2, 2)
}

///|
impl @algebra.TransposeMatrix for Flip2x2 with fn transpose(self) {
  { a11: self.a11, a12: self.a21, a21: self.a12, a22: self.a22 }
}

///|
test "TransposeMatrix keeps shape and swaps off-diagonal entries" {
  let matrix : Flip2x2 = { a11: 1, a12: 2, a21: 3, a22: 4 }
  let transposed = @algebra.TransposeMatrix::transpose(matrix)
  let (rows, cols) = @algebra.MatrixShape::shape(transposed)
  inspect(rows, content="2")
  inspect(cols, content="2")
  inspect(transposed.a12, content="3")
  inspect(transposed.a21, content="2")
}
```

Represents matrix-like objects with observable shape and same-category
transpose. It does not require matrix multiplication because dynamic rectangular
matrix multiplication is only defined for compatible runtime shapes.

The trait does not require dense storage, contiguous memory, direct element
indexing, or mutation support.

Use the stronger traits only when the algorithm actually needs the extra
operation:

```moonbit check
///|
struct ScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for ScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for ScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for ScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for ScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for ScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for ScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveMatrix for ScalarMatrix

///|
impl @algebra.MatMulMatrix for ScalarMatrix

///|
fn[T : @algebra.MatMulMatrix] multiply_matrices(left : T, right : T) -> T {
  left * right
}

///|
test "matrix additive and multiplicative traits compose cleanly" {
  let left : ScalarMatrix = { value: 2 }
  let right : ScalarMatrix = { value: 5 }
  inspect((left + right).value, content="7")
  inspect(multiply_matrices(left, right).value, content="10")
}
```

## Boundary

Do not add `dot`, `norm`, or inner-product traits here unless the scalar mapping
is modeled explicitly. The core algebra package is for minimal structure and
same-category operations.
