///|
pub struct Transpose[T](Matrix[T])

///|
pub fn[T] Transpose::row(self : Transpose[T]) -> Int {
  self.0.col
}

///|
pub fn[T] Transpose::col(self : Transpose[T]) -> Int {
  self.0.row
}

///|
pub fn[T] Transpose::get(self : Transpose[T], row : Int, col : Int) -> T {
  guard row >= 0 && row < self.row() && col >= 0 && col < self.col()
  self.0.data[col][row]
}

///|
pub fn[T] Transpose::set(
  self : Transpose[T],
  row : Int,
  col : Int,
  val : T,
) -> Unit {
  guard row >= 0 && row < self.row() && col >= 0 && col < self.col()
  self.0.data[col][row] = val
}

///|
struct Lens[T] {
  data : Matrix[T]
  col : Int
}

///|
pub fn[T] Lens::op_get(self : Lens[T], row : Int) -> T {
  self.data.get(row, self.col)
}

///|
pub fn[T] Lens::op_set(self : Lens[T], row : Int, val : T) -> Unit {
  self.data.set(row, self.col, val)
}

///|
pub fn[T] Transpose::op_get(self : Transpose[T], row : Int) -> Lens[T] {
  guard row >= 0 && row < self.row()
  { data: self.0, col: row }
}

///|
pub impl[T : Show] Show for Transpose[T] with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
pub impl[T : Show] Show for Transpose[T] with output(self, logger) {
  for i in 0..<self.row() {
    logger.write_char('|')
    self.eachi_row(i, fn(c, x) {
      logger.write_object(x)
      if c < self.col() - 1 {
        logger.write_string(", ")
      }
    })
    logger.write_char('|')
    if i < self.row() - 1 {
      logger.write_char('\n')
    }
  }
}

///|
pub impl[T : Add] Add for Transpose[T] with add(a, b) {
  Transpose(a.0 + b.0)
}

///|
pub impl[T : AddMonoid + Mul] Mul for Transpose[T] with mul(a, b) {
  Transpose(b.0 * a.0)
}

///|
pub impl[T : Neg] Neg for Transpose[T] with neg(a) {
  Transpose(-a.0)
}

///|
pub impl[T : Add + Neg] Sub for Transpose[T] with sub(a, b) {
  Transpose(a.0 - b.0)
}

///|
pub impl[T : Eq] Eq for Transpose[T] with equal(a, b) {
  a.0 == b.0
}

///|
pub fn[T] Transpose::each(self : Transpose[T], f : (T) -> Unit) -> Unit {
  self.0.each(f)
}

///|
pub fn[T] Transpose::eachi(self : Transpose[T], f : (Int, T) -> Unit) -> Unit {
  let mut idx = 0
  for i in 0..<self.row() {
    for j in 0..<self.col() {
      // Transpose[i][j] maps to Matrix[j][i]
      // Matrix uses Array[Array], so matrix.data[j][i].
      f(idx, self.0.data[j][i])
      idx += 1
    }
  }
}

///|
pub fn[T] Transpose::each_row(
  self : Transpose[T],
  row : Int,
  f : (T) -> Unit,
) -> Unit {
  self.0.each_col(row, f)
}

///|
pub fn[T] Transpose::eachi_row(
  self : Transpose[T],
  row : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  self.0.eachi_col(row, f)
}

///|
pub fn[T] Transpose::each_col(
  self : Transpose[T],
  col : Int,
  f : (T) -> Unit,
) -> Unit {
  self.0.each_row(col, f)
}

///|
pub fn[T] Transpose::eachi_col(
  self : Transpose[T],
  col : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  self.0.eachi_row(col, f)
}

///|
pub fn[T] Transpose::each_row_col(
  self : Transpose[T],
  f : (Int, Int, T) -> Unit,
) -> Unit {
  self.0.each_row_col(fn(matrix_row, matrix_col, v) {
    f(matrix_col, matrix_row, v)
  })
}

///|
pub fn[T] Transpose::copy(self : Transpose[T]) -> Transpose[T] {
  Transpose(self.0.copy())
}

///|
pub fn[T] Transpose::transpose(self : Transpose[T]) -> Matrix[T] {
  self.0
}

///|
pub fn[T] Transpose::map(self : Transpose[T], f : (T) -> T) -> Transpose[T] {
  Transpose(self.0.map(f))
}

///|
#alias(map_in_place, deprecated)
pub fn[T] Transpose::map_inplace(self : Transpose[T], f : (T) -> T) -> Unit {
  self.0.map_inplace(f)
}

///|
#alias(map_col_in_place, deprecated)
pub fn[T] Transpose::map_col_inplace(
  self : Transpose[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_row_inplace(col, f)
}

///|
#alias(map_row_in_place, deprecated)
pub fn[T] Transpose::map_row_inplace(
  self : Transpose[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_col_inplace(row, f)
}

///|
pub fn[T] Transpose::row_to_array(self : Transpose[T], row : Int) -> Array[T] {
  self.0.col_to_array(row)
}

///|
pub fn[T] Transpose::col_to_array(self : Transpose[T], col : Int) -> Array[T] {
  self.0.row_to_array(col)
}

///|
pub fn[T] Transpose::row_to_vector(self : Transpose[T], row : Int) -> Vector[T] {
  self.0.col_to_vector(row)
}

///|
pub fn[T] Transpose::col_to_vector(self : Transpose[T], col : Int) -> Vector[T] {
  self.0.row_to_vector(col)
}

///|
pub fn[T : Add] Transpose::add_constant(
  self : Transpose[T],
  cst : T,
) -> Transpose[T] {
  Transpose(self.0.add_constant(cst))
}

///|
pub fn[T : Mul] Transpose::scale(self : Transpose[T], cst : T) -> Transpose[T] {
  Transpose(self.0.scale(cst))
}

///|
pub fn[T] Transpose::swap_rows(self : Transpose[T], r1 : Int, r2 : Int) -> Unit {
  self.0.swap_cols(r1, r2)
}

///|
pub fn[T] Transpose::swap_cols(self : Transpose[T], c1 : Int, c2 : Int) -> Unit {
  self.0.swap_rows(c1, c2)
}

///|
pub fn[T] Transpose::horizontal_combine(
  self : Transpose[T],
  other : Transpose[T],
) -> Transpose[T] {
  Transpose(self.0.vertical_combine(other.0))
}

///|
pub fn[T] Transpose::vertical_combine(
  self : Transpose[T],
  other : Transpose[T],
) -> Transpose[T] {
  Transpose(self.0.horizontal_combine(other.0))
}

///|
pub fn[T] Transpose::materialize(self : Transpose[T]) -> Matrix[T] {
  self.0.transpose()
}
