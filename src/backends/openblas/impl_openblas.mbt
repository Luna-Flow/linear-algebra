///|
fn[T] transpose_data(
  row : Int,
  col : Int,
  data : FixedArray[T],
) -> FixedArray[T] {
  FixedArray::makei(row * col, fn(i) {
    let out_row = i / row
    let out_col = i % row
    data[out_col * col + out_row]
  })
}

///|
fn[T] map_data(
  data : FixedArray[T],
  f : (T) -> T,
) -> FixedArray[T] {
  FixedArray::makei(data.length(), fn(i) { f(data[i]) })
}

///|
fn[T] zip_data(
  left : FixedArray[T],
  right : FixedArray[T],
  f : (T, T) -> T,
) -> FixedArray[T] {
  FixedArray::makei(left.length(), fn(i) { f(left[i], right[i]) })
}

///|
pub impl[T] @algebra.VectorShape for BlasVector[T] with fn length(self) {
  self.length
}

///|
pub impl[T : BLASInnerType + Show] Show for BlasVector[T] with fn to_string(self) {
  self.to_immut().to_string()
}

///|
pub impl[T : BLASInnerType + Show] Show for BlasVector[T] with fn output(
  self,
  logger,
) {
  self.to_immut().output(logger)
}

///|
pub impl[T : BLASInnerType] Add for BlasVector[T] with fn add(left, right) {
  guard left.length() == right.length() else {
    abort("Vector lengths do not match")
  }
  BlasVector::from_backend(
    left.length(),
    zip_data(left.data, right.data, fn(a, b) { a + b }),
  )
}

///|
pub impl[T : BLASInnerType] Neg for BlasVector[T] with fn neg(value) {
  BlasVector::from_backend(
    value.length(),
    map_data(value.data, fn(elem) { -elem }),
  )
}

///|
pub impl[T : BLASInnerType] Sub for BlasVector[T] with fn sub(left, right) {
  guard left.length() == right.length() else {
    abort("Vector lengths do not match")
  }
  BlasVector::from_backend(
    left.length(),
    zip_data(left.data, right.data, fn(a, b) { a + -b }),
  )
}

///|
pub impl[T : BLASInnerType] @algebra.AdditiveVector for BlasVector[T]

///|
pub fn[T : BLASInnerType] BlasVector::scale(
  self : BlasVector[T],
  scalar : T,
) -> BlasVector[T] {
  BlasVector::from_backend(
    self.length(),
    T::scal(self.length(), scalar, self.data),
  )
}

///|
pub fn[T : BLASInnerType] BlasVector::dot(
  self : BlasVector[T],
  other : BlasVector[T],
) -> T {
  guard self.length() == other.length() else {
    abort("Vector length mismatch for dot product")
  }
  T::dot(self.length(), self.data, other.data)
}

///|
pub fn[T : BLASInnerType] BlasVector::axpy(
  self : BlasVector[T],
  alpha : T,
  other : BlasVector[T],
) -> BlasVector[T] {
  guard self.length() == other.length() else {
    abort("Vector lengths do not match")
  }
  BlasVector::from_backend(
    self.length(),
    T::axpy(self.length(), alpha, self.data, other.data),
  )
}

///|
pub impl[T] @internal.HasShape for BlasMatrix[T] with fn shape(
  self,
) {
  (self.row, self.col)
}

///|
pub impl[T] @algebra.MatrixShape for BlasMatrix[T] with fn shape(
  self,
) {
  (self.row, self.col)
}

///|
pub impl[T : BLASInnerType + Show] Show for BlasMatrix[T] with fn to_string(self) {
  self.to_immut().to_string()
}

///|
pub impl[T : BLASInnerType + Show] Show for BlasMatrix[T] with fn output(
  self,
  logger,
) {
  self.to_immut().output(logger)
}

///|
pub impl[T : BLASInnerType] Add for BlasMatrix[T] with fn add(left, right) {
  @internal.ensure_same_shape(left, right)
  BlasMatrix::from_backend(
    left.row,
    left.col,
    zip_data(left.data, right.data, fn(a, b) { a + b }),
  )
}

///|
pub impl[T : BLASInnerType] Neg for BlasMatrix[T] with fn neg(value) {
  BlasMatrix::from_backend(
    value.row,
    value.col,
    map_data(value.data, fn(elem) { -elem }),
  )
}

///|
pub impl[T : BLASInnerType] Sub for BlasMatrix[T] with fn sub(left, right) {
  @internal.ensure_same_shape(left, right)
  BlasMatrix::from_backend(
    left.row,
    left.col,
    zip_data(left.data, right.data, fn(a, b) { a + -b }),
  )
}

///|
pub impl[T : BLASInnerType] Mul for BlasMatrix[T] with fn mul(left, right) {
  @internal.ensure_mul_compatible(left, right)
  BlasMatrix::from_backend(
    left.row,
    right.col,
    T::gemm(left.row, right.col, left.col, left.data, right.data),
  )
}

///|
pub impl[T : BLASInnerType] @algebra.TransposeMatrix for BlasMatrix[T] with fn transpose(
  value,
) {
  BlasMatrix::from_backend(
    value.col,
    value.row,
    transpose_data(value.row, value.col, value.data),
  )
}

///|
pub impl[T : BLASInnerType] @algebra.AdditiveMatrix for BlasMatrix[T]

///|
pub impl[T : BLASInnerType] @algebra.MatMulMatrix for BlasMatrix[T]

///|
pub fn[T : BLASInnerType] BlasMatrix::matvec(
  self : BlasMatrix[T],
  vector : BlasVector[T],
) -> BlasVector[T] {
  guard self.col() == vector.length() else {
    abort("Matrix and vector dimensions are not compatible for multiplication")
  }
  BlasVector::from_backend(
    self.row(),
    T::gemv(self.row(), self.col(), self.data, vector.data),
  )
}
