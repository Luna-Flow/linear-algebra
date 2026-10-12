///|
/// Default mutable dense vector backend.
pub struct DenseVector[T] {
  inner : @mutable.Vector[T]
}

///|
/// Default mutable dense matrix backend.
pub struct DenseMatrix[T] {
  inner : @mutable.Matrix[T]
}

///|
/// Default immutable dense vector backend.
pub struct ImmutableDenseVector[T] {
  inner : @immut.Vector[T]
}

///|
/// Default immutable dense matrix backend.
pub struct ImmutableDenseMatrix[T] {
  inner : @immut.Matrix[T]
}

///|
pub fn[T] DenseVector::from_backend(
  inner : @mutable.Vector[T],
) -> DenseVector[T] {
  { inner, }
}

///|
pub fn[T] DenseVector::from_array(data : Array[T]) -> DenseVector[T] {
  { inner: @mutable.Vector::from_array(data), }
}

///|
pub fn[T] DenseVector::make(length : Int32, value : T) -> DenseVector[T] {
  { inner: @mutable.Vector::make(length, value), }
}

///|
pub fn[T] DenseVector::inner(self : DenseVector[T]) -> @mutable.Vector[T] {
  self.inner
}

///|
pub fn[T] DenseVector::length(self : DenseVector[T]) -> Int32 {
  self.inner.length()
}

///|
#alias("_[_]")
pub fn[T] DenseVector::at(self : DenseVector[T], index : Int32) -> T {
  self.inner[index]
}

///|
pub fn[T] DenseMatrix::from_backend(
  inner : @mutable.Matrix[T],
) -> DenseMatrix[T] {
  { inner, }
}

///|
pub fn[T] DenseMatrix::from_2d_array(data : Array[Array[T]]) -> DenseMatrix[T] {
  { inner: @mutable.Matrix::from_2d_array(data), }
}

///|
pub fn[T] DenseMatrix::new(
  row : Int32,
  col : Int32,
  value : T,
) -> DenseMatrix[T] {
  { inner: @mutable.Matrix::new(row, col, value), }
}

///|
pub fn[T] DenseMatrix::inner(self : DenseMatrix[T]) -> @mutable.Matrix[T] {
  self.inner
}

///|
pub fn[T] DenseMatrix::row(self : DenseMatrix[T]) -> Int32 {
  self.inner.row()
}

///|
pub fn[T] DenseMatrix::col(self : DenseMatrix[T]) -> Int32 {
  self.inner.col()
}

///|
pub fn[T] ImmutableDenseVector::from_backend(
  inner : @immut.Vector[T],
) -> ImmutableDenseVector[T] {
  { inner, }
}

///|
pub fn[T] ImmutableDenseVector::from_array(
  data : Array[T],
) -> ImmutableDenseVector[T] {
  { inner: @immut.Vector::from_array(data), }
}

///|
pub fn[T] ImmutableDenseVector::make(
  length : Int32,
  value : T,
) -> ImmutableDenseVector[T] {
  { inner: @immut.Vector::make(length, value), }
}

///|
pub fn[T] ImmutableDenseVector::inner(
  self : ImmutableDenseVector[T],
) -> @immut.Vector[T] {
  self.inner
}

///|
pub fn[T] ImmutableDenseVector::length(self : ImmutableDenseVector[T]) -> Int32 {
  self.inner.length()
}

///|
#alias("_[_]")
pub fn[T] ImmutableDenseVector::at(
  self : ImmutableDenseVector[T],
  index : Int32,
) -> T {
  self.inner[index]
}

///|
pub fn[T] ImmutableDenseMatrix::from_backend(
  inner : @immut.Matrix[T],
) -> ImmutableDenseMatrix[T] {
  { inner, }
}

///|
pub fn[T] ImmutableDenseMatrix::from_2d_array(
  data : Array[Array[T]],
) -> ImmutableDenseMatrix[T] {
  { inner: @immut.Matrix::from_2d_array(data), }
}

///|
pub fn[T] ImmutableDenseMatrix::new(
  row : Int32,
  col : Int32,
  value : T,
) -> ImmutableDenseMatrix[T] {
  { inner: @immut.Matrix::new(row, col, value), }
}

///|
pub fn[T] ImmutableDenseMatrix::inner(
  self : ImmutableDenseMatrix[T],
) -> @immut.Matrix[T] {
  self.inner
}

///|
pub fn[T] ImmutableDenseMatrix::row(self : ImmutableDenseMatrix[T]) -> Int32 {
  self.inner.row()
}

///|
pub fn[T] ImmutableDenseMatrix::col(self : ImmutableDenseMatrix[T]) -> Int32 {
  self.inner.col()
}
