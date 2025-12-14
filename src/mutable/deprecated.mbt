///|
#deprecated("Use Matrix::map_in_place instead")
pub fn[T] Matrix::map_inplace(self : Matrix[T], f : (T) -> T) -> Unit {
  self.data.map_in_place(f)
}

///|
#deprecated("Use Matrix::map_row_in_place instead")
pub fn[T] Matrix::map_row_inplace(
  self : Matrix[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  for i in 0..<self.col {
    self.data[row * self.col + i] = f(self.data[row * self.col + i])
  }
}

///|
#deprecated("Use Matrix::map_col_in_place instead")
pub fn[T] Matrix::map_col_inplace(
  self : Matrix[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  for i in 0..<self.row {
    self.data[i * self.col + col] = f(self.data[i * self.col + col])
  }
}

///|
#deprecated("Use Matrix::map_in_place instead")
pub fn[T] Transpose::map_inplace(self : Transpose[T], f : (T) -> T) -> Unit {
  self.0.map_in_place(f)
}

///|
#deprecated("Use Matrix::map_col_in_place instead")
pub fn[T] Transpose::map_col_inplace(
  self : Transpose[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_row_in_place(col, f)
}

///|
#deprecated("Use Matrix::map_col_in_place instead")
pub fn[T] Transpose::map_row_inplace(
  self : Transpose[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_col_in_place(row, f)
}

///|
#deprecated("Use Vector::map_in_place instead")
pub fn[A] Vector::map_inplace(self : Vector[A], f : (A) -> A) -> Unit {
  self.0.map_in_place(f)
}

///|
#deprecated("Use Vector::left_scale_in_place instead")
pub fn[A : Mul] Vector::left_scale_inplace(
  self : Vector[A],
  scalar : A,
) -> Unit {
  self.map_in_place(x => x * scalar)
}

///|
#deprecated("Use Vector::right_scale_in_place instead")
pub fn[A : Mul] Vector::right_scale_inplace(
  scalar : A,
  self : Vector[A],
) -> Unit {
  self.map_in_place(x => scalar * x)
}
