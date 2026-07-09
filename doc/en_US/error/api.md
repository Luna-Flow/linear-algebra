# `linear-algebra/error`

API baseline for `Luna-Flow/linear-algebra/error` in the current `0.4.2`
repository state.

## Purpose

`error` provides the structured error type used by checked linear-algebra APIs.
The package lets callers distinguish shape errors, invalid domains, singular
matrices, unsupported backends, reserved-but-not-yet-implemented backends, and
arithmetic failures without parsing abort messages.

## `LinearAlgebraErrorKind`

```moonbit check
///|
test "LinearAlgebraErrorKind distinguishes failure categories" {
  let kind = @la_error.LinearAlgebraError::singular_matrix("matrix is singular").kind
  let label = match kind {
    @la_error.LinearAlgebraErrorKind::SingularMatrix => "singular"
    _ => "other"
  }
  inspect(label, content="singular")
}
```

The enum classifies the failure. `ArithmeticFailure` wraps the upstream
`Luna-Flow/arithmetic.ArithmeticError`.

## `LinearAlgebraError`

```moonbit check
///|
test "LinearAlgebraError stores kind and message" {
  let err = @la_error.LinearAlgebraError::singular_matrix("matrix is singular")
  inspect(err.is_singular_matrix(), content="true")
  inspect(err.message, content="matrix is singular")
}
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
- `LinearAlgebraError::backend_not_impl(message)`
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
- `is_backend_not_impl()`
- `is_arithmetic_failure()`

These methods are intended for matching common checked API failures without
destructuring the error value.

`unsupported_backend` and `backend_not_impl` are intentionally distinct.
Use `unsupported_backend` when a backend is outside the supported contract.
Use `backend_not_impl` when the API already reserves a backend selector such as
`BlasBackend`, but the current repository state has not wired it yet.

## Usage

```moonbit check
///|
test "checked callers can branch on structured linear-algebra errors" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let status = match matrix.inverse() {
    Ok(_) => "ok"
    Err(err) => if err.is_singular_matrix() { "singular" } else { "other" }
  }
  inspect(status, content="singular")
}
```

## Boundary

This package defines error values only. It does not implement matrix algorithms,
numeric recovery strategies, logging, or formatting policy.
