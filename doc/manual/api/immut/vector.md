# `@immut.Vector`

API baseline for `@immut.Vector` in the current `0.5.0` repository state.

## Overview

- `@immut.Vector` is the repository's value-oriented vector type.
- The public type is also exported under the package alias `VecLib[T]`.
- Storage is backed by the immutable core vector alias `VecCore[T]`.
- Operations such as `set`, `map`, `left_scale`, and `right_scale` always
  return a new vector.
- The package does not expose in-place updates or a dot-product helper.

## Core API

- `Vector::from_array(arr)`
  Builds a vector from a mutable `Array[T]`.
- `Vector::make(n, elem)` / `Vector::makei(n, f)`
  Create a constant vector or generate one from indices.
- `length()`
  Returns the vector length.
- `v[i]`
  Reads one element. Bounds follow the underlying immutable vector contract.
- `set(i, x)`
  Returns a new vector with one replaced element.
- `iter()`
  Exposes an iterator over the elements in order.

## Value transforms

- `map(f)` / `zip_with(other, f)`
  Return transformed vectors without mutating the original.
- `add_constant(cst)`
  Adds the same scalar to every element.
- `left_scale(scalar)` / `right_scale(scalar)`
  Apply scalar multiplication and return a new vector.
- `lerp(other, alpha)`
  Computes `(1 - alpha) * self + alpha * other`.
- `+`, `*`, unary `-`
  Element-wise addition, Hadamard multiplication, and negation.
- `lin_comb(scalar_a, self, scalar_b, other)`
  Top-level helper for a two-vector linear combination.

Length mismatches for shared element-wise operations follow the underlying
vector contract and abort.

## Matrix conversions

- `to_col_matrix()` / `to_row_matrix()`
  Materialize the vector as an `n x 1` or `1 x n` matrix.
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

Promoted on `Vector`: `add`, `mul`, `neg` (`+`, element-wise `*`, unary `-`),
`equal`, `to_string`. `v[i]` is `Vector::at(i)`.

## Guidance

- Use `@immut.Vector` when downstream code benefits from explicit value
  semantics.
- Use `@mutable.Vector` instead when you need in-place updates or the public
  `dot()` helper.
- `backends/default.ImmutableDenseVector` is a wrapper around this concrete
  implementation. If you want the trait-oriented default backend entry point,
  see [the `backends/default` API](../backends/default.md).
