# error API

## Purpose

`Luna-Flow/linear-algebra/error` defines `LinearAlgebraError`, the error value
returned by every checked API of this repository, and its classification
`LinearAlgebraErrorKind`. A caller branches on the kind (or on an `is_*`
predicate) and uses the message only for diagnostics.

Source: [`src/error/error.mbt`](../../../src/error/error.mbt). Why checked APIs
return this value is explained in the [error design](../design/error.md).

## Importing

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/error" @la_error,
}
```

The examples on this page write every name with its package prefix, such as
`@la_error.`, instead of a `using` declaration: all pages of this manual
compile into one test package, where the declarations of different pages
would clash. The alias `@la_error` avoids a clash with MoonBit's builtin
`Error` vocabulary.

## Types

### `LinearAlgebraErrorKind`

`LinearAlgebraErrorKind` classifies a failure.

```mbti
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
  ArithmeticFailure(@arithmetic.ArithmeticError)
} derive(Eq)
```

The enum is `pub`: other packages can read and `match` its values but cannot
construct them, not even for a comparison such as `kind == SingularMatrix`.
Build errors with the constructors of `LinearAlgebraError` below and test kinds
with `match` or the `is_*` predicates.

| Kind | Meaning | Produced by |
| --- | --- | --- |
| `DimensionMismatch` | operand shapes are incompatible | `@immut.Matrix::matmul`, `@mutable.Matrix::mul_vec` |
| `IndexOutOfBounds` | a row, column or element index is outside the shape | `container` adapters |
| `NegativeDimension` | a requested shape or length is negative | `container` builders and algorithms |
| `InvalidLength` | a flat buffer has the wrong length | reserved; not produced in this release |
| `RaggedRows` | nested rows have different lengths | reserved; not produced in this release |
| `NonSquareMatrix` | the operation needs a square matrix | `trace`, `determinant`, `pow`, `inverse`, `is_invertible`, `matrix_power` |
| `NegativeExponent` | a matrix power has a negative exponent | `pow`, `matrix_power` |
| `EmptyMatrix` | the operation needs at least one element | `mean`, `variance`, `std_dev`, `max_element`, `min_element` |
| `SingularMatrix` | the matrix is singular within tolerance | `@mutable.Matrix::inverse` |
| `NonConvergence` | an iteration did not converge | reserved; not produced in this release |
| `ArithmeticFailure(e)` | a scalar operation failed with `e` | reserved for callers; not produced in this release |

### `LinearAlgebraErrorKind::equal`

`LinearAlgebraErrorKind::equal` compares two kinds structurally; it backs `==`.

```mbti
pub fn LinearAlgebraErrorKind::equal(Self, Self) -> Bool
```

Two `ArithmeticFailure` kinds are equal when their wrapped `ArithmeticError`
values are equal.

### `LinearAlgebraError`

`LinearAlgebraError` pairs a machine-readable kind with a human-readable
message.

```mbti
pub struct LinearAlgebraError {
  kind : LinearAlgebraErrorKind
  message : String
} derive(Eq)
```

Both fields are readable from other packages. The type implements `Eq` but
neither `Show` nor `Debug`, so print `err.message` rather than the error
itself, and compare errors with `==` or a predicate rather than `inspect`.

### `LinearAlgebraError::equal`

`LinearAlgebraError::equal` compares kind and message; it backs `==`.

```mbti
pub fn LinearAlgebraError::equal(Self, Self) -> Bool
```

Two errors of the same kind with different messages are not equal. Compare
kinds (`a.kind == b.kind`) when the message does not matter.

## Constructors

Each constructor builds an error of one kind with the given message. Library
code in this repository uses them; your own checked helpers can use them too.

### `LinearAlgebraError::dimension_mismatch`

`LinearAlgebraError::dimension_mismatch(message)` builds a `DimensionMismatch`
error.

```mbti
pub fn LinearAlgebraError::dimension_mismatch(String) -> Self
```

### `LinearAlgebraError::index_out_of_bounds`

`LinearAlgebraError::index_out_of_bounds(message)` builds an `IndexOutOfBounds`
error.

```mbti
pub fn LinearAlgebraError::index_out_of_bounds(String) -> Self
```

### `LinearAlgebraError::negative_dimension`

`LinearAlgebraError::negative_dimension(message)` builds a `NegativeDimension`
error.

```mbti
pub fn LinearAlgebraError::negative_dimension(String) -> Self
```

### `LinearAlgebraError::invalid_length`

`LinearAlgebraError::invalid_length(message)` builds an `InvalidLength` error.

```mbti
pub fn LinearAlgebraError::invalid_length(String) -> Self
```

### `LinearAlgebraError::ragged_rows`

`LinearAlgebraError::ragged_rows(message)` builds a `RaggedRows` error.

```mbti
pub fn LinearAlgebraError::ragged_rows(String) -> Self
```

### `LinearAlgebraError::non_square_matrix`

`LinearAlgebraError::non_square_matrix(message)` builds a `NonSquareMatrix`
error.

```mbti
pub fn LinearAlgebraError::non_square_matrix(String) -> Self
```

### `LinearAlgebraError::negative_exponent`

`LinearAlgebraError::negative_exponent(message)` builds a `NegativeExponent`
error.

```mbti
pub fn LinearAlgebraError::negative_exponent(String) -> Self
```

### `LinearAlgebraError::empty_matrix`

`LinearAlgebraError::empty_matrix(message)` builds an `EmptyMatrix` error.

```mbti
pub fn LinearAlgebraError::empty_matrix(String) -> Self
```

### `LinearAlgebraError::singular_matrix`

`LinearAlgebraError::singular_matrix(message)` builds a `SingularMatrix` error.

```mbti
pub fn LinearAlgebraError::singular_matrix(String) -> Self
```

### `LinearAlgebraError::non_convergence`

`LinearAlgebraError::non_convergence(message)` builds a `NonConvergence` error.

```mbti
pub fn LinearAlgebraError::non_convergence(String) -> Self
```

### `LinearAlgebraError::arithmetic_failure`

`LinearAlgebraError::arithmetic_failure(error)` wraps a scalar
`ArithmeticError` in an `ArithmeticFailure` error.

```mbti
pub fn LinearAlgebraError::arithmetic_failure(@arithmetic.ArithmeticError) -> Self
```

The message is always `"Arithmetic operation failed"`; the scalar error's own
message stays inside the kind.

```moonbit check
///|
test "constructors set kind and message" {
  let err = @la_error.LinearAlgebraError::singular_matrix("pivot vanished")
  inspect(err.message, content="pivot vanished")
  let label = match err.kind {
    SingularMatrix => "singular"
    _ => "other"
  }
  inspect(label, content="singular")
  let scalar = @lf_arith.ArithmeticError::division_by_zero("1 / 0")
  let wrapped = @la_error.LinearAlgebraError::arithmetic_failure(scalar)
  inspect(wrapped.message, content="Arithmetic operation failed")
  match wrapped.kind {
    ArithmeticFailure(inner) => inspect(inner.message, content="1 / 0")
    _ => fail("expected an arithmetic failure")
  }
}
```

## Predicates

Each predicate returns `true` exactly when the error has the corresponding
kind. They let callers branch without importing the enum.

### `LinearAlgebraError::is_dimension_mismatch`

`is_dimension_mismatch` tests for `DimensionMismatch`.

```mbti
pub fn LinearAlgebraError::is_dimension_mismatch(Self) -> Bool
```

### `LinearAlgebraError::is_index_out_of_bounds`

`is_index_out_of_bounds` tests for `IndexOutOfBounds`.

```mbti
pub fn LinearAlgebraError::is_index_out_of_bounds(Self) -> Bool
```

### `LinearAlgebraError::is_negative_dimension`

`is_negative_dimension` tests for `NegativeDimension`.

```mbti
pub fn LinearAlgebraError::is_negative_dimension(Self) -> Bool
```

### `LinearAlgebraError::is_invalid_length`

`is_invalid_length` tests for `InvalidLength`.

```mbti
pub fn LinearAlgebraError::is_invalid_length(Self) -> Bool
```

### `LinearAlgebraError::is_ragged_rows`

`is_ragged_rows` tests for `RaggedRows`.

```mbti
pub fn LinearAlgebraError::is_ragged_rows(Self) -> Bool
```

### `LinearAlgebraError::is_non_square_matrix`

`is_non_square_matrix` tests for `NonSquareMatrix`.

```mbti
pub fn LinearAlgebraError::is_non_square_matrix(Self) -> Bool
```

### `LinearAlgebraError::is_negative_exponent`

`is_negative_exponent` tests for `NegativeExponent`.

```mbti
pub fn LinearAlgebraError::is_negative_exponent(Self) -> Bool
```

### `LinearAlgebraError::is_empty_matrix`

`is_empty_matrix` tests for `EmptyMatrix`.

```mbti
pub fn LinearAlgebraError::is_empty_matrix(Self) -> Bool
```

### `LinearAlgebraError::is_singular_matrix`

`is_singular_matrix` tests for `SingularMatrix`.

```mbti
pub fn LinearAlgebraError::is_singular_matrix(Self) -> Bool
```

### `LinearAlgebraError::is_non_convergence`

`is_non_convergence` tests for `NonConvergence`.

```mbti
pub fn LinearAlgebraError::is_non_convergence(Self) -> Bool
```

### `LinearAlgebraError::is_arithmetic_failure`

`is_arithmetic_failure` tests for `ArithmeticFailure(_)`, whatever the wrapped
error.

```mbti
pub fn LinearAlgebraError::is_arithmetic_failure(Self) -> Bool
```

The predicates in use, on errors returned by real checked calls:

```moonbit check
///|
test "predicates classify checked failures" {
  let rect = @mutable.Matrix::from_2d_array([[1.0, 2.0, 3.0]])
  match rect.determinant() {
    Err(e) => inspect(e.is_non_square_matrix(), content="true")
    Ok(_) => fail("a 1x3 matrix has no determinant")
  }
  let singular = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  match singular.inverse() {
    Err(e) => inspect(e.is_singular_matrix(), content="true")
    Ok(_) => fail("the matrix is singular")
  }
  let empty : @mutable.Matrix[Double] = @mutable.Matrix::new(0, 3, 0.0)
  match empty.mean() {
    Err(e) => inspect(e.is_empty_matrix(), content="true")
    Ok(_) => fail("an empty matrix has no mean")
  }
}
```

## Deprecated

| Item | Replacement |
| --- | --- |
| `LinearAlgebraError::not_equal`, `LinearAlgebraErrorKind::not_equal` (method form, hidden from the interface) | the `!=` operator |
