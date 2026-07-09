# `@immut.Vector`

API baseline for `@immut.Vector` in the current `0.4.4` repository state.

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

## Value Transforms

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

## Matrix Conversions

- `to_col_matrix()` / `to_row_matrix()`
  Materialize the vector as an `n x 1` or `1 x n` matrix.
- `scaled_matrix()`
  Builds a diagonal matrix with the vector on the main diagonal.
- `tensor_product(other)`
  Computes the outer product and returns a matrix.

## Guidance

- Use `@immut.Vector` when downstream code benefits from explicit value
  semantics.
- Use `@mutable.Vector` instead when you need in-place updates or the public
  `dot()` helper.
- `backends/default.ImmutableDenseVector` is a wrapper around this concrete
  implementation. If you want the trait-oriented default backend entry point,
  see [the `backends/default` API](../../backends/default/api.md).
