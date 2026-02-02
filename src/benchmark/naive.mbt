///|
pub fn naive_matrix_access(
  _rows : Int,
  _cols : Int,
  data : Array[Array[Double]],
) -> Double {
  data
  .iter()
  .flat_map(fn(row) { row.iter() })
  .fold(fn(acc, x) { acc + x }, init=0.0)
}

///|
pub fn naive_matrix_mapi(
  _rows : Int,
  _cols : Int,
  data : Array[Array[Double]],
  f : (Int, Int, Double) -> Double,
) -> Array[Array[Double]] {
  data.mapi(fn(i, row) { row.mapi(fn(j, x) { f(i, j, x) }) })
}

///|
pub fn naive_matrix_map_inplace(
  _rows : Int,
  _cols : Int,
  data : Array[Array[Double]],
  f : (Double) -> Double,
) -> Unit {
  // Functional style usually avoids inplace, but "intuitive" use of each + map_in_place
  data.each(fn(row) { row.map_in_place(f) })
}

///|
pub fn naive_vector_dot(a : Array[Double], b : Array[Double]) -> Double {
  a.iter().mapi(fn(i, x) { x * b[i] }).fold(fn(acc, x) { acc + x }, init=0.0)
}

///|
pub fn naive_matrix_vector_mul(
  _rows : Int,
  _cols : Int,
  mat : Array[Array[Double]],
  vec : Array[Double],
) -> Array[Double] {
  mat.map(fn(row) {
    row
    .iter()
    .mapi(fn(i, x) { x * vec[i] })
    .fold(fn(acc, x) { acc + x }, init=0.0)
  })
}

///|
pub fn naive_matrix_mul(
  n : Int,
  a : Array[Array[Double]],
  b : Array[Array[Double]],
) -> Array[Array[Double]] {
  // Functional intuition: dot product of rows of A and columns of B
  a.map(fn(row_a) {
    Array::makei(n, fn(j) {
      let mut sum = 0.0
      for k in 0..<n {
        sum = sum + row_a[k] * b[k][j]
      }
      sum
    })
  })
}

///|
pub fn naive_vector_access(data : Array[Double]) -> Double {
  data.iter().fold(fn(acc, x) { acc + x }, init=0.0)
}

///|
pub fn naive_matrix_set_access(
  _rows : Int,
  _cols : Int,
  data : Array[Array[Double]],
  val : Double,
) -> Unit {
  data.each(fn(row) {
    for j = 0; j < row.length(); j = j + 1 {
      row[j] = val
    }
  })
}

///|
pub fn naive_matrix_each(
  data : Array[Array[Double]],
  f : (Double) -> Unit,
) -> Unit {
  data.each(fn(row) { row.each(f) })
}

///|
pub fn naive_matrix_each_row_col(
  data : Array[Array[Double]],
  f : (Int, Int, Double) -> Unit,
) -> Unit {
  data.eachi(fn(i, row) { row.eachi(fn(j, x) { f(i, j, x) }) })
}

///|
pub fn naive_reduce_row_elimination(
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
pub fn naive_rank(rows : Int, cols : Int, data : Array[Array[Double]]) -> Int {
  let m = naive_reduce_row_elimination(rows, cols, data)
  m
  .iter()
  .fold(
    fn(acc, row) {
      if row.iter().any(fn(x) { x.abs() > 1.0e-15 }) {
        acc + 1
      } else {
        acc
      }
    },
    init=0,
  )
}

///|
pub fn naive_inverse(
  n : Int,
  data : Array[Array[Double]],
) -> Array[Array[Double]]? {
  let rows = n
  let cols = 2 * n
  let augmented = Array::makei(rows, fn(i) {
    Array::makei(cols, fn(j) {
      if j < n {
        data[i][j]
      } else if j == n + i {
        1.0
      } else {
        0.0
      }
    })
  })
  let res = naive_reduce_row_elimination(rows, cols, augmented)
  for i = 0; i < n; i = i + 1 {
    if res[i][i].abs() < 1.0e-15 {
      return None
    }
  }
  Some(Array::makei(n, fn(i) { Array::makei(n, fn(j) { res[i][n + j] }) }))
}

///|
pub fn naive_determinant(n : Int, data : Array[Array[Double]]) -> Double {
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
