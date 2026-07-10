///|
fn check_vector_index(
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
fn check_matrix_index(
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
fn check_vector_length(
  length : Int,
) -> Result[Unit, @la_error.LinearAlgebraError] {
  guard length >= 0 else {
    return Err(
      @la_error.LinearAlgebraError::negative_dimension(
        "Vector length must be non-negative",
      ),
    )
  }
  Ok(())
}

///|
fn check_matrix_shape(
  rows : Int,
  cols : Int,
) -> Result[Unit, @la_error.LinearAlgebraError] {
  guard rows >= 0 && cols >= 0 else {
    return Err(
      @la_error.LinearAlgebraError::negative_dimension(
        "Matrix dimensions must be non-negative",
      ),
    )
  }
  Ok(())
}
