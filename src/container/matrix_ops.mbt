///|
/// Storage-independent checked observation of a matrix.
pub struct MatrixReadOps[M, T] {
  shape : (M) -> (Int, Int)
  get : (M, Int, Int) -> Result[T, @la_error.LinearAlgebraError]
}

///|
pub fn[M, T] MatrixReadOps::new(
  shape : (M) -> (Int, Int),
  get : (M, Int, Int) -> Result[T, @la_error.LinearAlgebraError],
) -> MatrixReadOps[M, T] {
  { shape, get }
}

///|
/// Storage-independent checked construction of a matrix.
pub struct MatrixBuildOps[M, T] {
  tabulate : (Int, Int, (Int, Int) -> T) -> Result[
    M,
    @la_error.LinearAlgebraError,
  ]
}

///|
pub fn[M, T] MatrixBuildOps::new(
  tabulate : (Int, Int, (Int, Int) -> T) -> Result[
    M,
    @la_error.LinearAlgebraError,
  ],
) -> MatrixBuildOps[M, T] {
  { tabulate, }
}

///|
/// Checked persistent replacement for value-oriented matrices.
///
/// `set` returns a new matrix and must not mutate the source through shared
/// backing storage.
pub struct MatrixPersistentEditOps[M, T] {
  set : (M, Int, Int, T) -> Result[M, @la_error.LinearAlgebraError]
}

///|
pub fn[M, T] MatrixPersistentEditOps::new(
  set : (M, Int, Int, T) -> Result[M, @la_error.LinearAlgebraError],
) -> MatrixPersistentEditOps[M, T] {
  { set, }
}

///|
/// Checked in-place replacement for mutable matrices.
///
/// `set` modifies the supplied matrix and returns no replacement container.
pub struct MatrixMutableEditOps[M, T] {
  set : (M, Int, Int, T) -> Result[Unit, @la_error.LinearAlgebraError]
}

///|
pub fn[M, T] MatrixMutableEditOps::new(
  set : (M, Int, Int, T) -> Result[Unit, @la_error.LinearAlgebraError],
) -> MatrixMutableEditOps[M, T] {
  { set, }
}
