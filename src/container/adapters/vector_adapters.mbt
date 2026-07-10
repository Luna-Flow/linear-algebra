///|
/// Read capability for the immutable dense vector implementation.
pub fn[T] immutable_vector_read_ops() -> @container.VectorReadOps[
  @immut.Vector[T],
  T,
] {
  @container.VectorReadOps::new(fn(vector) { vector.length() }, fn(
    vector,
    index,
  ) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector[index])
    }
  })
}

///|
/// Build capability for the immutable dense vector implementation.
pub fn[T] immutable_vector_build_ops() -> @container.VectorBuildOps[
  @immut.Vector[T],
  T,
] {
  @container.VectorBuildOps::new(fn(length, initializer) {
    match check_vector_length(length) {
      Err(error) => Err(error)
      Ok(_) => Ok(@immut.Vector::makei(length, initializer))
    }
  })
}

///|
/// Persistent edit capability for the immutable dense vector implementation.
pub fn[T] immutable_vector_persistent_edit_ops() -> @container.VectorPersistentEditOps[
  @immut.Vector[T],
  T,
] {
  @container.VectorPersistentEditOps::new(fn(vector, index, value) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector.set(index, value))
    }
  })
}

///|
/// Read capability for the mutable dense vector implementation.
pub fn[T] mutable_vector_read_ops() -> @container.VectorReadOps[
  @mutable.Vector[T],
  T,
] {
  @container.VectorReadOps::new(fn(vector) { vector.length() }, fn(
    vector,
    index,
  ) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector[index])
    }
  })
}

///|
/// Build capability for the mutable dense vector implementation.
pub fn[T] mutable_vector_build_ops() -> @container.VectorBuildOps[
  @mutable.Vector[T],
  T,
] {
  @container.VectorBuildOps::new(fn(length, initializer) {
    match check_vector_length(length) {
      Err(error) => Err(error)
      Ok(_) => Ok(@mutable.Vector::makei(length, initializer))
    }
  })
}

///|
/// Mutable edit capability for the mutable dense vector implementation.
pub fn[T] mutable_vector_mutable_edit_ops() -> @container.VectorMutableEditOps[
  @mutable.Vector[T],
  T,
] {
  @container.VectorMutableEditOps::new(fn(vector, index, value) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => {
        vector[index] = value
        Ok(())
      }
    }
  })
}

///|
/// Read capability for the default mutable vector wrapper.
pub fn[T] dense_vector_read_ops() -> @container.VectorReadOps[
  @default.DenseVector[T],
  T,
] {
  @container.VectorReadOps::new(fn(vector) { vector.length() }, fn(
    vector,
    index,
  ) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector[index])
    }
  })
}

///|
/// Build capability for the default mutable vector wrapper.
pub fn[T] dense_vector_build_ops() -> @container.VectorBuildOps[
  @default.DenseVector[T],
  T,
] {
  @container.VectorBuildOps::new(fn(length, initializer) {
    match check_vector_length(length) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.DenseVector::from_backend(
            @mutable.Vector::makei(length, initializer),
          ),
        )
    }
  })
}

///|
/// Mutable edit capability for the default mutable vector wrapper.
pub fn[T] dense_vector_mutable_edit_ops() -> @container.VectorMutableEditOps[
  @default.DenseVector[T],
  T,
] {
  @container.VectorMutableEditOps::new(fn(vector, index, value) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => {
        vector.inner()[index] = value
        Ok(())
      }
    }
  })
}

///|
/// Read capability for the default immutable vector wrapper.
pub fn[T] immutable_dense_vector_read_ops() -> @container.VectorReadOps[
  @default.ImmutableDenseVector[T],
  T,
] {
  @container.VectorReadOps::new(fn(vector) { vector.length() }, fn(
    vector,
    index,
  ) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(vector[index])
    }
  })
}

///|
/// Build capability for the default immutable vector wrapper.
pub fn[T] immutable_dense_vector_build_ops() -> @container.VectorBuildOps[
  @default.ImmutableDenseVector[T],
  T,
] {
  @container.VectorBuildOps::new(fn(length, initializer) {
    match check_vector_length(length) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.ImmutableDenseVector::from_backend(
            @immut.Vector::makei(length, initializer),
          ),
        )
    }
  })
}

///|
/// Persistent edit capability for the default immutable vector wrapper.
pub fn[T] immutable_dense_vector_persistent_edit_ops() -> @container.VectorPersistentEditOps[
  @default.ImmutableDenseVector[T],
  T,
] {
  @container.VectorPersistentEditOps::new(fn(vector, index, value) {
    match check_vector_index(vector.length(), index) {
      Err(error) => Err(error)
      Ok(_) =>
        Ok(
          @default.ImmutableDenseVector::from_backend(
            vector.inner().set(index, value),
          ),
        )
    }
  })
}

///|
/// Read capability for a mutable row view.
pub fn[T] mutable_row_view_read_ops() -> @container.VectorReadOps[
  @mutable.RowView[T],
  T,
] {
  @container.VectorReadOps::new(fn(view) { view.length() }, fn(view, index) {
    match check_vector_index(view.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(view.get(index))
    }
  })
}

///|
/// Mutable edit capability for a mutable row view.
pub fn[T] mutable_row_view_mutable_edit_ops() -> @container.VectorMutableEditOps[
  @mutable.RowView[T],
  T,
] {
  @container.VectorMutableEditOps::new(fn(view, index, value) {
    match check_vector_index(view.length(), index) {
      Err(error) => Err(error)
      Ok(_) => {
        view.set(index, value)
        Ok(())
      }
    }
  })
}

///|
/// Read capability for a mutable column view.
pub fn[T] mutable_col_view_read_ops() -> @container.VectorReadOps[
  @mutable.ColView[T],
  T,
] {
  @container.VectorReadOps::new(fn(view) { view.length() }, fn(view, index) {
    match check_vector_index(view.length(), index) {
      Err(error) => Err(error)
      Ok(_) => Ok(view.get(index))
    }
  })
}

///|
/// Mutable edit capability for a mutable column view.
pub fn[T] mutable_col_view_mutable_edit_ops() -> @container.VectorMutableEditOps[
  @mutable.ColView[T],
  T,
] {
  @container.VectorMutableEditOps::new(fn(view, index, value) {
    match check_vector_index(view.length(), index) {
      Err(error) => Err(error)
      Ok(_) => {
        view.set(index, value)
        Ok(())
      }
    }
  })
}
