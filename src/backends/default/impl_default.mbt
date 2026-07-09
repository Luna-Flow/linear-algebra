///|
///|
fn[T : @lf_alg.Zero + Add + Mul] dot_immut_vectors(
  left : @immut.Vector[T],
  right : @immut.Vector[T],
) -> T {
  let len = left.length()
  guard len == right.length() else {
    abort("Vector length mismatch for dot product")
  }
  let mut sum = T::zero()
  for i in 0..<len {
    sum = sum + left[i] * right[i]
  }
  sum
}

///|
fn[T : @lf_alg.Zero + Add + Mul] matvec_immut(
  matrix : @immut.Matrix[T],
  vector : @immut.Vector[T],
) -> @immut.Vector[T] {
  let row = matrix.row()
  let col = matrix.col()
  guard col == vector.length() else {
    abort("Matrix and vector dimensions are not compatible for multiplication")
  }
  @immut.Vector::makei(row, fn(i) {
    let mut sum = T::zero()
    for j in 0..<col {
      sum = sum + matrix[i][j] * vector[j]
    }
    sum
  })
}

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
pub fn[T : Mul] DenseVector::scale(
  self : DenseVector[T],
  scalar : T,
) -> DenseVector[T] {
  DenseVector::from_backend(self.inner.right_scale(scalar))
}

///|
pub fn[T : @lf_alg.AddMonoid + Mul] DenseVector::dot(
  self : DenseVector[T],
  other : DenseVector[T],
) -> T {
  self.inner.dot(other.inner)
}

///|
pub fn[T : Add + Mul] DenseVector::axpy(
  self : DenseVector[T],
  alpha : T,
  other : DenseVector[T],
) -> DenseVector[T] {
  self.scale(alpha) + other
}

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
pub fn[T : Mul] ImmutableDenseVector::scale(
  self : ImmutableDenseVector[T],
  scalar : T,
) -> ImmutableDenseVector[T] {
  ImmutableDenseVector::from_backend(self.inner.right_scale(scalar))
}

///|
pub fn[T : @lf_alg.Zero + Add + Mul] ImmutableDenseVector::dot(
  self : ImmutableDenseVector[T],
  other : ImmutableDenseVector[T],
) -> T {
  dot_immut_vectors(self.inner, other.inner)
}

///|
pub fn[T : Add + Mul] ImmutableDenseVector::axpy(
  self : ImmutableDenseVector[T],
  alpha : T,
  other : ImmutableDenseVector[T],
) -> ImmutableDenseVector[T] {
  self.scale(alpha) + other
}

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
pub fn[T : @lf_alg.AddMonoid + Mul] DenseMatrix::matvec(
  self : DenseMatrix[T],
  vector : DenseVector[T],
) -> DenseVector[T] {
  DenseVector::from_backend(self.inner.unchecked_mul_vec(vector.inner()))
}

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

///|
pub fn[T : Add + @lf_alg.Zero + Mul] ImmutableDenseMatrix::matvec(
  self : ImmutableDenseMatrix[T],
  vector : ImmutableDenseVector[T],
) -> ImmutableDenseVector[T] {
  ImmutableDenseVector::from_backend(matvec_immut(self.inner(), vector.inner()))
}
