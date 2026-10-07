# `linear-algebra/error`

API baseline for `Luna-Flow/linear-algebra/error` in the current `0.5.0`
repository state.

## Purpose

`error` provides the structured error type used by checked linear-algebra APIs.
The package lets callers distinguish shape errors, invalid domains, singular
matrices, non-convergence, and arithmetic failures without parsing abort
messages.

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
- `is_arithmetic_failure()`

These methods are intended for matching common checked API failures without
destructuring the error value.

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

`LinearAlgebraErrorKind` and `LinearAlgebraError` promote `equal`, so
`left == right` and `left.equal(right)` both work.

## Boundary

This package defines error values only. It does not implement matrix algorithms,
numeric recovery strategies, logging, or formatting policy.
