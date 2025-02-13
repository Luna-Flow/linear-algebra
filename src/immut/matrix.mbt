///|
typealias IArray[T] = @immut/array.T[T]

///|
struct Matrix[T] {
  row : Int
  col : Int
  data : IArray[T]
} derive(Eq)

///|
struct Indexed[T] {
  index : (Int) -> Int
  src : IArray[T]
}

///|
impl[T : Show] Show for Matrix[T] with to_string(s) {
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
impl[T : Show] Show for Matrix[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
pub fn map[T, U](self : Matrix[T], f : (T) -> U) -> Matrix[U] {
  { row: self.row, col: self.col, data: self.data.map(f) }
}

///|
pub fn Matrix::make[T](row : Int, col : Int, f : (Int, Int) -> T) -> Matrix[T] {
  {
    row,
    col,
    data: @immut/array.makei(row * col, fn(i) { f(i / col, i % col) }),
  }
}

///|
pub fn Matrix::new[T](row : Int, col : Int, elem : T) -> Matrix[T] {
  Matrix::make(row, col, fn { _, _ => elem })
}

///|
pub fn Matrix::from_2d_array[T](arr : Array[Array[T]]) -> Matrix[T] {
  let data = Matrix::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
  data
}

///|
pub fn Matrix::op_get[T](self : Matrix[T], row : Int) -> Indexed[T] {
  { index: fn { c => c + self.col * row }, src: self.data }
}

///|
pub fn op_get[T](self : Indexed[T], col : Int) -> T {
  self.src[(self.index)(col)]
}

///|
test {
  let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
  inspect!(
    m,
    content=
      #||2, 3, 4|
      #||1, 2, 3|
    ,
  )
  inspect!(m[0][1], content="3")
}

///|
pub fn op_mul[T : Mul + Add](self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row
  let data = @immut/array.makei(row * col, fn(i) {
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
pub fn op_add[T : Add](self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  guard self.col == other.col
  guard self.row == other.row
  let mut i = 0
  let data = self.data.map(fn(x) {
    let r = x + other.data[i]
    i += 1
    r
  })
  { data, row: self.row, col: self.col }
}

///|
pub fn op_neg[T : Neg](self : Matrix[T]) -> Matrix[T] {
  self.map(T::op_neg)
}

///|
pub fn op_sub[T : Add + Neg](self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  self + -other
}

///|
pub fn scale[T : Mul](self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x * cst })
}

///|
pub fn add_constant[T : Add](self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x + cst })
}

///|
pub fn identity[T : One + Zero](size : Int) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
pub fn null[T : Compare + Zero](self : Matrix[T]) -> Bool {
  for x in self.data {
    if x != T::zero() {
      break false
    }
  } else {
    true
  }
}

///|
test {
  let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
  let m3 = m1 * m2
  let m4 = m1 + m2
  inspect!(
    m3,
    content=
      #||1, 2|
      #||3, 4|
    ,
  )
  inspect!(
    m4,
    content=
      #||2, 2|
      #||3, 5|
    ,
  )
  inspect!(
    -m1,
    content=
      #||-1, -2|
      #||-3, -4|
    ,
  )
}
