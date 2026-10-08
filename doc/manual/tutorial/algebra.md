# algebra tutorial

This tutorial shows how to write linear-algebra helpers once, against the
`algebra` traits, and run them on any matrix or vector type that implements
those traits: the repository's dense wrappers or a type of your own. You need
to know MoonBit generics; the mathematics is kept light and explained in the
[algebra design](../design/algebra.md).

| I want to | Use |
| --- | --- |
| write one helper for every additive vector type | a bound `V : @algebra.AdditiveVector` |
| use the matrix product generically | `M : @algebra.MatMulMatrix` and `@default.matmul` |
| transpose generically | `@algebra.TransposeMatrix::transpose` or `@default.transpose` |
| check shapes before `*` | `@algebra.MatrixShape::shape` |
| run the helpers on dense data | the `backends/default` wrappers |
| make my own type usable | implement the smallest trait that fits |

## Quick start

Add the module and the packages you use:

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/backends/default",
}
```

The smallest useful program asks a matrix for its shape through the trait, so
it works for every `MatrixShape` type:

```moonbit check
///|
fn[M : @algebra.MatrixShape] alg_tut_describe(matrix : M) -> String {
  let (rows, cols) = @algebra.MatrixShape::shape(matrix)
  "\{rows}x\{cols}"
}

///|
test "describe a dense matrix" {
  let m = @default.DenseMatrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  inspect(alg_tut_describe(m), content="2x3")
}
```

The output is `2x3`.

## Everyday tasks

### Compute a residual for any additive vector type

A residual $r = b - A x$ only needs vector subtraction. Ask for
`AdditiveVector`, and the helper accepts both the mutable and the immutable
dense vectors:

```moonbit check
///|
fn[V : @algebra.AdditiveVector] alg_tut_residual(
  observed : V,
  predicted : V,
) -> V {
  observed - predicted
}

///|
test "residual over two vector representations" {
  let b = @default.DenseVector::from_array([3, 5, 7])
  let p = @default.DenseVector::from_array([1, 5, 9])
  let r = alg_tut_residual(b, p)
  inspect(r.inner(), content="|2, 0, -2|")
  let bi = @default.ImmutableDenseVector::from_array([3, 5, 7])
  let pi = @default.ImmutableDenseVector::from_array([1, 5, 9])
  inspect(alg_tut_residual(bi, pi).inner(), content="|2, 0, -2|")
}
```

### Build the Gram matrix $A^{\mathsf T} A$

The Gram matrix needs a transpose and a matrix product, which is exactly
`MatMulMatrix`:

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] alg_tut_gram(a : M) -> M {
  @algebra.TransposeMatrix::transpose(a) * a
}

///|
test "gram matrix of a 3x2 design matrix" {
  let a = @default.ImmutableDenseMatrix::from_2d_array([[1, 0], [1, 1], [1, 2]])
  let g = alg_tut_gram(a)
  debug_inspect(@algebra.MatrixShape::shape(g), content="(2, 2)")
  inspect(g.inner(), content="|3, 3|\n|3, 5|")
}
```

$A^{\mathsf T}A$ is always defined, whatever the shape of $A$: an
$m \times n$ matrix gives an $n \times n$ result.

### Check composability before multiplying

On runtime-shaped matrices `*` is partial, and the dense wrappers abort on a
mismatch. When shapes come from data, check them first with `MatrixShape`:

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] alg_tut_try_product(a : M, b : M) -> M? {
  let (_, inner_a) = @algebra.MatrixShape::shape(a)
  let (inner_b, _) = @algebra.MatrixShape::shape(b)
  if inner_a == inner_b {
    Some(a * b)
  } else {
    None
  }
}

///|
test "product only for composable shapes" {
  let a = @default.DenseMatrix::from_2d_array([[1, 2]])
  let b = @default.DenseMatrix::from_2d_array([[3], [4]])
  debug_inspect(
    alg_tut_try_product(a, b).map(m => m.inner().get(0, 0)),
    content="Some(11)",
  )
  inspect(alg_tut_try_product(a, a) is None, content="true")
}
```

### Bring your own fixed-size matrix

A $2 \times 2$ matrix type has a total product, so it can implement every
matrix level without runtime preconditions. Implement the operator traits, then
declare the levels:

```moonbit check
///|
struct AlgTutMat2 {
  a : Int
  b : Int
  c : Int
  d : Int
}

