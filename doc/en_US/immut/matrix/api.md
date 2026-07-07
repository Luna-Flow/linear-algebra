# `@immut.Matrix`

This page documents the current `0.4.1` repository behavior.

## Overview

- `@immut.Matrix` uses value semantics.
- Operations such as `set`, `swap_rows`, and `swap_cols` return a new matrix.
- Matrix storage is row-major and backed by the immutable vector implementation.
- Public indexed access is strict about bounds. `m[row][col]` and `set(row, col, value)` abort on out-of-range indices, including `0xN` and `Nx0` edge shapes.
- `swap_rows(i, i)` and `swap_cols(i, i)` are no-op operations that return the original value unchanged.

## Core Matrix API

- `Matrix::make(row, col, f)`
  Creates a matrix from a generator function. Negative dimensions abort.
- `Matrix::new(row, col, elem)`
  Creates a matrix filled with `elem`. Negative dimensions abort.
- `Matrix::from_2d_array(arr)`
  Creates a matrix from a rectangular 2D array. Ragged input aborts.
- `Matrix::from_array(row, col, data)`
  Builds a matrix from a flat immutable vector in row-major order. Negative dimensions or wrong element count abort.
- `row()` / `col()`
  Return the stored shape.
- `m[row][col]`
  Read-only convenience indexing. Row and column bounds are checked explicitly.
- `set(row, col, elem)`
  Returns a new matrix with one replaced element. Bounds are checked explicitly.
- `map`, `mapi`
  Return transformed matrices without mutating the original.
- `transpose()`
  Returns the materialized transpose.
- `horizontal_combine`, `vertical_combine`
  Concatenate matrices with compatible shapes.
- `iter`, `iter_row`, `iter_col`, `to_array`, `to_2d_array`
  Expose row-major iteration and materialized conversions. Row/column iterators abort on invalid indices.

## Algebraic Operations

- `+`, `-`, `*`
  Addition, subtraction, and matrix multiplication. Shape mismatch aborts.
- `matmul(rhs)`, `trace()`, `determinant()`, `pow(power)`
  Checked APIs return `Result[..., LinearAlgebraError]` for shape or exponent failures.
- `unchecked_matmul(rhs)`, `unchecked_trace()`, `unchecked_determinant()`, `unchecked_pow(power)`
  Preserve the old aborting behavior for callers that explicitly want unchecked operations.
- `scale(cst)`, `add_constant(cst)`, unary `-`
  Element-wise scalar transforms.
- `identity(size)`
  Creates an identity matrix. Negative `size` aborts.
- `trace()`
  Checked sum of diagonal entries. Requires a square matrix.
- `determinant()`
  Checked determinant of a square matrix. Uses the current repository implementation with small-size specializations and elimination for larger inputs.
- `pow(power)`
  Checked square-matrix exponentiation for non-negative integer powers.
- `null()`, `is_square()`
  Shape and zero-matrix helpers.
- `adjoint()`
  Conjugate transpose for element types implementing `Conjugate`.
- `swap_rows(r1, r2)`, `swap_cols(c1, c2)`
  Return a new matrix with the chosen rows or columns swapped. Out-of-range indices abort; same-index swaps leave the value unchanged.

## `MatrixFn`

- `MatrixFn` is the lazy functional companion to `Matrix`.
- It follows the same non-negative-dimension rule.
- `MatrixFn::from_2d_array([])` yields a `0x0` matrix.
- `MatrixFn::from_2d_array([[], ...])` preserves zero-column shapes.
- Ragged input is rejected eagerly.
- Row access validates the row immediately, and element access validates the column through the functional backing contract.

Important methods:

- `MatrixFn::make`, `new`, `from_2d_array`
- `map`, `fold`, `zip_with`
- `transpose`, `horizontal_combine`, `vertical_combine`
- `swap_rows`, `swap_cols`
- `identity`, `pow`, `determinant`, `adjoint`

## Notes On Correctness

- For shared algebraic behavior, prefer the capability traits and the
  `backends/default` wrapper types. `@immut.Matrix` is one dense implementation
  used by the default backend, not the semantic center of the ecosystem.
- The mutable package intentionally exposes extra execution-oriented APIs such as views and in-place updates; those should not be projected back onto `immut`.
