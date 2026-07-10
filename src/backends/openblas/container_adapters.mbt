///|
fn check_blas_vector_index(
  length : Int,
  index : Int,
) -> Result[Unit, @la_error.LinearAlgebraError] {
  guard index >= 0 && index < length else {
    return Err(
      @la_error.LinearAlgebraError::index_out_of_bounds(
        "Vector index out of bounds",
      ),
    )
  }
  Ok(())
}

///|
fn check_blas_matrix_index(
  rows : Int,
  cols : Int,
  row : Int,
  col : Int,
) -> Result[Unit, @la_error.LinearAlgebraError] {
  guard row >= 0 && row < rows else {
    return Err(
      @la_error.LinearAlgebraError::index_out_of_bounds(
        "Row index out of bounds",
      ),
    )
  }
  guard col >= 0 && col < cols else {
    return Err(
      @la_error.LinearAlgebraError::index_out_of_bounds(
        "Column index out of bounds",
      ),
    )
  }
  Ok(())
}

///|
/// Checked read capability for an owned OpenBLAS vector.
pub fn[T] blas_vector_read_ops() -> @container.VectorReadOps[BlasVector[T], T] {
  @container.VectorReadOps::new(fn(vector) { vector.length }, fn(
    vector,
    index,
  ) {
    match check_blas_vector_index(vector.length, index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector.data[index])
    }
  })
}

///|
/// Checked build capability for an owned OpenBLAS vector.
pub fn[T : BLASInnerType] blas_vector_build_ops() -> @container.VectorBuildOps[
  BlasVector[T],
  T,
] {
  @container.VectorBuildOps::new(fn(length, initializer) {
    guard length >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension(
          "Vector length must be non-negative",
        ),
      )
    }
    ignore(T::tolerance())
    Ok(BlasVector::from_backend(length, FixedArray::makei(length, initializer)))
  })
}

///|
/// Checked read capability for an owned OpenBLAS matrix.
pub fn[T] blas_matrix_read_ops() -> @container.MatrixReadOps[BlasMatrix[T], T] {
  @container.MatrixReadOps::new(fn(matrix) { (matrix.row, matrix.col) }, fn(
    matrix,
    row,
    col,
  ) {
    match check_blas_matrix_index(matrix.row, matrix.col, row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix.data[row * matrix.col + col])
    }
  })
}

///|
/// Checked build capability for an owned OpenBLAS matrix.
pub fn[T : BLASInnerType] blas_matrix_build_ops() -> @container.MatrixBuildOps[
  BlasMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new(fn(rows, cols, initializer) {
    guard rows >= 0 && cols >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension(
          "Matrix dimensions must be non-negative",
        ),
      )
    }
    ignore(T::tolerance())
    Ok(
      BlasMatrix::from_backend(
        rows,
        cols,
        FixedArray::makei(rows * cols, fn(index) {
          initializer(index / cols, index % cols)
        }),
      ),
    )
  })
}
