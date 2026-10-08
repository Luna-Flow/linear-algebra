# algebra API

`Luna-Flow/linear-algebra/algebra` defines the structure traits that whole
vector and matrix objects implement: shape, closed additive structure,
Hadamard multiplication, transpose and matrix multiplication. Each trait asks
for one more capability than the one below it, so a generic algorithm can name
exactly what it uses. The package has no types and no functions; the
implementations for the repository's own dense types live in
[`backends/default`](backends/default.md).

Source: [`src/algebra/linear_traits.mbt`](../../../src/algebra/linear_traits.mbt).
The mathematics behind the hierarchy is in the [algebra design](../design/algebra.md),
and the [integration guide](../integration/algebra.md) explains how external
types choose a level.

> [!WARNING]
> `algebra` is experimental. The trait hierarchy, its supertraits and the
> operator commitments may change incompatibly before the package is declared
> stable. Depend on the smallest trait you need, and do not re-export these
> traits as a stable public boundary of your own library yet.

## Import

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/algebra",
}
```

## Trait hierarchy

| Trait | Supertraits | Adds |
| --- | --- | --- |
| `VectorShape` | none | `length` |
| `AdditiveVector` | `VectorShape + Add + Neg + Sub` | closed `+`, unary `-`, binary `-` |
| `VecMulVector` | `AdditiveVector + Mul` | element-wise (Hadamard) `*` |
| `MatrixShape` | none | `shape` |
| `TransposeMatrix` | `MatrixShape` | same-type `transpose` |
| `AdditiveMatrix` | `TransposeMatrix + Add + Neg + Sub` | closed `+`, unary `-`, binary `-` |
| `MatMulMatrix` | `AdditiveMatrix + Mul` | matrix product `*` |

All traits are `pub(open)`: any package may implement them for the types it
owns. The operator traits `Add`, `Neg`, `Sub` and `Mul` are the builtin MoonBit
traits, so a type that joins a level keeps using the ordinary operators.

## Shape traits

### `VectorShape`

`VectorShape` marks an object whose length can be observed.

```mbti
pub(open) trait VectorShape {
  fn length(Self) -> Int
}
```

It claims no operation and no element access. A vector of length $n$ is an
element of some set that the implementation associates with $\{0, \dots, n-1\}$;
the trait only exposes $n$.

### `VectorShape::length`

`VectorShape::length` returns the number of components of the vector.

```mbti
fn VectorShape::length(Self) -> Int
```

The result is non-negative for every implementation in this repository. Call it
in the trait-qualified form `@algebra.VectorShape::length(v)` inside generic
code; concrete types may also expose a `length` method of their own.

### `MatrixShape`

`MatrixShape` marks an object whose row and column counts can be observed.

```mbti
pub(open) trait MatrixShape {
  fn shape(Self) -> (Int, Int)
}
```

### `MatrixShape::shape`

`MatrixShape::shape` returns `(rows, cols)`.

```mbti
fn MatrixShape::shape(Self) -> (Int, Int)
```

Both components are non-negative. Degenerate shapes $0 \times n$ and
$n \times 0$ are valid matrices and must be reported as such.

The following example implements both shape traits for two small types and
reads them back in generic form.

```moonbit check
///|
struct AlgApiToyMatrix {
  rows : Int
  cols : Int
}

///|
struct AlgApiToyVector {
  size : Int
}

///|
impl @algebra.MatrixShape for AlgApiToyMatrix with fn shape(self) {
  (self.rows, self.cols)
}

///|
impl @algebra.VectorShape for AlgApiToyVector with fn length(self) {
  self.size
}

///|
test "shape traits report dimensions" {
  let matrix : AlgApiToyMatrix = { rows: 2, cols: 3, }
  let vector : AlgApiToyVector = { size: 4, }
  debug_inspect(@algebra.MatrixShape::shape(matrix), content="(2, 3)")
  inspect(@algebra.VectorShape::length(vector), content="4")
}
```

## Vector traits

### `AdditiveVector`

`AdditiveVector` marks a vector type whose values form an abelian group under
`+`.

```mbti
pub(open) trait AdditiveVector : VectorShape + Add + Neg + Sub {
}
```

The trait has no methods of its own. Implementing it is a promise that, for
values of equal length,

$$
\begin{aligned}
(u + v) + w &= u + (v + w), & u + v &= v + u, \\
(u + (-u)) + v &= v, & u - v &= u + (-v),
\end{aligned}
$$

and that the results keep the length of the operands. The trait does not ask
for a global zero, a scalar action, a dot product or a norm; see the
[design page](../design/algebra.md) for why. Equal lengths are a runtime
precondition: the implementations in this repository abort on a length
mismatch.

### `VecMulVector`

`VecMulVector` adds the element-wise (Hadamard) product $(u \odot v)_i = u_i v_i$
as `*`.

```mbti
pub(open) trait VecMulVector : AdditiveVector + Mul {
}
```

`*` must mean the Hadamard product, not a dot or cross product. With it, the
vectors of a fixed length $n$ over a ring $R$ form the product ring $R^n$, so
`*` is associative and distributes over `+`.

The example writes one helper per level and runs it on a one-component toy
type.

```moonbit check
///|
struct AlgApiMulVec {
  value : Int
}

///|
impl @algebra.VectorShape for AlgApiMulVec with fn length(_) {
  1
}

///|
impl Add for AlgApiMulVec with fn add(left, right) {
  { value: left.value + right.value, }
}

