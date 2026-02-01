///|
pub fn m2d_matrix_mul(
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
pub fn m2d_matrix_vector_mul(
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
