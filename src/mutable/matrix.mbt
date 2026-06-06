///|
/// Shared matrix type for all mutable backends.
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
pub impl[T] HasShape for Matrix[T] with fn shape(self) {
  (self.row, self.col)
}

///|
fn[T] Matrix::matrix_index_offset(
  self : Matrix[T],
  row : Int,
  col : Int,
) -> Int {
  @internal.ensure_index_in_bounds(self, row, col)
  row * self.col + col
}

///|
fn[T] Matrix::matrix_row_offset(self : Matrix[T], row : Int) -> Int {
  @internal.ensure_row_in_bounds(self, row)
  row * self.col
}

///|
fn[T] Matrix::matrix_checked_col(self : Matrix[T], col : Int) -> Int {
  @internal.ensure_col_in_bounds(self, col)
  col
}

///|
struct Lens[T] {
  data : Matrix[T]
  fst : Int
  is_transpose : Bool
}
