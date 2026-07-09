///|
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
  BackendNotImpl
  ArithmeticFailure(@arith.ArithmeticError)
} derive(Eq)

///|
pub struct LinearAlgebraError {
  kind : LinearAlgebraErrorKind
  message : String
} derive(Eq)

///|
pub fn LinearAlgebraError::dimension_mismatch(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::DimensionMismatch, message }
}

///|
pub fn LinearAlgebraError::index_out_of_bounds(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::IndexOutOfBounds, message }
}

///|
pub fn LinearAlgebraError::negative_dimension(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::NegativeDimension, message }
}

///|
pub fn LinearAlgebraError::invalid_length(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::InvalidLength, message }
}

///|
pub fn LinearAlgebraError::ragged_rows(message : String) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::RaggedRows, message }
}

///|
pub fn LinearAlgebraError::non_square_matrix(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::NonSquareMatrix, message }
}

///|
pub fn LinearAlgebraError::negative_exponent(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::NegativeExponent, message }
}

///|
pub fn LinearAlgebraError::empty_matrix(message : String) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::EmptyMatrix, message }
}

///|
pub fn LinearAlgebraError::singular_matrix(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::SingularMatrix, message }
}

///|
pub fn LinearAlgebraError::non_convergence(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::NonConvergence, message }
}

///|
pub fn LinearAlgebraError::unsupported_backend(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::UnsupportedBackend, message }
}

///|
pub fn LinearAlgebraError::backend_not_impl(
  message : String,
) -> LinearAlgebraError {
  { kind: LinearAlgebraErrorKind::BackendNotImpl, message }
}

///|
pub fn LinearAlgebraError::arithmetic_failure(
  error : @arith.ArithmeticError,
) -> LinearAlgebraError {
  {
    kind: LinearAlgebraErrorKind::ArithmeticFailure(error),
    message: "Arithmetic operation failed",
  }
}

///|
pub fn LinearAlgebraError::is_dimension_mismatch(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::DimensionMismatch => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_index_out_of_bounds(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::IndexOutOfBounds => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_negative_dimension(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::NegativeDimension => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_invalid_length(self : LinearAlgebraError) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::InvalidLength => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_ragged_rows(self : LinearAlgebraError) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::RaggedRows => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_non_square_matrix(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::NonSquareMatrix => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_negative_exponent(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::NegativeExponent => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_empty_matrix(self : LinearAlgebraError) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::EmptyMatrix => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_singular_matrix(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::SingularMatrix => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_non_convergence(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::NonConvergence => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_unsupported_backend(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::UnsupportedBackend => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_backend_not_impl(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::BackendNotImpl => true
    _ => false
  }
}

///|
pub fn LinearAlgebraError::is_arithmetic_failure(
  self : LinearAlgebraError,
) -> Bool {
  match self.kind {
    LinearAlgebraErrorKind::ArithmeticFailure(_) => true
    _ => false
  }
}
