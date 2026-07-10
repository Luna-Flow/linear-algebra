///|
/// Storage-independent checked observation of a vector.
pub struct VectorReadOps[V, T] {
  length : (V) -> Int
  get : (V, Int) -> Result[T, @la_error.LinearAlgebraError]
}

///|
pub fn[V, T] VectorReadOps::new(
  length : (V) -> Int,
  get : (V, Int) -> Result[T, @la_error.LinearAlgebraError],
) -> VectorReadOps[V, T] {
  { length, get }
}

///|
/// Storage-independent checked construction of a vector.
pub struct VectorBuildOps[V, T] {
  tabulate : (Int, (Int) -> T) -> Result[V, @la_error.LinearAlgebraError]
}

///|
pub fn[V, T] VectorBuildOps::new(
  tabulate : (Int, (Int) -> T) -> Result[V, @la_error.LinearAlgebraError],
) -> VectorBuildOps[V, T] {
  { tabulate, }
}

///|
/// Checked persistent replacement for value-oriented vectors.
///
/// `set` returns a new vector and must not mutate the source through shared
/// backing storage.
pub struct VectorPersistentEditOps[V, T] {
  set : (V, Int, T) -> Result[V, @la_error.LinearAlgebraError]
}

///|
pub fn[V, T] VectorPersistentEditOps::new(
  set : (V, Int, T) -> Result[V, @la_error.LinearAlgebraError],
) -> VectorPersistentEditOps[V, T] {
  { set, }
}

///|
/// Checked in-place replacement for mutable vectors.
///
/// `set` modifies the supplied vector and returns no replacement container.
pub struct VectorMutableEditOps[V, T] {
  set : (V, Int, T) -> Result[Unit, @la_error.LinearAlgebraError]
}

///|
pub fn[V, T] VectorMutableEditOps::new(
  set : (V, Int, T) -> Result[Unit, @la_error.LinearAlgebraError],
) -> VectorMutableEditOps[V, T] {
  { set, }
}
