///|
struct MatrixFn[T] {
  data : (Int, Int) -> T
  grid : (Int, Int)
}

///|
pub fn MatrixFn::op_get[T](self : MatrixFn[T], i : Int) -> Indexed[T] {
  { index: fn { c => (self.data)(i, c) } }
}

///|
impl[T : Eq] Eq for MatrixFn[T] with op_equal(self, other) {
  self.zip_with(other, T::op_equal).fold(init=true, fn(acc, x) { acc && x })
}

///|
pub fn MatrixFn::fold[T, U](
  self : MatrixFn[T],
  init~ : U,
  f : (U, T) -> U
) -> U {
  let (r, c) = self.grid
  let mut acc = init
  for i in 0..<r {
    for j in 0..<c {
      acc = f(acc, (self.data)(i, j))
    }
  }
  acc
}

///|
pub fn MatrixFn::new[T : Default](row : Int, col : Int) -> MatrixFn[T] {
  {
    data: fn {
      i, j if 0 <= i && i < row && 0 <= j && j < col => T::default()
      _, _ => abort("Index out of bounds")
    },
    grid: (row, col),
  }
}

///|
pub fn MatrixFn::map[T, U](self : MatrixFn[T], f : (T) -> U) -> MatrixFn[U] {
  { data: fn { i, j => f((self.data)(i, j)) }, grid: self.grid }
}

///|
pub impl[T : Show] Show for MatrixFn[T] with to_string(s) {
  let mut res = ""
  for i in 0..<s.grid.0 {
    res = res + "|"
    for j in 0..<s.grid.1 {
      res = res + (s.data)(i, j).to_string()
      if j < s.grid.1 - 1 {
        res = res + ", "
      }
    }
    res = res + "|"
    if i < s.grid.0 - 1 {
      res = res + "\n"
    }
  }
  res
}

///|
pub impl[T : Show] Show for MatrixFn[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
pub fn MatrixFn::map_row[T](
  self : MatrixFn[T],
  row : Int,
  f : (T) -> T
) -> MatrixFn[T] {
  {
    data: fn {
      i, j => if i == row { f((self.data)(i, j)) } else { (self.data)(i, j) }
    },
    grid: self.grid,
  }
}

///|
pub fn MatrixFn::map_col[T](
  self : MatrixFn[T],
  col : Int,
  f : (T) -> T
) -> MatrixFn[T] {
  {
    data: fn {
      i, j => if j == col { f((self.data)(i, j)) } else { (self.data)(i, j) }
    },
    grid: self.grid,
  }
}

///|
pub fn MatrixFn::transpose[T](self : MatrixFn[T]) -> MatrixFn[T] {
  { data: fn { i, j => (self.data)(j, i) }, grid: (self.grid.1, self.grid.0) }
}

///|
pub fn MatrixFn::make[T](
  row : Int,
  col : Int,
  f : (Int, Int) -> T
) -> MatrixFn[T] {
  { data: f, grid: (row, col) }
}

///|
pub fn MatrixFn::from_2d_array[T](arr : Array[Array[T]]) -> MatrixFn[T] {
  MatrixFn::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
}

///|
impl[T : Add] Add for MatrixFn[T] with op_add(self, other) {
  self.zip_with(other, Add::op_add)
}

///|
impl[T : Neg] Neg for MatrixFn[T] with op_neg(self) {
  self.map(T::op_neg)
}

///|
impl[T : Add + Neg] Sub for MatrixFn[T] with op_sub(self, other) {
  self + -other
}

///|
pub fn MatrixFn::scale[T : Mul](self : MatrixFn[T], cst : T) -> MatrixFn[T] {
  self.map(fn(x) { x * cst })
}

///|
pub fn MatrixFn::identity[T : One + Zero](size : Int) -> MatrixFn[T] {
  MatrixFn::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
pub fn MatrixFn::pow[T : Semiring](
  self : MatrixFn[T],
  power : Int
) -> MatrixFn[T] {
  loop MatrixFn::identity(self.grid.1), power, self {
    s, 0, _ => s
    s, 1, m => s * m
    s, p, m => continue if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m
  }
}

///|
pub fn MatrixFn::adjoint[T : Conjugate](self : MatrixFn[T]) -> MatrixFn[T] {
  self.map(T::conjugate)
}

///|
pub fn MatrixFn::swap_cols[T](
  self : MatrixFn[T],
  r1 : Int,
  r2 : Int
) -> MatrixFn[T] {
  let (r, c) = self.grid
  guard r1 < r && r2 < r && r1 >= 0 && r2 >= 0
  if r1 == r2 {
    self
  } else {
    MatrixFn::make(r, c, fn {
      i, j if i == r1 => (self.data)(r2, j)
      i, j if i == r2 => (self.data)(r1, j)
      i, j => (self.data)(i, j)
    })
  }
}

///|
pub fn MatrixFn::swap_rows[T](
  self : MatrixFn[T],
  r1 : Int,
  r2 : Int
) -> MatrixFn[T] {
  let (r, c) = self.grid
  guard r1 < r && r2 < r && r1 >= 0 && r2 >= 0
  if r1 == r2 {
    self
  } else {
    MatrixFn::make(r, c, fn {
      i, j if j == r1 => (self.data)(i, r2)
      i, j if j == r2 => (self.data)(i, r1)
      i, j => (self.data)(i, j)
    })
  }
}

///|
impl[T : Mul + Add] Mul for MatrixFn[T] with op_mul(self, other) {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard c1 == r2
  MatrixFn::make(r1, c2, fn(i, j) {
    let mut sum = (self.data)(i, 0) * (other.data)(0, j)
    for k in 1..<c1 {
      sum += (self.data)(i, k) * (other.data)(k, j)
    }
    sum
  })
}

///|
pub fn MatrixFn::zip_with[T, U, W](
  self : MatrixFn[T],
  other : MatrixFn[U],
  f : (T, U) -> W
) -> MatrixFn[W] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard r1 == r2 && c1 == c2 else {
    abort("Matrix dimensions do not match for addition")
  }
  MatrixFn::make(r1, c1, fn(i, j) { f((self.data)(i, j), (other.data)(i, j)) })
}

///|
pub fn MatrixFn::determinant[T : Mul + Add + One + Neg + Zero](
  self : MatrixFn[T]
) -> T {
  let (n, m) = self.grid
  guard m == n else { abort("determinant: not a square matrix") }
  fn go {
    f, 1 => f(0, 0)
    f, n => {
      let mut det = T::zero()
      for i in 0..<n {
        let sub_view = fn { j, k => f(j + 1, if k < i { k } else { k + 1 }) }
        let sign = if i % 2 == 0 { T::one() } else { -T::one() }
        det += sign * f(0, i) * go(sub_view, n - 1)
      }
      det
    }
  }

  go(fn { i, j => self[i][j] }, n)
}

///|
pub fn MatrixFn::horizontal_combine[T](
  self : MatrixFn[T],
  other : MatrixFn[T]
) -> MatrixFn[T] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard r1 == r2
  MatrixFn::make(r1, c1 + c2, fn(i, j) {
    if j < c1 {
      (self.data)(i, j)
    } else {
      (other.data)(i, j - c1)
    }
  })
}

