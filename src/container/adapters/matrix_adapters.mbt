///|
/// Read capability for the immutable dense matrix implementation.
pub fn[T] immutable_matrix_read_ops() -> @container.MatrixReadOps[
  @immut.Matrix[T],
  T,
] {
  @container.MatrixReadOps::new(fn(matrix) { (matrix.row(), matrix.col()) }, fn(
    matrix,
    row,
    col,
  ) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix[row][col])
    }
  })
}

///|
/// Build capability for the immutable dense matrix implementation.
pub fn[T] immutable_matrix_build_ops() -> @container.MatrixBuildOps[
  @immut.Matrix[T],
  T,
] {
  @container.MatrixBuildOps::new(fn(rows, cols, initializer) {
    match check_matrix_shape(rows, cols) {
      Err(error) => Err(error)
      Ok(_) => Ok(@immut.Matrix::make(rows, cols, initializer))
    }
  })
}

///|
/// Persistent edit capability for the immutable dense matrix implementation.
pub fn[T] immutable_matrix_persistent_edit_ops() -> @container.MatrixPersistentEditOps[
  @immut.Matrix[T],
  T,
] {
  @container.MatrixPersistentEditOps::new(fn(matrix, row, col, value) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix.set(row, col, value))
    }
  })
}

///|
/// Read capability for the mutable dense matrix implementation.
pub fn[T] mutable_matrix_read_ops() -> @container.MatrixReadOps[
  @mutable.Matrix[T],
  T,
] {
  @container.MatrixReadOps::new(fn(matrix) { (matrix.row(), matrix.col()) }, fn(
    matrix,
    row,
    col,
  ) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix.get(row, col))
    }
  })
}

///|
/// Build capability for the mutable dense matrix implementation.
pub fn[T] mutable_matrix_build_ops() -> @container.MatrixBuildOps[
  @mutable.Matrix[T],
  T,
] {
  @container.MatrixBuildOps::new(fn(rows, cols, initializer) {
    match check_matrix_shape(rows, cols) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @mutable.Matrix::from_array(
            rows,
            cols,
            Array::makei(rows * cols, fn(index) {
              initializer(index / cols, index % cols)
            }),
          ),
        )
    }
  })
}

///|
/// Mutable edit capability for the mutable dense matrix implementation.
pub fn[T] mutable_matrix_mutable_edit_ops() -> @container.MatrixMutableEditOps[
  @mutable.Matrix[T],
  T,
] {
  @container.MatrixMutableEditOps::new(fn(matrix, row, col, value) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => {
        matrix.set(row, col, value)
        Ok(())
      }
    }
  })
}

///|
/// Read capability for the default mutable matrix wrapper.
pub fn[T] dense_matrix_read_ops() -> @container.MatrixReadOps[
  @default.DenseMatrix[T],
  T,
] {
  @container.MatrixReadOps::new(fn(matrix) { (matrix.row(), matrix.col()) }, fn(
    matrix,
    row,
    col,
  ) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix.inner().get(row, col))
    }
  })
}

///|
/// Build capability for the default mutable matrix wrapper.
pub fn[T] dense_matrix_build_ops() -> @container.MatrixBuildOps[
  @default.DenseMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new(fn(rows, cols, initializer) {
    match check_matrix_shape(rows, cols) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.DenseMatrix::from_backend(
            @mutable.Matrix::from_array(
              rows,
              cols,
              Array::makei(rows * cols, fn(index) {
                initializer(index / cols, index % cols)
              }),
            ),
          ),
        )
    }
  })
}

///|
/// Mutable edit capability for the default mutable matrix wrapper.
pub fn[T] dense_matrix_mutable_edit_ops() -> @container.MatrixMutableEditOps[
  @default.DenseMatrix[T],
  T,
] {
  @container.MatrixMutableEditOps::new(fn(matrix, row, col, value) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => {
        matrix.inner().set(row, col, value)
        Ok(())
      }
    }
  })
}

///|
/// Read capability for the default immutable matrix wrapper.
pub fn[T] immutable_dense_matrix_read_ops() -> @container.MatrixReadOps[
  @default.ImmutableDenseMatrix[T],
  T,
] {
  @container.MatrixReadOps::new(fn(matrix) { (matrix.row(), matrix.col()) }, fn(
    matrix,
    row,
    col,
  ) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(matrix.inner()[row][col])
    }
  })
}

///|
/// Build capability for the default immutable matrix wrapper.
pub fn[T] immutable_dense_matrix_build_ops() -> @container.MatrixBuildOps[
  @default.ImmutableDenseMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new(fn(rows, cols, initializer) {
    match check_matrix_shape(rows, cols) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.ImmutableDenseMatrix::from_backend(
            @immut.Matrix::make(rows, cols, initializer),
          ),
        )
    }
  })
}

///|
/// Persistent edit capability for the default immutable matrix wrapper.
pub fn[T] immutable_dense_matrix_persistent_edit_ops() -> @container.MatrixPersistentEditOps[
  @default.ImmutableDenseMatrix[T],
  T,
] {
  @container.MatrixPersistentEditOps::new(fn(matrix, row, col, value) {
    match check_matrix_index(matrix.row(), matrix.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.ImmutableDenseMatrix::from_backend(
            matrix.inner().set(row, col, value),
          ),
        )
    }
  })
}

///|
/// Read capability for a mutable transpose view.
pub fn[T] mutable_transpose_read_ops() -> @container.MatrixReadOps[
  @mutable.Transpose[T],
  T,
] {
  @container.MatrixReadOps::new(fn(view) { (view.row(), view.col()) }, fn(
    view,
    row,
    col,
  ) {
    match check_matrix_index(view.row(), view.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => Ok(view.get(row, col))
    }
  })
}

///|
/// Mutable edit capability for a mutable transpose view.
pub fn[T] mutable_transpose_mutable_edit_ops() -> @container.MatrixMutableEditOps[
  @mutable.Transpose[T],
  T,
] {
  @container.MatrixMutableEditOps::new(fn(view, row, col, value) {
    match check_matrix_index(view.row(), view.col(), row, col) {
      Err(error) => Err(error)
      Ok(_) => {
        view.set(row, col, value)
        Ok(())
      }
    }
  })
}
