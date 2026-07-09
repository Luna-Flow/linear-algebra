///|
/// Numeric scalars backed by OpenBLAS GEMM kernels.
pub trait BLASInnerType : Add + Neg + Mul + Compare + @lf_alg.Zero {
  fn tolerance() -> Self

  fn gemm(
    m : Int,
    n : Int,
    k : Int,
    left : FixedArray[Self],
    right : FixedArray[Self],
  ) -> FixedArray[Self]
}

///|
pub struct BlasMatrix[T] {
  row : Int
  col : Int
  data : FixedArray[T]
} derive(Eq)

///|
fn[T] BlasMatrix::from_backend(
  row : Int,
  col : Int,
  data : FixedArray[T],
) -> BlasMatrix[T] {
  guard row >= 0 && col >= 0 else {
    abort("Matrix dimensions must be non-negative")
  }
  guard data.length() == row * col else {
    abort("Matrix data length does not match shape")
  }
  { row, col, data }
}

///|
pub fn[T : BLASInnerType] BlasMatrix::from_immut(
  inner : @immut.Matrix[T],
) -> BlasMatrix[T] {
  ignore(T::tolerance())
  {
    row: inner.row(),
    col: inner.col(),
    data: FixedArray::from_array(inner.to_array()),
  }
}

///|
pub fn[T : BLASInnerType] BlasMatrix::from_default(
  inner : @default.ImmutableDenseMatrix[T],
) -> BlasMatrix[T] {
  BlasMatrix::from_immut(inner.inner())
}

///|
pub fn[T : BLASInnerType] BlasMatrix::from_2d_array(
  data : Array[Array[T]],
) -> BlasMatrix[T] {
  BlasMatrix::from_immut(@immut.Matrix::from_2d_array(data))
}

///|
pub fn[T : BLASInnerType] BlasMatrix::new(
  row : Int,
  col : Int,
  value : T,
) -> BlasMatrix[T] {
  ignore(T::tolerance())
  BlasMatrix::from_backend(row, col, FixedArray::make(row * col, value))
}

///|
pub fn[T] BlasMatrix::row(self : BlasMatrix[T]) -> Int {
  self.row
}

///|
pub fn[T] BlasMatrix::col(self : BlasMatrix[T]) -> Int {
  self.col
}

///|
pub fn[T] BlasMatrix::to_array(self : BlasMatrix[T]) -> Array[T] {
  Array::from_fixed_array(self.data)
}

///|
pub fn[T : BLASInnerType] BlasMatrix::to_2d_array(
  self : BlasMatrix[T],
) -> Array[Array[T]] {
  self.to_immut().to_2d_array()
}

///|
pub fn[T : BLASInnerType] BlasMatrix::to_immut(
  self : BlasMatrix[T],
) -> @immut.Matrix[T] {
  ignore(T::tolerance())
  @immut.Matrix::from_array(
    self.row,
    self.col,
    @immut.Vector::from_array(self.to_array()),
  )
}

///|
pub fn[T : BLASInnerType] BlasMatrix::to_default(
  self : BlasMatrix[T],
) -> @default.ImmutableDenseMatrix[T] {
  @default.ImmutableDenseMatrix::from_backend(self.to_immut())
}

///|
pub impl BLASInnerType for Float with fn tolerance() {
  1.0e-4F
}

///|
pub impl BLASInnerType for Float with fn gemm(
  m,
  n,
  k,
  left,
  right,
) {
  let output = FixedArray::make(m * n, 0.0F)
  @cblas.cblas_sgemm(
    @cblas.CblasRowMajor,
    @cblas.CblasNoTrans,
    @cblas.CblasNoTrans,
    m,
    n,
    k,
    1.0F,
    left,
    k,
    right,
    n,
    1.0F,
    output,
    n,
  )
  output
}

///|
pub impl BLASInnerType for Double with fn tolerance() {
  1.0e-10
}

///|
pub impl BLASInnerType for Double with fn gemm(
  m,
  n,
  k,
  left,
  right,
) {
  let output = FixedArray::make(m * n, 0.0)
  @cblas.cblas_dgemm(
    @cblas.CblasRowMajor,
    @cblas.CblasNoTrans,
    @cblas.CblasNoTrans,
    m,
    n,
    k,
    1.0,
    left,
    k,
    right,
    n,
    1.0,
    output,
    n,
  )
  output
}
