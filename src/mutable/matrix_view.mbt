///|
pub struct RowView[T] {
  data : Matrix[T]
  row : Int
  offset : Int
}

///|
pub struct ColView[T] {
  data : Matrix[T]
  col : Int
}
