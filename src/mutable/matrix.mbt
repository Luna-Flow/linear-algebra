///|
/// Shared matrix type for all mutable backends.
struct Matrix[T] {
  row : Int32
  col : Int32
  data : Array[T]
} derive(Eq)

///|
pub impl[T] HasShape for Matrix[T] with fn shape(self) {
  (self.row, self.col)
}

///|
/// Multiplies two matrices, returning a dimension mismatch instead of aborting.
pub fn[T : AddMonoid + Mul] Matrix::matmul(
  self : Matrix[T],
  other : Matrix[T],
) -> Result[Matrix[T], LinearAlgebraError] {
  match ensure_mul_compatible_checked(self, other) {
    Ok(_) => Ok(self.unchecked_matmul(other))
    Err(err) => Err(err)
  }
}

///|
fn[T] Matrix::matrix_index_offset(
  self : Matrix[T],
  row : Int32,
  col : Int32,
) -> Int32 {
  @internal.ensure_index_in_bounds(self, row, col)
  row * self.col + col
}

///|
fn[T] Matrix::matrix_row_offset(self : Matrix[T], row : Int32) -> Int32 {
  @internal.ensure_row_in_bounds(self, row)
  row * self.col
}

///|
fn[T] Matrix::matrix_checked_col(self : Matrix[T], col : Int32) -> Int32 {
  @internal.ensure_col_in_bounds(self, col)
  col
}

///|
struct Lens[T] {
  data : Matrix[T]
  fst : Int32
  is_transpose : Bool
}
