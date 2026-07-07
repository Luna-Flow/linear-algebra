# `linear-algebra/error`

This page documents the public API exported by `Luna-Flow/linear-algebra/error`
in the current `0.4.0` repository state.

## Purpose

`error` provides the structured error type used by checked linear-algebra APIs.
The package lets callers distinguish shape errors, invalid domains, singular
matrices, unsupported backends, and arithmetic failures without parsing abort
messages.

## `LinearAlgebraErrorKind`

```moonbit
pub enum LinearAlgebraErrorKind {
  DimensionMismatch
  IndexOutOfBounds
  NegativeDimension
  InvalidLength
  RaggedRows
  NonSquareMatrix
  NegativeExponent
  EmptyMatrix
  SingularMatrix
  NonConvergence
  UnsupportedBackend
  ArithmeticFailure(@arithmetic.ArithmeticError)
} derive(Eq)
```

The enum classifies the failure. `ArithmeticFailure` wraps the upstream
`Luna-Flow/arithmetic.ArithmeticError`.

## `LinearAlgebraError`

```moonbit
pub struct LinearAlgebraError {
  kind : LinearAlgebraErrorKind
  message : String
} derive(Eq)
```

The struct stores a machine-readable kind and a human-readable message.

## Constructors

- `LinearAlgebraError::dimension_mismatch(message)`
- `LinearAlgebraError::index_out_of_bounds(message)`
- `LinearAlgebraError::negative_dimension(message)`
- `LinearAlgebraError::invalid_length(message)`
- `LinearAlgebraError::ragged_rows(message)`
- `LinearAlgebraError::non_square_matrix(message)`
- `LinearAlgebraError::negative_exponent(message)`
- `LinearAlgebraError::empty_matrix(message)`
- `LinearAlgebraError::singular_matrix(message)`
- `LinearAlgebraError::non_convergence(message)`
- `LinearAlgebraError::unsupported_backend(message)`
- `LinearAlgebraError::arithmetic_failure(error)`

## Predicates

- `is_dimension_mismatch()`
- `is_index_out_of_bounds()`
- `is_negative_dimension()`
- `is_invalid_length()`
- `is_ragged_rows()`
- `is_non_square_matrix()`
- `is_negative_exponent()`
- `is_empty_matrix()`
- `is_singular_matrix()`
- `is_non_convergence()`
- `is_unsupported_backend()`
- `is_arithmetic_failure()`

These methods are intended for matching common checked API failures without
destructuring the error value.

## Usage

```moonbit
match matrix.inverse() {
  Ok(inv) => inv
  Err(err) => {
    if err.is_singular_matrix() {
      abort("matrix is singular")
    }
    abort("matrix inverse failed")
  }
}
```

## Boundary

This package defines error values only. It does not implement matrix algorithms,
numeric recovery strategies, logging, or formatting policy.
