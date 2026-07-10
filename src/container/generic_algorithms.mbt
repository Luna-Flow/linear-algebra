///|
fn negative_vector_length() -> @la_error.LinearAlgebraError {
  @la_error.LinearAlgebraError::negative_dimension(
    "Vector length must be non-negative",
  )
}

///|
fn negative_matrix_shape() -> @la_error.LinearAlgebraError {
  @la_error.LinearAlgebraError::negative_dimension(
    "Matrix dimensions must be non-negative",
  )
}

///|
/// Maps a vector into an independently selected target container and scalar.
pub fn[V1, V2, A, B] vector_map(
  source : V1,
  source_ops : VectorReadOps[V1, A],
  target_ops : VectorBuildOps[V2, B],
  map_element : (A) -> B,
) -> Result[V2, @la_error.LinearAlgebraError] {
  let length = (source_ops.length)(source)
  guard length >= 0 else { return Err(negative_vector_length()) }
  let values = []
  for index in 0..<length {
    match (source_ops.get)(source, index) {
      Ok(value) => values.push(map_element(value))
      Err(error) => return Err(error)
    }
  }
  (target_ops.tabulate)(length, fn(index) { values[index] })
}

///|
/// Converts a vector between storage backends without changing its scalar type.
pub fn[V1, V2, T] vector_convert(
  source : V1,
  source_ops : VectorReadOps[V1, T],
  target_ops : VectorBuildOps[V2, T],
) -> Result[V2, @la_error.LinearAlgebraError] {
  vector_map(source, source_ops, target_ops, fn(value) { value })
}

///|
/// Maps a matrix into an independently selected target container and scalar.
///
/// Values are observed and supplied to the builder in row-major coordinate
/// order. Degenerate shapes retain their exact row and column counts.
pub fn[M1, M2, A, B] matrix_map(
  source : M1,
  source_ops : MatrixReadOps[M1, A],
  target_ops : MatrixBuildOps[M2, B],
  map_element : (A) -> B,
) -> Result[M2, @la_error.LinearAlgebraError] {
  let (rows, cols) = (source_ops.shape)(source)
  guard rows >= 0 && cols >= 0 else { return Err(negative_matrix_shape()) }
  let values = []
  for row in 0..<rows {
    for col in 0..<cols {
      match (source_ops.get)(source, row, col) {
        Ok(value) => values.push(map_element(value))
        Err(error) => return Err(error)
      }
    }
  }
  (target_ops.tabulate)(rows, cols, fn(row, col) { values[row * cols + col] })
}

///|
/// Converts a matrix between storage backends without changing its scalar type.
pub fn[M1, M2, T] matrix_convert(
  source : M1,
  source_ops : MatrixReadOps[M1, T],
  target_ops : MatrixBuildOps[M2, T],
) -> Result[M2, @la_error.LinearAlgebraError] {
  matrix_map(source, source_ops, target_ops, fn(value) { value })
}

///|
/// Transposes a matrix into an independently selected target container.
pub fn[M1, M2, T] matrix_transpose(
  source : M1,
  source_ops : MatrixReadOps[M1, T],
  target_ops : MatrixBuildOps[M2, T],
) -> Result[M2, @la_error.LinearAlgebraError] {
  let (rows, cols) = (source_ops.shape)(source)
  guard rows >= 0 && cols >= 0 else { return Err(negative_matrix_shape()) }
  let values = []
  for row in 0..<rows {
    for col in 0..<cols {
      match (source_ops.get)(source, row, col) {
        Ok(value) => values.push(value)
        Err(error) => return Err(error)
      }
    }
  }
  (target_ops.tabulate)(cols, rows, fn(row, col) { values[col * cols + row] })
}
