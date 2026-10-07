# `@mutable.Vector`

API baseline for `@mutable.Vector` in the current `0.5.0` repository state.

## Overview

- `@mutable.Vector` is the repository's mutation-oriented vector type.
- Storage is a wrapped `Array[T]`, so indexed writes update the underlying
  mutable buffer directly.
- Even in this package, many algebraic helpers still return fresh vectors so
  callers can choose between mutation and value-producing transforms.

## Core API

- `Vector::from_array(arr)` / `Vector::make(n, elem)` / `Vector::makei(n, f)`
  Construct vectors from existing data, a repeated value, or an index function.
- `length()`
  Returns the vector length.
- `v[i]` / `v[i] = x`
  Read and write one element. Bounds follow `Array[T]` behavior.
- `copy()`
  Returns a deep copy of the vector.
- `iter()`
  Exposes an iterator over the current elements.

## Value-producing helpers

- `map(f)` / `zip_with(other, f)`
  Return a transformed vector without mutating `self`.
- `add_constant(cst)`
  Adds the same scalar to each element.
- `left_scale(scalar)` / `right_scale(scalar)`
  Return scaled vectors.
- `lerp(other, alpha)`
  Computes `(1 - alpha) * self + alpha * other`.
- `+`, `*`, unary `-`
  Element-wise addition, Hadamard multiplication, and negation.

## In-place helpers

- `map_inplace(f)`
  Rewrites every element in place.
- `left_scale_inplace(scalar)` / `right_scale_inplace(scalar)`
  Apply scalar multiplication in place.

## Scalar and matrix helpers

- `dot(other)`
  Computes the dot product. Length mismatch aborts.
- `lin_comb(weights, vectors)`
  Top-level helper that builds one vector from weighted input vectors. Empty
  inputs, mismatched counts, or mismatched vector lengths abort.
- `to_col_matrix()` / `to_row_matrix()`
  Convert the vector into matrix form.
- `scaled_matrix()`
  Builds a diagonal matrix with the vector on the main diagonal.
- `tensor_product(other)`
  Computes the outer product and returns a matrix.

## Method surface (MoonBit 0.10)

MoonBit 0.10 no longer turns trait implementations into methods implicitly.
Each package lists the trait methods it promotes to method-call syntax in its
`extends.mbt` (`pub extend T with Trait::{method}`); any other trait method is
reached through its operator or a trait-qualified call such as
`Trait::method(x)`. Promotions marked deprecated and hidden from the docs
(`not_equal`, `output`, `to_repr`, `arbitrary`) exist only for source
compatibility; use `!=`, string interpolation, `Repr(x)`, or the quickcheck
trait instead. Indexing is provided by ordinary methods annotated with
`#alias("_[_]")` / `#alias("_[_]=_")`, so `x[i]` and `x.at(i)` (or `x.get(i)`)
are equivalent; the former `op_get` / `op_set` names are gone from the API.

Promoted on `Vector`: `add`, `mul`, `neg`, `equal`, `to_string`. `v[i]` and
`v[i] = x` are `Vector::at(i)` and `Vector::set(i, x)`.

```moonbit check
///|
test "mutable vector indexing and display" {
  let v = @mutable.Vector::from_array([1, 2, 3])
  v[0] = 10
  inspect(v[0], content="10")
  inspect(v.at(1), content="2")
  inspect(v, content="|10, 2, 3|")
  inspect("\{v + v}", content="|20, 4, 6|")
}
```

## Guidance

- Use direct indexing or `*_inplace` helpers when the workload is truly
  mutation-heavy.
- Use the non-`inplace` helpers when you need a fresh vector or want code that
  mirrors `@immut.Vector` more closely.
- `backends/default.DenseVector` is a wrapper around this concrete
  implementation. If you want the trait-oriented default backend entry point,
  see [the `backends/default` API](../backends/default.md).
