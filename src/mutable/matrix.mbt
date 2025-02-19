///|
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
struct Indexed[T] {
  index : (Int) -> T
}

///|
pub impl[T : Show] Show for Matrix[T] with to_string(s) {
  let mut res = ""
  for i = 0; i < s.row; i = i + 1 {
    res = res + "|"
    for j = 0; j < s.col; j = j + 1 {
      res = res + s.data[i * s.col + j].to_string()
      if j < s.col - 1 {
        res = res + ", "
      }
    }
    res = res + "|"
    if i < s.row - 1 {
      res = res + "\n"
    }
  }
  res
}

///|
pub impl[T : Show] Show for Matrix[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
pub fn map[T, U](self : Matrix[T], f : (T) -> U) -> Matrix[U] {
  { row: self.row, col: self.col, data: self.data.map(f) }
}

///|
pub fn Matrix::make[A](row : Int, col : Int, f : (Int, Int) -> A) -> Matrix[A] {
  { row, col, data: Array::makei(row * col, fn(i) { f(i / col, i % col) }) }
}

///|
pub fn Matrix::new[T](row : Int, col : Int, elem : T) -> Matrix[T] {
  Matrix::make(row, col, fn { _, _ => elem })
}

///|
pub fn Matrix::from_2d_array[T](arr : Array[Array[T]]) -> Matrix[T] {
  Matrix::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
}

///|
pub fn Matrix::op_get[T](self : Matrix[T], row : Int) -> Indexed[T] {
  { index: fn { c => self.data[c + self.col * row] } }
}

///|
pub fn op_get[T](self : Indexed[T], col : Int) -> T {
  (self.index)(col)
}

///|
pub fn Matrix::set[T](self : Matrix[T], i : Int, j : Int, elem : T) -> Unit {
  self.data[i * self.col + j] = elem
}

///|
pub fn op_mul[T : @luna_generic.Mul + @luna_generic.Add](
  self : Matrix[T],
  other : Matrix[T]
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row
  let data = Array::makei(row * col, fn(i) {
    let r = i / col
    let c = i % col
    let mut sum = self[r][0] * other[0][c]
    for k = 1; k < inner; k = k + 1 {
      sum = sum + self[r][k] * other[k][c]
    }
    sum
  })
  { row, col, data }
}

///|
pub fn op_add[T : @luna_generic.Add](
  self : Matrix[T],
  other : Matrix[T]
) -> Matrix[T] {
  guard self.col == other.col
  guard self.row == other.row
  {
    data: array_zip_with(self.data, other.data, T::op_add),
    row: self.row,
    col: self.col,
  }
}

///|
pub fn op_neg[T : @luna_generic.Neg](self : Matrix[T]) -> Matrix[T] {
  self.map(T::op_neg)
}

///|
pub fn op_sub[T : @luna_generic.Add + @luna_generic.Neg](
  self : Matrix[T],
  other : Matrix[T]
) -> Matrix[T] {
  self + -other
}

///|
pub fn scale[T : @luna_generic.Mul](self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x * cst })
}

///|
pub fn add_constant[T : @luna_generic.Add](
  self : Matrix[T],
  cst : T
) -> Matrix[T] {
  self.map(fn(x) { x + cst })
}

///|
pub fn identity[T : @luna_generic.One + @luna_generic.Zero](
  size : Int
) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
pub fn null[T : Compare + @luna_generic.Zero](self : Matrix[T]) -> Bool {
  for x in self.data {
    if x != T::zero() {
      break false
    }
  } else {
    true
  }
}

///|
pub fn adjoint[T : @luna_generic.Conjugate](self : Matrix[T]) -> Matrix[T] {
  self.map(T::conjugate)
}

///|
pub fn transpose[T](self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) { self[j][i] })
}
