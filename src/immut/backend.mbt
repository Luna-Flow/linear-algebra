///|
pub(all) enum MatMulBackend {
  PureBackend
  AutoBackend
  CheckedBackend
  BlasBackend
}

///|
fn backend_not_impl_error() -> @la_error.LinearAlgebraError {
  @la_error.LinearAlgebraError::backend_not_impl(
    "BlasBackend is reserved for future backend support and is not wired yet",
  )
}

///|
pub fn[T : Mul + Add + Zero] checked_matmul_with(
  backend : MatMulBackend,
  a : Matrix[T],
  b : Matrix[T],
) -> Result[Matrix[T], @la_error.LinearAlgebraError] {
  match backend {
    PureBackend => Ok(matmul_pure_impl(a, b))
    AutoBackend => Ok(matmul_pure_impl(a, b))
    CheckedBackend =>
      match ensure_mul_compatible_checked(a, b) {
        Ok(_) => Ok(matmul_pure_impl(a, b))
        Err(err) => Err(err)
      }
    BlasBackend => Err(backend_not_impl_error())
  }
}

///|
pub fn[T : Mul + Add + Zero] matmul_with(
  backend : MatMulBackend,
  a : Matrix[T],
  b : Matrix[T],
) -> Matrix[T] {
  match checked_matmul_with(backend, a, b) {
    Ok(product) => product
    Err(err) => abort(err.message)
  }
}

///|
pub fn[T : Mul + Add + Zero] matmul(a : Matrix[T], b : Matrix[T]) -> Matrix[T] {
  matmul_with(PureBackend, a, b)
}

///|
pub fn[T : Mul + Add + Zero] matmul_auto(
  a : Matrix[T],
  b : Matrix[T],
) -> Matrix[T] {
  matmul_with(AutoBackend, a, b)
}
