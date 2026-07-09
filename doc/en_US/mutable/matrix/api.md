# `@mutable.Matrix`

API baseline for `@mutable.Matrix` in the current `0.4.2` repository state.
Square-root-dependent APIs use `Luna-Flow/arithmetic.Sqrt`; `Tolerance`
remains defined by `mutable`.

## Overview

- `@mutable.Matrix` is the repository's execution-oriented matrix type.
- `set`, `swap_rows`, `swap_cols`, `map_inplace`, row/column view updates, and transpose updates modify the underlying matrix in place.
- Public storage is a flat row-major `Array[T]` across backends. Backend-specific files differ in execution tuning, not in the public matrix model.
- Public access is strict about bounds. `get`, `set`, `m[row][col]`, `row_view`, `col_view`, extraction helpers, iterators, and transpose-view access reject out-of-range indices consistently, including zero-row and zero-column edge shapes.
- `swap_rows(i, i)` and `swap_cols(i, i)` leave the matrix unchanged. Out-of-range row or column indices abort explicitly instead of relying on accidental storage access.

## Core Matrix API

- `Matrix::make(row, col, f)`
  Builds a matrix from a generator function. Negative dimensions abort.
- `Matrix::new(row, col, elem)`
  Builds a matrix filled with `elem`. Negative dimensions abort.
- `Matrix::from_2d_array(arr)`
  Creates a matrix from a rectangular 2D array. Ragged input aborts.
- `Matrix::from_array(row, col, data)`
  Uses a flat row-major array as matrix storage. Negative dimensions or wrong element count abort.
- `row()` / `col()`
  Return the stored shape.
- `get(row, col)` / `set(row, col, elem)`
  Fast random access with explicit bounds checks.
- `m[row][col]`
  Convenience syntax backed by `Lens[T]`. It is valid for read and write, but repeated bulk work should prefer `row_view`, `col_view`, or the dedicated row/column helpers.
- `copy()`
  Deep-copies the matrix.
- `map`, `mapi`
  Return a transformed matrix.
- `map_inplace`, `map_row_inplace`, `map_col_inplace`
  Apply in-place transforms.
- `each`, `eachi`, `each_row_col`, `each_row`, `each_col`, `eachi_row`, `eachi_col`
  Traversal helpers.
- `iter`, `iter_row`, `iter_col`
  Iterators with checked row/column bounds.
- `row_to_array`, `col_to_array`, `row_to_vector`, `col_to_vector`, `to_array`, `to_2d_array`, `to_vector`
  Materialization helpers with checked indices where applicable.
- `transpose()`
  Returns a materialized transpose.
- `to_transpose()`
  Returns a live transpose view.
- `horizontal_combine`, `vertical_combine`
  Concatenate compatible matrices.

## Views And Transpose

- `row_view(row)` / `col_view(col)`
  Return live views into the underlying matrix.
- `RowView` and `ColView`
  Expose `get`, `set`, `iter`, `each`, `eachi`, `map_inplace`, `to_array`, and `to_vector`.
- `Transpose`
  Exposes the same matrix-like surface over a live transposed view.
- `Transpose::swap_rows` and `Transpose::swap_cols`
  Delegate to the underlying matrix with the same strict bounds semantics.

## Algebraic And Numeric API

- `+`, `-`, `*`
  Matrix addition, subtraction, and multiplication.
- `scale(cst)`, `add_constant(cst)`, unary `-`
  Element-wise scalar transforms.
- `identity(size)`
  Identity matrix constructor. Negative `size` aborts.
- `pow(power)`
  Checked square-matrix exponentiation for non-negative integer powers.
- `matrix_power(n)`
  Checked public wrapper around `pow(n)`.
- `trace()`
  Checked sum of diagonal entries. Requires a square matrix and returns `Result[..., LinearAlgebraError]`.
- `determinant()`
  Checked determinant of a square matrix.
- `inverse()`, `is_invertible()`
  Checked inversion helpers for square matrices. Singular inverse returns `Err`.
- `mul_vec(vector)`
  Checked matrix-vector multiplication. Shape mismatch returns `Err`.
- `mean()`, `variance()`, `std_dev()`, `max_element()`, `min_element()`
  Checked aggregate helpers. Empty matrices return `Err`.
- `unchecked_trace()`, `unchecked_determinant()`, `unchecked_inverse()`, `unchecked_is_invertible()`, `unchecked_pow()`, `unchecked_matrix_power()`, `unchecked_mul_vec()`, `unchecked_mean()`, `unchecked_variance()`, `unchecked_std_dev()`, `unchecked_max_element()`, `unchecked_min_element()`
  Preserve the old aborting or `Option`-returning behavior.
- `rank()`
  Rank computed through the current repository algorithm.
- `reduce_row_elimination()`
  In-place-style row reduction on the mutable matrix value.
- `cholesky_decomposition()`
  Cholesky factorization for supported numeric inputs.
- `eigen()`, `power_method()`
  Public eigen-related APIs for supported numeric cases. The specialized
  2x2 helper used by the implementation is not part of the public package
  interface.
- `is_square()`, `null()`, `is_symmetric()`, `is_positive_definite()`
  Structural and numeric predicates.
- `frobenius_norm()`
  Non-checked aggregate numeric helper for supported element types.

## Guidance

- Backends are expected to expose the same public semantics. The repository currently keeps separate kernel files for `native`, `js`, `wasm`, and `wasm-gc`, so tests and documentation should be read as backend-invariant unless a note says otherwise.
- For code shared across `immut` and `mutable`, rely on the common algebraic surface and not on identical mutation semantics.
- `backends/default.DenseMatrix` is a wrapper around this concrete
  implementation. If you want the trait-oriented default backend entry point,
  see [the `backends/default` API](../../backends/default/api.md).
