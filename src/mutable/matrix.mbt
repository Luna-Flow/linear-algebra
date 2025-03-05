///|
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
struct Lens[T] {
  set : (Int, T) -> Unit
  get : (Int) -> T
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
pub fn map_row[T](self : Matrix[T], row : Int, f : (T) -> T) -> Unit {
  for i = 0; i < self.col; i = i + 1 {
    let val = self[row][i]
    (self[row].set)(i, f(val))
  }
}

///|
pub fn map_col[T](self : Matrix[T], col : Int, f : (T) -> T) -> Unit {
  for i = 0; i < self.row; i = i + 1 {
    let val = self[i][col]
    (self[i].set)(col, f(val))
  }
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
pub fn Matrix::op_get[T](self : Matrix[T], row : Int) -> Lens[T] {
  {
    set: fn { c, v => self.data[c + self.col * row] = v },
    get: fn { c => self.data[c + self.col * row] },
  }
}

///|
pub fn op_get[T](self : Lens[T], col : Int) -> T {
  (self.get)(col)
}

///|
pub fn Lens::op_set[T](self : Lens[T], col : Int, elem : T) -> Unit {
  (self.set)(col, elem)
}

///|
test "op_set" {
  let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
  inspect!(m[0][1], content="3")
  m[0][1] = 4
  inspect!(m[0][1], content="4")
}

///|
pub fn op_mul[T : @lg.Mul + @lg.Add](
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
      sum += self[r][k] * other[k][c]
    }
    sum
  })
  { row, col, data }
}

///|
pub fn op_add[T : @lg.Add](self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  guard self.col == other.col
  guard self.row == other.row
  {
    data: array_zip_with(self.data, other.data, T::op_add),
    row: self.row,
    col: self.col,
  }
}

///|
pub fn op_neg[T : @lg.Neg](self : Matrix[T]) -> Matrix[T] {
  self.map(T::op_neg)
}

///|
pub fn op_sub[T : @lg.Add + @lg.Neg](
  self : Matrix[T],
  other : Matrix[T]
) -> Matrix[T] {
  self + -other
}

///|
pub fn scale[T : @lg.Mul](self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x * cst })
}

///|
pub fn add_constant[T : @lg.Add](self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x + cst })
}

///|
pub fn identity[T : @lg.One + @lg.Zero](size : Int) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
pub fn null[T : Compare + @lg.Zero](self : Matrix[T]) -> Bool {
  not(self.data.iter().any(fn(x) { x != T::zero() }))
}

///|
pub fn adjoint[T : @lg.Conjugate](self : Matrix[T]) -> Matrix[T] {
  self.map(T::conjugate)
}

///|
pub fn transpose[T](self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) { self[j][i] })
}

///|
pub fn swap_rows[T](self : Matrix[T], r1 : Int, r2 : Int) -> Unit {
  let r = self.row
  let c = self.col
  guard r1 < r && r2 < r && r1 >= 0 && r2 >= 0
  if r1 == r2 {
    return
  }
  let temp = Array::makei(c, fn(i) { self[r1][i] })
  for i = 0; i < c; i = i + 1 {
    (self[r1].set)(i, self[r2][i])
  }  
  for i = 0; i < c; i = i + 1 {
    (self[r2].set)(i, temp[i])
  }
}

///|
pub fn swap_cols[T](self : Matrix[T], c1 : Int, c2 : Int) -> Matrix[T] {
  let r = self.row
  let c = self.col
  guard c1 < c && c2 < c && c1 >= 0 && c2 >= 0
  if c1 == c2 {
    return self
  }
  let temp = Array::makei(r, fn(i) { self[i][c1] })
  for i = 0; i < r; i = i + 1 {
    (self[i].set)(c1, self[i][c2])
  }
  for i = 0; i < r; i = i + 1 {
    (self[i].set)(c2, temp[i])
  }
  self
}

test "swap" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  inspect!(m.swap_rows(0, 1), content="|4, 5, 6|\n|1, 2, 3|")
  inspect!(m.swap_cols(0, 1), content="|5, 4, 6|\n|2, 1, 3|")
}

///|
pub fn pow[T : @lg.Semiring](self : Matrix[T], power : Int) -> Matrix[T] {
  loop identity(self.col), power, self {
    s, 0, _ => s
    s, 1, m => s * m
    s, p, m => continue if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m
  }
}

///|
pub fn reduce_row_elimination[T : Compare + @lg.Mul + @lg.Add + @lg.One + @lg.Neg + @lg.Sub + @lg.Inverse + @lg.Zero](self : Matrix[T]) -> Matrix[T] {
  let r = self.row
  let c = self.col
  let mut col = 0
  for i = 0; i < r; i = i + 1 {
    if col >= c {
      break
    }
    let mut max_row = i
    for j = i + 1; j < r; j = j + 1 {
      if self[j][col] > self[max_row][col] {
        max_row = j
      }
    }
    self.swap_rows(i, max_row)
    if self[i][col] == T::zero() {
      col = col + 1
      continue
    }
    let val = self[i][col]
    self.map_row(i, fn(x) { x * val.inv() })
    for j = 0; j < r; j = j + 1 {
      if j == i {
        continue
      }
      let factor = self[j][col]
      for k = 0; k < c; k = k + 1 {
        self[j][k] = self[j][k] - self[i][k] * factor
      }
    }
    col = col + 1
  }
  self
}

test "reduce_row_elimination" {
  let m = Matrix::from_2d_array([[1.0, 2.0, 3.0], [1.0, 1.0, 1.0], [2.0, 3.0, 3.0]])
  inspect!(m.reduce_row_elimination(), content=
    #||1, 0, 0|
    #||0, 1, 0|
    #||0, 0, 1|
  )
}