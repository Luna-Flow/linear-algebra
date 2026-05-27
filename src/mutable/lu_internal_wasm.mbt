priv struct LuDecomposition[T] {
  lu : Matrix[T]
  permutation : Array[Int]
  swap_count : Int
  singular : Bool
}

fn[T : Compare + Field + Num + Tolerance] Matrix::lu_decompose_internal(
  self : Matrix[T],
) -> LuDecomposition[T] {
  let lu = self.copy()
  let n = lu.row
  let data = lu.data
  let permutation = Array::makei(n, fn(i) { i })
  let mut swap_count = 0
  let mut singular = false
  let tol = T::tolerance()
  for j in 0..<n {
    let mut max_row = j
    for i in (j + 1)..<n {
      if data[i * n + j].abs() > data[max_row * n + j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      lu.swap_rows(j, max_row)
      let temp = permutation[j]
      permutation[j] = permutation[max_row]
      permutation[max_row] = temp
      swap_count += 1
    }
    let pivot = data[j * n + j]
    if pivot.abs() < tol {
      singular = true
      continue
    }
    let pivot_row_offset = j * n
    for i in (j + 1)..<n {
      let row_offset = i * n
      let factor = data[row_offset + j] / pivot
      data[row_offset + j] = factor
      for k in (j + 1)..<n {
        data[row_offset + k] = data[row_offset + k] -
          factor * data[pivot_row_offset + k]
      }
    }
  }
  { lu, permutation, swap_count, singular }
}

fn[T : Num] LuDecomposition::determinant_internal(
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
    det *= lu_data[i * n + i]
  }
  det
}

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
  let permutation = self.permutation
  let tol = T::tolerance()
  let y = Matrix::new(n, cols, T::zero())
  let y_data = y.data
  for i in 0..<n {
    let row_offset = i * cols
    let rhs_row_offset = permutation[i] * cols
    for j in 0..<cols {
      let mut acc = rhs_data[rhs_row_offset + j]
      for k in 0..<i {
        acc = acc - lu_data[i * n + k] * y_data[k * cols + j]
      }
      y_data[row_offset + j] = acc
    }
  }
  let x = Matrix::new(n, cols, T::zero())
  let x_data = x.data
  for step in 0..<n {
    let i = n - 1 - step
    let row_offset = i * cols
    let lu_row_offset = i * n
    let pivot = lu_data[lu_row_offset + i]
    if pivot.abs() < tol {
      return None
    }
    for j in 0..<cols {
      let mut acc = y_data[row_offset + j]
      for k in (i + 1)..<n {
        acc = acc - lu_data[lu_row_offset + k] * x_data[k * cols + j]
      }
      x_data[row_offset + j] = acc / pivot
    }
  }
  Some(x)
}

fn[T : Compare + Field + Num + Tolerance] LuDecomposition::solve_identity_internal(
  self : LuDecomposition[T],
) -> Matrix[T]? {
  if self.singular {
    return None
  }
  let n = self.lu.row
  let lu_data = self.lu.data
  let permutation = self.permutation
  let tol = T::tolerance()
  let work = Array::make(n, T::zero())
  let x = Matrix::new(n, n, T::zero())
  let x_data = x.data
  for rhs_col in 0..<n {
    for i in 0..<n {
      let mut acc = if permutation[i] == rhs_col {
        T::one()
      } else {
        T::zero()
      }
      let row_offset = i * n
      for k in 0..<i {
        acc = acc - lu_data[row_offset + k] * work[k]
      }
      work[i] = acc
    }
    for step in 0..<n {
      let i = n - 1 - step
      let row_offset = i * n
      let pivot = lu_data[row_offset + i]
      if pivot.abs() < tol {
        return None
      }
      let mut acc = work[i]
      for k in (i + 1)..<n {
        acc = acc - lu_data[row_offset + k] * x_data[k * n + rhs_col]
      }
      x_data[row_offset + rhs_col] = acc / pivot
    }
  }
  Some(x)
}