///|
impl @algebra.MatrixShape for AlgTutMat2 with fn shape(_) {
  (2, 2)
}

///|
impl @algebra.TransposeMatrix for AlgTutMat2 with fn transpose(m) {
  { a: m.a, b: m.c, c: m.b, d: m.d, }
}

///|
impl Add for AlgTutMat2 with fn add(x, y) {
  { a: x.a + y.a, b: x.b + y.b, c: x.c + y.c, d: x.d + y.d, }
}

///|
impl Neg for AlgTutMat2 with fn neg(x) {
  { a: -x.a, b: -x.b, c: -x.c, d: -x.d, }
}

///|
impl Sub for AlgTutMat2 with fn sub(x, y) {
  x + -y
}

///|
impl Mul for AlgTutMat2 with fn mul(x, y) {
  {
    a: x.a * y.a + x.b * y.c,
    b: x.a * y.b + x.b * y.d,
    c: x.c * y.a + x.d * y.c,
    d: x.c * y.b + x.d * y.d,
  }
}

///|
impl @algebra.AdditiveMatrix for AlgTutMat2

///|
impl @algebra.MatMulMatrix for AlgTutMat2

///|
test "the generic gram helper runs on a custom type" {
  let m : AlgTutMat2 = { a: 1, b: 2, c: 3, d: 4, }
  let g = alg_tut_gram(m)
  debug_inspect((g.a, g.b, g.c, g.d), content="(10, 14, 14, 20)")
}
```

The helper `alg_tut_gram` from the previous task needed no change.

## Going further

**Use the generic helpers of `backends/default`.** `@default.shape_of`,
`@default.transpose` and `@default.matmul` are the trait-bounded versions of
the three operations; they are convenient when you want a function value
rather than a trait-qualified call.

**Combine with `container`.** The `algebra` traits describe whole-object
operations and never expose elements. When an algorithm also needs to read or
build individual entries, use the operation dictionaries of
[`container`](container.md) alongside the trait bound; the two layers are
independent.

**Scalar requirements stay on the concrete types.** The traits do not mention
the scalar type. If an algorithm needs scalar multiplication or a dot product,
take the concrete type (`@default.DenseVector[T]` with `T : AddMonoid + Mul`)
or pass the scalar operation in as a function.

**Checked products.** When failure must be a value, convert to a concrete type
with a checked method, such as `@immut.Matrix::matmul`, which returns
`Result[_, LinearAlgebraError]`. See the [error tutorial](error.md).

## Common pitfalls

- **Calling trait methods with dot syntax in generic code.** Inside
  `fn[M : @algebra.MatMulMatrix]`, write
  `@algebra.TransposeMatrix::transpose(m)`. Dot calls on a type parameter for a
  supertrait method are deprecated in MoonBit 0.10.
- **Implementing `MatMulMatrix` with a Hadamard `*`.** `*` on a `MatMulMatrix`
  must be the matrix product; a type whose `*` is entry-wise should stop at
  `AdditiveMatrix`.
- **Expecting `(AB)^T = B^T A^T` for every scalar.** It needs commuting
  scalars; quaternion matrices violate it.
- **Comparing floating-point results exactly.** Products of `Double` matrices
  agree only up to rounding. Compare with a tolerance (see the
  [`arithmetic` tutorial](arithmetic.md)).

## Next steps

- [algebra API](../api/algebra.md) for the exact laws of each trait.
- [algebra design](../design/algebra.md) for why there is no `VectorSpace`
  trait and why multiplication is a separate level.
- [Algebra integration guide](../integration/algebra.md) before you publish
  implementations for your own types.
- [`backends/default` tutorial](backends/default.md) for the dense wrappers.
- Downstream use: [geometry3d](https://lunaflow.cn/en/geometry3d/) builds on
  these layers.
