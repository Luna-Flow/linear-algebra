///|
/// Numeric scalars backed by OpenBLAS GEMM kernels.
pub trait BLASInnerType : Add + Neg + Mul + Compare + @lf_alg.Zero {
  fn tolerance() -> Self

  fn dot(
    length : Int,
    left : FixedArray[Self],
    right : FixedArray[Self],
  ) -> Self

  fn scal(
    length : Int,
    alpha : Self,
    data : FixedArray[Self],
  ) -> FixedArray[Self]

  fn axpy(
    length : Int,
    alpha : Self,
    x : FixedArray[Self],
    y : FixedArray[Self],
  ) -> FixedArray[Self]

  fn gemm(
    m : Int,
    n : Int,
    k : Int,
    left : FixedArray[Self],
    right : FixedArray[Self],
  ) -> FixedArray[Self]

  fn gemv(
    row : Int,
    col : Int,
    matrix : FixedArray[Self],
    vector : FixedArray[Self],
  ) -> FixedArray[Self]
}

///|
pub struct BlasVector[T] {
  length : Int
  data : FixedArray[T]
} derive(Eq)

///|
pub struct BlasMatrix[T] {
  row : Int
  col : Int
  data : FixedArray[T]
} derive(Eq)

///|
fn[T] copy_fixed_array(data : FixedArray[T]) -> FixedArray[T] {
  FixedArray::makei(data.length(), fn(i) { data[i] })
}

///|
fn[T] BlasVector::from_backend(
  length : Int,
  data : FixedArray[T],
) -> BlasVector[T] {
  guard length >= 0 else {
    abort("Vector length must be non-negative")
  }
  guard data.length() == length else {
    abort("Vector data length does not match shape")
  }
  { length, data }
}

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
pub fn[T : BLASInnerType] BlasVector::from_immut(
  inner : @immut.Vector[T],
) -> BlasVector[T] {
  ignore(T::tolerance())
  { length: inner.length(), data: FixedArray::from_array(inner.iter().to_array()) }
}

///|
pub fn[T : BLASInnerType] BlasVector::from_default(
  inner : @default.ImmutableDenseVector[T],
) -> BlasVector[T] {
  BlasVector::from_immut(inner.inner())
}

///|
pub fn[T : BLASInnerType] BlasVector::from_array(data : Array[T]) -> BlasVector[T] {
  ignore(T::tolerance())
  let fixed = FixedArray::from_array(data)
  { length: fixed.length(), data: fixed }
}

///|
pub fn[T : BLASInnerType] BlasVector::make(
  length : Int,
  value : T,
) -> BlasVector[T] {
  ignore(T::tolerance())
  BlasVector::from_backend(length, FixedArray::make(length, value))
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
pub fn[T] BlasVector::length(self : BlasVector[T]) -> Int {
  self.length
}

///|
pub fn[T] BlasVector::op_get(self : BlasVector[T], index : Int) -> T {
  self.data[index]
}

///|
pub fn[T] BlasVector::to_array(self : BlasVector[T]) -> Array[T] {
  Array::from_fixed_array(self.data)
}

///|
pub fn[T : BLASInnerType] BlasVector::to_immut(
  self : BlasVector[T],
) -> @immut.Vector[T] {
  ignore(T::tolerance())
  @immut.Vector::from_array(self.to_array())
}

///|
pub fn[T : BLASInnerType] BlasVector::to_default(
  self : BlasVector[T],
) -> @default.ImmutableDenseVector[T] {
  @default.ImmutableDenseVector::from_backend(self.to_immut())
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
pub impl BLASInnerType for Float with fn dot(length, left, right) {
  @cblas.cblas_sdot(length, left, 1, right, 1)
}

///|
pub impl BLASInnerType for Float with fn scal(length, alpha, data) {
  let output = copy_fixed_array(data)
  @cblas.cblas_sscal(length, alpha, output, 1)
  output
}

///|
pub impl BLASInnerType for Float with fn axpy(length, alpha, x, y) {
  let output = copy_fixed_array(y)
  @cblas.cblas_saxpy(length, alpha, x, 1, output, 1)
  output
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
pub impl BLASInnerType for Float with fn gemv(row, col, matrix, vector) {
  let output = FixedArray::make(row, 0.0F)
  @cblas.cblas_sgemv(
    @cblas.CblasRowMajor,
    @cblas.CblasNoTrans,
    row,
    col,
    1.0F,
    matrix,
    col,
    vector,
    1,
    0.0F,
    output,
    1,
  )
  output
}

///|
pub impl BLASInnerType for Double with fn tolerance() {
  1.0e-10
}

///|
pub impl BLASInnerType for Double with fn dot(length, left, right) {
  @cblas.cblas_ddot(length, left, 1, right, 1)
}

///|
pub impl BLASInnerType for Double with fn scal(length, alpha, data) {
  let output = copy_fixed_array(data)
  @cblas.cblas_dscal(length, alpha, output, 1)
  output
}

///|
pub impl BLASInnerType for Double with fn axpy(length, alpha, x, y) {
  let output = copy_fixed_array(y)
  @cblas.cblas_daxpy(length, alpha, x, 1, output, 1)
  output
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

///|
pub impl BLASInnerType for Double with fn gemv(row, col, matrix, vector) {
  let output = FixedArray::make(row, 0.0)
  @cblas.cblas_dgemv(
    @cblas.CblasRowMajor,
    @cblas.CblasNoTrans,
    row,
    col,
    1.0,
    matrix,
    col,
    vector,
    1,
    0.0,
    output,
    1,
  )
  output
}
