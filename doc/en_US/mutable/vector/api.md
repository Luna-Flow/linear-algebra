# `@mutable.Vector`

API baseline for `@mutable.Vector` in the current `0.4.3` repository state.

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

## Value-Producing Helpers

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

## In-Place Helpers

- `map_inplace(f)`
  Rewrites every element in place.
- `left_scale_inplace(scalar)` / `right_scale_inplace(scalar)`
  Apply scalar multiplication in place.

## Scalar And Matrix Helpers

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

## Guidance

- Use direct indexing or `*_inplace` helpers when the workload is truly
  mutation-heavy.
- Use the non-`inplace` helpers when you need a fresh vector or want code that
  mirrors `@immut.Vector` more closely.
- `backends/default.DenseVector` is a wrapper around this concrete
  implementation. If you want the trait-oriented default backend entry point,
  see [the `backends/default` API](../../backends/default/api.md).
