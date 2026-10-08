# backends/default tutorial

This tutorial shows how to use the dense wrappers of `backends/default` as
ready-to-run data for generic code written against the `algebra` traits, and
how to step down to the full concrete API when you need it. The background is
in the [backends/default design](../../design/backends/default.md).

## Quick start

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

```moonbit check
///|
test "multiply two dense matrices" {
  let a = @default.DenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let b = @default.DenseMatrix::from_2d_array([[0, 1], [1, 0]])
  inspect((a * b).inner(), content="|2, 1|\n|4, 3|")
}
```

## Everyday tasks

### Run a generic algorithm on both wrappers

A helper written against `MatMulMatrix` accepts the mutable and the immutable
wrapper alike:

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] def_tut_commutator(a : M, b : M) -> M {
  a * b - b * a
}

///|
test "commutator on two representations" {
  let a = @default.DenseMatrix::from_2d_array([[0, 1], [0, 0]])
  let b = @default.DenseMatrix::from_2d_array([[0, 0], [1, 0]])
  inspect(def_tut_commutator(a, b).inner(), content="|1, 0|\n|0, -1|")
  let ai = @default.ImmutableDenseMatrix::from_2d_array([[0, 1], [0, 0]])
  let bi = @default.ImmutableDenseMatrix::from_2d_array([[0, 0], [1, 0]])
  inspect(def_tut_commutator(ai, bi).inner(), content="|1, 0|\n|0, -1|")
}
```

### Evaluate a linear model

`matvec`, `dot` and `axpy` cover the common vector arithmetic of a linear
model $y = W x + b$:

```moonbit check
///|
test "a tiny linear layer" {
  let w = @default.DenseMatrix::from_2d_array([[0.5, -1.0], [2.0, 0.0]])
  let x = @default.DenseVector::from_array([2.0, 1.0])
  let b = @default.DenseVector::from_array([0.1, 0.2])
  let y = w.matvec(x) + b
  inspect(y.inner(), content="|0.1, 4.2|")
  inspect(y.dot(y), content="17.650000000000002")
}
```

The last digit of `17.650000000000002` is rounding: $0.1^2 + 4.2^2$ is not
exactly representable.

### Step down to the concrete API

The wrappers expose only trait-level operations. Use `inner()` for anything
else, for example a checked inverse:

```moonbit check
///|
test "checked inverse through inner" {
  let a = @default.DenseMatrix::from_2d_array([[4.0, 7.0], [2.0, 6.0]])
  let inv = @default.DenseMatrix::from_backend(a.inner().inverse().unwrap())
  let id = a * inv
  inspect((id.inner().get(0, 0) - 1.0).abs() < 1.0e-12, content="true")
  inspect(id.inner().get(0, 1).abs() < 1.0e-12, content="true")
}
```

### Wrap an existing matrix without copying

`from_backend` shares the inner value, so a later write is visible:

```moonbit check
///|
test "wrapping shares storage" {
  let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  let d = @default.DenseMatrix::from_backend(m)
  m.set(0, 0, 10)
  inspect(d.inner().get(0, 0), content="10")
}
```

## Going further

**Choosing a wrapper.** Use `DenseMatrix`/`DenseVector` when you will also use
the in-place and numerical API of `@mutable` (views, decompositions,
statistics). Use the `Immutable*` wrappers when values must not change after
construction, for example when they are shared between parts of a program.

**Converting between wrappers.** The [`container` adapters](../container/adapters.md)
have dictionaries for all four wrappers, so `matrix_convert` moves data between
them.

**Writing a new backend.** A sparse or fixed-size type should implement the
`algebra` traits for itself, as in the [algebra tutorial](../algebra.md),
rather than convert into these wrappers.

## Common pitfalls

- **Expecting `DenseVector::from_array` to copy.** It shares the array, like
  `@mutable.Vector::from_array`. Copy first if the array is reused.
- **Expecting `axpy` to update in place.** It returns a new vector.
- **Multiplying incompatible shapes.** `*` and `matvec` abort; check shapes
  with `shape()` or use the checked methods of the inner type.
- **Looking for decompositions on the wrapper.** They are on `inner()`.

## Next steps

- [backends/default API](../../api/backends/default.md).
- [algebra tutorial](../algebra.md) for writing the generic side.
- [mutable tutorial](../mutable.md) and [immut tutorial](../immut.md) for the
  wrapped types.