///|
impl Neg for AlgApiMulVec with fn neg(value) {
  { value: -value.value, }
}

///|
impl Sub for AlgApiMulVec with fn sub(left, right) {
  left + -right
}

///|
impl Mul for AlgApiMulVec with fn mul(left, right) {
  { value: left.value * right.value, }
}

///|
impl @algebra.AdditiveVector for AlgApiMulVec

///|
impl @algebra.VecMulVector for AlgApiMulVec

///|
fn[V : @algebra.AdditiveVector] alg_api_difference(left : V, right : V) -> V {
  left - right
}

///|
fn[V : @algebra.VecMulVector] alg_api_hadamard(left : V, right : V) -> V {
  left * right
}

///|
test "vector traits expose closed operators" {
  let left : AlgApiMulVec = { value: 7, }
  let right : AlgApiMulVec = { value: 3, }
  inspect(alg_api_difference(left, right).value, content="4")
  inspect(alg_api_hadamard(left, right).value, content="21")
}
```

## Matrix traits

### `TransposeMatrix`

`TransposeMatrix` marks a matrix type that is closed under transposition.

```mbti
pub(open) trait TransposeMatrix : MatrixShape {
  fn transpose(Self) -> Self
}
```

### `TransposeMatrix::transpose`

`TransposeMatrix::transpose` returns the transpose $A^{\mathsf T}$, with
$(A^{\mathsf T})_{ij} = A_{ji}$, as a value of the same type.

```mbti
fn TransposeMatrix::transpose(Self) -> Self
```

An implementation must satisfy

$$
\operatorname{shape}(A^{\mathsf T}) = (n, m) \text{ when } \operatorname{shape}(A) = (m, n),
\qquad (A^{\mathsf T})^{\mathsf T} = A .
$$

Transpose is total: it never fails, for any shape. The trait does not require
dense storage, element access or mutation; it also does not say whether the
result shares storage with the argument.

### `AdditiveMatrix`

`AdditiveMatrix` adds closed entry-wise `+`, unary `-` and binary `-` to a
transposable matrix type.

```mbti
pub(open) trait AdditiveMatrix : TransposeMatrix + Add + Neg + Sub {
}
```

The laws are those of `AdditiveVector` for matrices of equal shape, together
with $(A + B)^{\mathsf T} = A^{\mathsf T} + B^{\mathsf T}$. Equal shapes are a
runtime precondition.

### `MatMulMatrix`

`MatMulMatrix` adds the matrix product as `*`.

```mbti
pub(open) trait MatMulMatrix : AdditiveMatrix + Mul {
}
```

`*` must be the product $(AB)_{ik} = \sum_j A_{ij} B_{jk}$, never the Hadamard
product. It is defined only when the column count of the left operand equals
the row count of the right one, so for runtime-shaped matrices it is a partial
operation. The trait does not standardize what happens outside that domain:
every implementation must document it. The dense wrappers of
[`backends/default`](backends/default.md) abort with a dimension-mismatch
message. An implementation must satisfy, wherever both sides are defined,

$$
(AB)C = A(BC), \qquad A(B + C) = AB + AC, \qquad (A + B)C = AC + BC ,
$$

and, when the scalars commute, $(AB)^{\mathsf T} = B^{\mathsf T} A^{\mathsf T}$.

The example implements every matrix level for a fixed $1 \times 1$ type, where
all operations are total, and uses a generic Gram-matrix helper.

```moonbit check
///|
struct AlgApiScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for AlgApiScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for AlgApiScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for AlgApiScalarMatrix with fn add(left, right) {
  { value: left.value + right.value, }
}

///|
impl Neg for AlgApiScalarMatrix with fn neg(value) {
  { value: -value.value, }
}

///|
impl Sub for AlgApiScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for AlgApiScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value, }
}

///|
impl @algebra.AdditiveMatrix for AlgApiScalarMatrix

///|
impl @algebra.MatMulMatrix for AlgApiScalarMatrix

///|
fn[M : @algebra.MatMulMatrix] alg_api_gram(matrix : M) -> M {
  @algebra.TransposeMatrix::transpose(matrix) * matrix
}

///|
test "matrix traits compose" {
  let a : AlgApiScalarMatrix = { value: 3, }
  let b : AlgApiScalarMatrix = { value: 5, }
  inspect((a + b).value, content="8")
  inspect(alg_api_gram(a).value, content="9")
}
```

## Implementations in this repository

| Type | Traits |
| --- | --- |
| `@default.DenseVector[T]` | `VectorShape`; `AdditiveVector` when `T : Add + Neg`; `VecMulVector` when `T : Add + Neg + Mul` |
| `@default.ImmutableDenseVector[T]` | the same as `DenseVector` |
| `@default.DenseMatrix[T]` | `MatrixShape`, `TransposeMatrix`; `AdditiveMatrix` when `T : Add + Neg`; `MatMulMatrix` when `T : Add + Neg + AddMonoid + Mul` |
| `@default.ImmutableDenseMatrix[T]` | `MatrixShape`, `TransposeMatrix`; `AdditiveMatrix` when `T : Add + Neg`; `MatMulMatrix` when `T : Add + Neg + Zero + Mul` |

The concrete `@immut` and `@mutable` types do not implement these traits
directly; they are wrapped by `backends/default` so that the packages keep
their own dependency direction (see the [architecture guide](../architecture.md)).
