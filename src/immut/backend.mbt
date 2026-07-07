///|
pub(all) enum MatMulBackend {
  PureBackend
  AutoBackend
  CheckedBackend
  BlasBackend
}

///|
pub fn[T : Mul + Add + Zero] matmul_with(
  backend : MatMulBackend,
  a : Matrix[T],
  b : Matrix[T],
) -> Matrix[T] {
  match backend {
    PureBackend => matmul_pure_impl(a, b)
    AutoBackend => matmul_pure_impl(a, b)
    CheckedBackend => {
      ensure_mul_compatible(a, b)
      matmul_pure_impl(a, b)
    }
    BlasBackend => abort("BlasBackend is not wired yet")
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
