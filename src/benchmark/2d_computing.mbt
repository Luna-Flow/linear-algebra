///|
pub fn _2d_matrix_mul(
  n : Int,
  a : Array[Array[Double]],
  b : Array[Array[Double]],
) -> Array[Array[Double]] {
  let c = Array::makei(n, fn(_i) { Array::make(n, 0.0) })
  for i = 0; i < n; i = i + 1 {
    let row_a = a[i]
    let row_c = c[i]
    for k = 0; k < n; k = k + 1 {
      let aik = row_a[k]
      let row_b = b[k]
      // 4x Loop Unrolling
      let mut j = 0
      while j <= n - 4 {
        row_c[j] = row_c[j] + aik * row_b[j]
        row_c[j + 1] = row_c[j + 1] + aik * row_b[j + 1]
        row_c[j + 2] = row_c[j + 2] + aik * row_b[j + 2]
        row_c[j + 3] = row_c[j + 3] + aik * row_b[j + 3]
        j = j + 4
      }
      while j < n {
        row_c[j] = row_c[j] + aik * row_b[j]
        j = j + 1
      }
    }
  }
  c
}

///|
pub fn _2d_matrix_vector_mul(
  rows : Int,
  cols : Int,
  mat : Array[Array[Double]],
  vec : Array[Double],
) -> Array[Double] {
  let res = Array::make(rows, 0.0)
  for i = 0; i < rows; i = i + 1 {
    let mut sum = 0.0
    let row = mat[i]
    let mut j = 0
    // 4x Loop Unrolling
    while j <= cols - 4 {
      sum = sum + row[j] * vec[j]
      sum = sum + row[j + 1] * vec[j + 1]
      sum = sum + row[j + 2] * vec[j + 2]
      sum = sum + row[j + 3] * vec[j + 3]
      j = j + 4
    }
    while j < cols {
      sum = sum + row[j] * vec[j]
      j = j + 1
    }
    res[i] = sum
  }
  res
}

// --- Advanced Computing ---

///|
pub fn _2d_reduce_row_elimination(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
) -> Array[Array[Double]] {
  let m = Array::makei(rows, fn(i) { data[i].copy() })
  let mut col = 0
  for i = 0; i < rows; i = i + 1 {
    if col >= cols {
      break
    }
    let mut max_row = i
    for j = i + 1; j < rows; j = j + 1 {
      if m[j][col].abs() > m[max_row][col].abs() {
        max_row = j
      }
    }
    // Swap rows
    if max_row != i {
      let tmp = m[i]
      m[i] = m[max_row]
      m[max_row] = tmp
    }
    if m[i][col].abs() < 1.0e-15 {
      col = col + 1
      continue
    }
    let val = m[i][col]
    let row_i = m[i]
    for k = 0; k < cols; k = k + 1 {
      row_i[k] = row_i[k] / val
    }
    for j = 0; j < rows; j = j + 1 {
      if j == i {
        continue
      }
      let factor = m[j][col]
      let row_j = m[j]
      for k = 0; k < cols; k = k + 1 {
        row_j[k] = row_j[k] - row_i[k] * factor
      }
    }
    col = col + 1
  }
  m
}

///|
pub fn _2d_rank(rows : Int, cols : Int, data : Array[Array[Double]]) -> Int {
  let m = _2d_reduce_row_elimination(rows, cols, data)
  let mut rank = 0
  for i = 0; i < rows; i = i + 1 {
    let mut has_nonzero = false
    let row = m[i]
    for j = 0; j < cols; j = j + 1 {
      if row[j].abs() > 1.0e-15 {
        has_nonzero = true
        break
      }
    }
    if has_nonzero {
      rank += 1
    }
  }
  rank
}

///|
pub fn _2d_inverse(
  n : Int,
  data : Array[Array[Double]],
) -> Array[Array[Double]]? {
  let rows = n
  let cols = 2 * n
  let augmented = Array::makei(rows, fn(i) {
    let row = Array::make(cols, 0.0)
    for j = 0; j < n; j = j + 1 {
      row[j] = data[i][j]
    }
    row[n + i] = 1.0
    row
  })
  let res = _2d_reduce_row_elimination(rows, cols, augmented)
  for i = 0; i < n; i = i + 1 {
    if res[i][i].abs() < 1.0e-15 {
      return None
    }
  }
  let inv = Array::makei(n, fn(i) {
    let row = Array::make(n, 0.0)
    for j = 0; j < n; j = j + 1 {
      row[j] = res[i][n + j]
    }
    row
  })
  Some(inv)
}

///|
pub fn _2d_determinant(n : Int, data : Array[Array[Double]]) -> Double {
  let m = Array::makei(n, fn(i) { data[i].copy() })
  if n == 0 {
    return 1.0
  }
  let mut det_sign = 1.0
  for j = 0; j < n; j = j + 1 {
    let mut max_row = j
    for i = j + 1; i < n; i = i + 1 {
      if m[i][j].abs() > m[max_row][j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      // Swap rows
      let tmp = m[j]
      m[j] = m[max_row]
      m[max_row] = tmp
      det_sign = -det_sign
    }
    let pivot = m[j][j]
    if pivot.abs() < 1.0e-15 {
      return 0.0
    }
    for i = j + 1; i < n; i = i + 1 {
      let factor = m[i][j] / pivot
      let row_i = m[i]
      let row_pivot = m[j]
      for k = j + 1; k < n; k = k + 1 {
        row_i[k] = row_i[k] - factor * row_pivot[k]
      }
    }
  }
  let mut det = det_sign
  for i = 0; i < n; i = i + 1 {
    det = det * m[i][i]
  }
  det
}
