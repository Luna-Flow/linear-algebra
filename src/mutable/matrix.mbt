///|
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
pub fn Matrix::make[A](row : Int, col : Int, f : (Int, Int) -> A) -> Matrix[A] {
  ...
}
