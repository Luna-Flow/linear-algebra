///|
priv struct LuDecomposition[T] {
  lu : Matrix[T]
  permutation : Array[Int]
  swap_count : Int
  singular : Bool
}

///|
fn[T : Compare + Field + Num + Tolerance] Matrix::lu_decompose_internal(
  self : Matrix[T],
) -> LuDecomposition[T] {
  let lu = self.copy()
  let n = lu.row
  let data = lu.data
  let permutation = Array::makei(n, fn(i) { i })
  let mut swap_count = 0
  let mut singular = false
  let tol = Tolerance::tolerance()
  for j = 0; j < n; j = j + 1 {
    let mut max_row = j
    for i = j + 1; i < n; i = i + 1 {
      if Num::abs(data[i * n + j]) > Num::abs(data[max_row * n + j]) {
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
    if Num::abs(pivot) < tol {
      singular = true
      continue
    }
    let pivot_row_offset = j * n
    for i = j + 1; i < n; i = i + 1 {
      let row_offset = i * n
      let factor = data[row_offset + j] / pivot
      data[row_offset + j] = factor
      let mut k = j + 1
      while k + 3 < n {
        data[row_offset + k] = data[row_offset + k] -
          factor * data[pivot_row_offset + k]
        data[row_offset + k + 1] = data[row_offset + k + 1] -
          factor * data[pivot_row_offset + k + 1]
        data[row_offset + k + 2] = data[row_offset + k + 2] -
          factor * data[pivot_row_offset + k + 2]
        data[row_offset + k + 3] = data[row_offset + k + 3] -
          factor * data[pivot_row_offset + k + 3]
        k += 4
      }
      while k < n {
        data[row_offset + k] = data[row_offset + k] -
          factor * data[pivot_row_offset + k]
        k += 1
      }
    }
  }
  { lu, permutation, swap_count, singular, }
}

///|
fn[T : Num] LuDecomposition::determinant_internal(
  self : LuDecomposition[T],
) -> T {
  if self.singular {
    return Zero::zero()
  }
  let n = self.lu.row
  let lu_data = self.lu.data
  let mut det = if (self.swap_count & 1) == 0 {
    One::one()
  } else {
    -One::one()
  }
  for i = 0; i < n; i = i + 1 {
    det *= lu_data[i * n + i]
  }
  det
}

///|
#warnings("-unused_value")
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
  let tol = Tolerance::tolerance()
  let y = Matrix::new(n, cols, Zero::zero())
  let y_data = y.data
  for i = 0; i < n; i = i + 1 {
    let row_offset = i * cols
    let rhs_row_offset = permutation[i] * cols
    for j = 0; j < cols; j = j + 1 {
      let mut acc = rhs_data[rhs_row_offset + j]
      for k = 0; k < i; k = k + 1 {
        acc = acc - lu_data[i * n + k] * y_data[k * cols + j]
      }
      y_data[row_offset + j] = acc
    }
  }
  let x = Matrix::new(n, cols, Zero::zero())
  let x_data = x.data
  for step = 0; step < n; step = step + 1 {
    let i = n - 1 - step
    let row_offset = i * cols
    let lu_row_offset = i * n
    let pivot = lu_data[lu_row_offset + i]
    if Num::abs(pivot) < tol {
      return None
    }
    for j = 0; j < cols; j = j + 1 {
      let mut acc = y_data[row_offset + j]
      for k = i + 1; k < n; k = k + 1 {
        acc = acc - lu_data[lu_row_offset + k] * x_data[k * cols + j]
      }
      x_data[row_offset + j] = acc / pivot
    }
  }
  Some(x)
}

///|
fn[T : Compare + Field + Num + Tolerance] LuDecomposition::solve_identity_internal(
  self : LuDecomposition[T],
) -> Matrix[T]? {
  if self.singular {
    return None
  }
  let n = self.lu.row
  let lu_data = self.lu.data
  let permutation = self.permutation
  let tol = Tolerance::tolerance()
  let work = Array::make(n, Zero::zero())
  let x = Matrix::new(n, n, Zero::zero())
  let x_data = x.data
  for rhs_col = 0; rhs_col < n; rhs_col = rhs_col + 1 {
    for i = 0; i < n; i = i + 1 {
      let mut acc = if permutation[i] == rhs_col {
        One::one()
      } else {
        Zero::zero()
      }
      let row_offset = i * n
      for k = 0; k < i; k = k + 1 {
        acc = acc - lu_data[row_offset + k] * work[k]
      }
      work[i] = acc
    }
    for step = 0; step < n; step = step + 1 {
      let i = n - 1 - step
      let row_offset = i * n
      let pivot = lu_data[row_offset + i]
      if Num::abs(pivot) < tol {
        return None
      }
      let mut acc = work[i]
      for k = i + 1; k < n; k = k + 1 {
        acc = acc - lu_data[row_offset + k] * x_data[k * n + rhs_col]
      }
      x_data[row_offset + rhs_col] = acc / pivot
    }
  }
  Some(x)
}
