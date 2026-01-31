///|
pub fn m2d_matrix_mul(
  n : Int,
  a : Array[Array[Double]],
  b : Array[Array[Double]],
) -> Array[Array[Double]] {
  if n <= 64 {
    let c = Array::makei(n, fn(_i) { Array::make(n, 0.0) })
    for i = 0; i < n; i = i + 1 {
      let row_a = a[i]
      let row_c = c[i]
      for j = 0; j < n; j = j + 1 {
        let mut sum = 0.0
        for k = 0; k < n; k = k + 1 {
          sum = sum + row_a[k] * b[k][j]
        }
        row_c[j] = sum
      }
    }
    c
  } else {
    let c = Array::makei(n, fn(_i) { Array::make(n, 0.0) })
    for i = 0; i < n; i = i + 1 {
      let row_a = a[i]
      let row_c = c[i]
      for k = 0; k < n; k = k + 1 {
        let r = row_a[k]
        let row_b = b[k]
        for j = 0; j < n; j = j + 1 {
          row_c[j] = row_c[j] + r * row_b[j]
        }
      }
    }
    c
  }
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
    for j = 0; j < cols; j = j + 1 {
      sum = sum + row[j] * vec[j]
    }
    res[i] = sum
  }
  res
}