///|
pub fn MatrixFn::vertical_combine[T](
  self : MatrixFn[T],
  other : MatrixFn[T]
) -> MatrixFn[T] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard c1 == c2
  MatrixFn::make(r1 + r2, c1, fn(i, j) {
    if i < r1 {
      (self.data)(i, j)
    } else {
      (other.data)(i - r1, j)
    }
  })
}

///|
test "matrix_combine" {
  let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m2 = MatrixFn::from_2d_array([[1, 0], [0, 1]])
  let m3 = MatrixFn::horizontal_combine(m1, m2)
  let m4 = MatrixFn::vertical_combine(m1, m2)
  inspect!(
    m3,
    content=
      #||1, 2, 1, 0|
      #||3, 4, 0, 1|
    ,
  )
  inspect!(
    m4,
    content=
      #||1, 2|
      #||3, 4|
      #||1, 0|
      #||0, 1|
    ,
  )
}

///|
test {
  let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m2 = MatrixFn::from_2d_array([[1, 0], [0, 1]])
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
  inspect!(
    m1.scale(10),
    content=
      #||10, 20|
      #||30, 40|
    ,
  )
  let m5 : MatrixFn[Int] = MatrixFn::identity(5)
  inspect!(
    m5,
    content=
      #||1, 0, 0, 0, 0|
      #||0, 1, 0, 0, 0|
      #||0, 0, 1, 0, 0|
      #||0, 0, 0, 1, 0|
      #||0, 0, 0, 0, 1|
    ,
  )
  inspect!(m4.determinant(), content="4")
  inspect!(m1.determinant(), content="-2")
  inspect!(m5.determinant(), content="1")
  let m = Matrix::make(3, 3, fn(i, _) -> Int { i }).pow(10)
  inspect!(
    m,
    content=
      #||0, 0, 0|
      #||19683, 19683, 19683|
      #||39366, 39366, 39366|
    ,
  )
}
