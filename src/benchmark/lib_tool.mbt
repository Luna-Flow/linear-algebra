///|
pub fn[T] lib_naive_matrix_each_row_col(
  m : Matrix[T],
  f : (Int, Int, T) -> Unit,
) -> Unit {
  let row = m.row()
  let col = m.col()
  for i = 0; i < row; i = i + 1 {
    let row_lens = m[i]
    for j = 0; j < col; j = j + 1 {
      f(i, j, row_lens[j])
    }
  }
}

///|
pub fn[T, U] lib_naive_matrix_mapi(
  m : Matrix[T],
  f : (Int, Int, T) -> U,
) -> Matrix[U] {
  Matrix::make(m.row(), m.col(), fn(i, j) { f(i, j, m[i][j]) })
}

///|
pub fn[T] lib_naive_matrix_map_inplace(m : Matrix[T], f : (T) -> T) -> Unit {
  let row = m.row()
  let col = m.col()
  for i = 0; i < row; i = i + 1 {
    for j = 0; j < col; j = j + 1 {
      m[i][j] = f(m[i][j])
    }
  }
}
