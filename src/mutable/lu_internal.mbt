///|
struct LuDecomposition[T] {
  lu : Matrix[T]
  rank : Int
  swap_count : Int
  singular : Bool
}

///|
fn[T : Compare + Num + Div + Tolerance] Matrix::lu_decompose_internal(
  self : Matrix[T],
) -> LuDecomposition[T] {
  let lu = self.copy()
  let n = lu.row
  let data = lu.data
  let mut rank = n
  let mut swap_count = 0
  let mut singular = false
  for j in 0..<n {
    let mut max_row = j
    for i in (j + 1)..<n {
      if data[i][j].abs() > data[max_row][j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      lu.swap_rows(j, max_row)
      swap_count += 1
    }
    let pivot = data[j][j]
    if pivot.abs() < T::tolerance() {
      rank -= 1
      singular = true
      continue
    }
    for i in (j + 1)..<n {
      let factor = data[i][j] / pivot
      data[i][j] = factor
      for k in (j + 1)..<n {
        data[i][k] = data[i][k] - factor * data[j][k]
      }
    }
  }
  { lu, rank, swap_count, singular }
}

///|
fn[T : Compare + Num + Div + Tolerance] LuDecomposition::determinant_internal(
  self : LuDecomposition[T],
) -> T {
  if self.singular {
    return T::zero()
  }
  let n = self.lu.row
  let lu_data = self.lu.data
  let mut det = if (self.swap_count & 1) == 0 {
    T::one()
  } else {
    -T::one()
  }
  for i in 0..<n {
    det *= lu_data[i][i]
  }
  det
}

///|
fn[T : Compare + Field + Num + Tolerance] LuDecomposition::solve_internal(
  self : LuDecomposition[T],
  rhs : Matrix[T],
) -> Matrix[T]? {
  if self.singular {
    return None
  }
  let n = self.lu.row
  let cols = rhs.col
  let lu_data = self.lu.data
  let rhs_data = rhs.data
  let y = Matrix::new(n, cols, T::zero())
  let y_data = y.data
  for i in 0..<n {
    for j in 0..<cols {
      let mut acc = rhs_data[i][j]
      for k in 0..<i {
        acc = acc - lu_data[i][k] * y_data[k][j]
      }
      y_data[i][j] = acc
    }
  }
  let x = Matrix::new(n, cols, T::zero())
  let x_data = x.data
  for step in 0..<n {
    let i = n - 1 - step
    let pivot = lu_data[i][i]
    if pivot.abs() < T::tolerance() {
      return None
    }
    for j in 0..<cols {
      let mut acc = y_data[i][j]
      for k in (i + 1)..<n {
        acc = acc - lu_data[i][k] * x_data[k][j]
      }
      x_data[i][j] = acc / pivot
    }
  }
  Some(x)
}
