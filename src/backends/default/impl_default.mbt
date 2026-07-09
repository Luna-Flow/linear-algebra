///|
pub impl[T : Add] Add for DenseVector[T] with fn add(left, right) {
  DenseVector::from_backend(left.inner + right.inner)
}

///|
pub impl[T : Neg] Neg for DenseVector[T] with fn neg(value) {
  DenseVector::from_backend(-value.inner)
}

///|
pub impl[T : Add + Neg] Sub for DenseVector[T] with fn sub(left, right) {
  DenseVector::from_backend(left.inner + -right.inner)
}

///|
pub impl[T : Mul] Mul for DenseVector[T] with fn mul(left, right) {
  DenseVector::from_backend(left.inner * right.inner)
}

///|
pub impl[T] @algebra.VectorShape for DenseVector[T] with fn length(self) {
  self.inner.length()
}

///|
pub impl[T : Add + Neg] @algebra.AdditiveVector for DenseVector[T]

///|
pub impl[T : Add + Neg + Mul] @algebra.VecMulVector for DenseVector[T]

///|
pub impl[T : Add] Add for ImmutableDenseVector[T] with fn add(left, right) {
  ImmutableDenseVector::from_backend(left.inner + right.inner)
}

///|
pub impl[T : Neg] Neg for ImmutableDenseVector[T] with fn neg(value) {
  ImmutableDenseVector::from_backend(-value.inner)
}

///|
pub impl[T : Add + Neg] Sub for ImmutableDenseVector[T] with fn sub(left, right) {
  ImmutableDenseVector::from_backend(left.inner + -right.inner)
}

///|
pub impl[T : Mul] Mul for ImmutableDenseVector[T] with fn mul(left, right) {
  ImmutableDenseVector::from_backend(left.inner * right.inner)
}

///|
pub impl[T] @algebra.VectorShape for ImmutableDenseVector[T] with fn length(
  self,
) {
  self.inner.length()
}

///|
pub impl[T : Add + Neg] @algebra.AdditiveVector for ImmutableDenseVector[T]

///|
pub impl[T : Add + Neg + Mul] @algebra.VecMulVector for ImmutableDenseVector[T]

///|
pub impl[T : Add] Add for DenseMatrix[T] with fn add(left, right) {
  DenseMatrix::from_backend(left.inner + right.inner)
}

///|
pub impl[T : Neg] Neg for DenseMatrix[T] with fn neg(value) {
  DenseMatrix::from_backend(-value.inner)
}

///|
pub impl[T : Add + Neg] Sub for DenseMatrix[T] with fn sub(left, right) {
  DenseMatrix::from_backend(left.inner + -right.inner)
}

///|
pub impl[T : @lf_alg.AddMonoid + Mul] Mul for DenseMatrix[T] with fn mul(
  left,
  right,
) {
  DenseMatrix::from_backend(left.inner * right.inner)
}

///|
pub impl[T] @algebra.MatrixShape for DenseMatrix[T] with fn shape(self) {
  (self.inner.row(), self.inner.col())
}

///|
pub impl[T] @algebra.TransposeMatrix for DenseMatrix[T] with fn transpose(value) {
  DenseMatrix::from_backend(value.inner.transpose())
}

///|
pub impl[T : Add + Neg] @algebra.AdditiveMatrix for DenseMatrix[T]

///|
pub impl[T : Add + Neg + @lf_alg.AddMonoid + Mul] @algebra.MatMulMatrix for DenseMatrix[
  T,
]

///|
pub impl[T : Add] Add for ImmutableDenseMatrix[T] with fn add(left, right) {
  ImmutableDenseMatrix::from_backend(left.inner + right.inner)
}

///|
pub impl[T : Neg] Neg for ImmutableDenseMatrix[T] with fn neg(value) {
  ImmutableDenseMatrix::from_backend(-value.inner)
}

///|
pub impl[T : Add + Neg] Sub for ImmutableDenseMatrix[T] with fn sub(left, right) {
  ImmutableDenseMatrix::from_backend(left.inner + -right.inner)
}

///|
pub impl[T : Add + @lf_alg.Zero + Mul] Mul for ImmutableDenseMatrix[T] with fn mul(
  left,
  right,
) {
  ImmutableDenseMatrix::from_backend(left.inner * right.inner)
}

///|
pub impl[T] @algebra.MatrixShape for ImmutableDenseMatrix[T] with fn shape(self) {
  (self.inner.row(), self.inner.col())
}

///|
pub impl[T] @algebra.TransposeMatrix for ImmutableDenseMatrix[T] with fn transpose(
  value,
) {
  ImmutableDenseMatrix::from_backend(value.inner.transpose())
}

///|
pub impl[T : Add + Neg] @algebra.AdditiveMatrix for ImmutableDenseMatrix[T]

///|
pub impl[T : Add + Neg + @lf_alg.Zero + Mul] @algebra.MatMulMatrix for ImmutableDenseMatrix[
  T,
]
