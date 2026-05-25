///|
/// Shared matrix type for all mutable backends.
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
pub impl[T] HasShape for Matrix[T] with shape(self) {
  (self.row, self.col)
}

///|
struct Lens[T] {
  data : Matrix[T]
  fst : Int
  offset : Int
  is_transpose : Bool
}
