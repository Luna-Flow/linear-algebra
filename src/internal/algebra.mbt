///|
pub(open) trait HasShape {
  shape(Self) -> (Int, Int)
}

///|
pub fn[M : HasShape] ensure_square(matrix : M) -> Unit {
  let (row, col) = HasShape::shape(matrix)
  guard row == col else {
    abort("Matrix must be square")
  }
}

///|
pub fn[M : HasShape] ensure_row_in_bounds(matrix : M, row : Int) -> Unit {
  let (rows, _) = HasShape::shape(matrix)
  guard row >= 0 && row < rows else {
    abort("Row index out of bounds")
  }
}

///|
pub fn[M : HasShape] ensure_col_in_bounds(matrix : M, col : Int) -> Unit {
  let (_, cols) = HasShape::shape(matrix)
  guard col >= 0 && col < cols else {
    abort("Column index out of bounds")
  }
}

///|
pub fn[M : HasShape] ensure_index_in_bounds(
  matrix : M,
  row : Int,
  col : Int,
) -> Unit {
  ensure_row_in_bounds(matrix, row)
  ensure_col_in_bounds(matrix, col)
}

///|
pub fn[A : HasShape, B : HasShape] ensure_same_shape(a : A, b : B) -> Unit {
  guard HasShape::shape(a) == HasShape::shape(b) else {
    abort("Matrix dimensions do not match")
  }
}

///|
pub fn[A : HasShape, B : HasShape] ensure_mul_compatible(a : A, b : B) -> Unit {
  let (_, a_cols) = HasShape::shape(a)
  let (b_rows, _) = HasShape::shape(b)
  guard a_cols == b_rows else {
    abort("Matrix dimensions are not compatible for multiplication")
  }
}
