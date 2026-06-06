///|
pub fn[T] Matrix::row_view(self : Matrix[T], row : Int) -> RowView[T] {
  ignore(self.matrix_row_offset(row))
  { data: self, row }
}

///|
pub fn[T] Matrix::col_view(self : Matrix[T], col : Int) -> ColView[T] {
  { data: self, col: self.matrix_checked_col(col) }
}

///|
pub fn[T] RowView::length(self : RowView[T]) -> Int {
  self.data.col()
}

///|
pub fn[T] ColView::length(self : ColView[T]) -> Int {
  self.data.row()
}

///|
pub fn[T] RowView::get(self : RowView[T], col : Int) -> T {
  self.data.get(self.row, col)
}

///|
pub fn[T] ColView::get(self : ColView[T], row : Int) -> T {
  self.data.get(row, self.col)
}

///|
pub fn[T] RowView::set(self : RowView[T], col : Int, val : T) -> Unit {
  self.data.set(self.row, col, val)
}

///|
pub fn[T] ColView::set(self : ColView[T], row : Int, val : T) -> Unit {
  self.data.set(row, self.col, val)
}

///|
pub fn[T] RowView::op_get(self : RowView[T], col : Int) -> T {
  self.get(col)
}

///|
pub fn[T] ColView::op_get(self : ColView[T], row : Int) -> T {
  self.get(row)
}

///|
pub fn[T] RowView::op_set(self : RowView[T], col : Int, val : T) -> Unit {
  self.set(col, val)
}

///|
pub fn[T] ColView::op_set(self : ColView[T], row : Int, val : T) -> Unit {
  self.set(row, val)
}

///|
pub fn[T] RowView::iter(self : RowView[T]) -> Iter[T] {
  self.data.iter_row(self.row)
}

///|
pub fn[T] ColView::iter(self : ColView[T]) -> Iter[T] {
  self.data.iter_col(self.col)
}

///|
pub fn[T] RowView::to_array(self : RowView[T]) -> Array[T] {
  self.data.row_to_array(self.row)
}

///|
pub fn[T] ColView::to_array(self : ColView[T]) -> Array[T] {
  self.data.col_to_array(self.col)
}

///|
pub fn[T] RowView::to_vector(self : RowView[T]) -> Vector[T] {
  self.data.row_to_vector(self.row)
}

///|
pub fn[T] ColView::to_vector(self : ColView[T]) -> Vector[T] {
  self.data.col_to_vector(self.col)
}

///|
pub fn[T] RowView::each(self : RowView[T], f : (T) -> Unit) -> Unit {
  self.data.each_row(self.row, f)
}

///|
pub fn[T] ColView::each(self : ColView[T], f : (T) -> Unit) -> Unit {
  self.data.each_col(self.col, f)
}

///|
pub fn[T] RowView::eachi(self : RowView[T], f : (Int, T) -> Unit) -> Unit {
  self.data.eachi_row(self.row, f)
}

///|
pub fn[T] ColView::eachi(self : ColView[T], f : (Int, T) -> Unit) -> Unit {
  self.data.eachi_col(self.col, f)
}

///|
pub fn[T] RowView::map_inplace(self : RowView[T], f : (T) -> T) -> Unit {
  self.data.map_row_inplace(self.row, f)
}

///|
pub fn[T] ColView::map_inplace(self : ColView[T], f : (T) -> T) -> Unit {
  self.data.map_col_inplace(self.col, f)
}

///|
pub impl[T : Show] Show for RowView[T] with fn to_string(self) {
  self.to_vector().to_string()
}

///|
pub impl[T : Show] Show for ColView[T] with fn to_string(self) {
  self.to_vector().to_string()
}
