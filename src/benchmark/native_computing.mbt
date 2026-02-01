///|
pub fn native_matrix_mul(
  n : Int,
  a : Array[Double],
  b : Array[Double],
) -> Array[Double] {
  if n <= 64 {
    let c = Array::make(n * n, 0.0)
    for i = 0; i < n; i = i + 1 {
      let row_offset = i * n
      for j = 0; j < n; j = j + 1 {
        let mut sum = 0.0
        for k = 0; k < n; k = k + 1 {
          sum = sum + a[row_offset + k] * b[k * n + j]
        }
        c[row_offset + j] = sum
      }
    }
    c
  } else {
    let c = Array::make(n * n, 0.0)
    let mut res_idx = 0
    for i = 0; i < n; i = i + 1 {
      for k = 0; k < n; k = k + 1 {
        let aik = a[i * n + k]
        let other_row_start = k * n
        for j = 0; j < n; j = j + 1 {
          c[res_idx + j] = c[res_idx + j] + aik * b[other_row_start + j]
        }
      }
      res_idx += n
    }
    c
  }
}

///|
pub fn native_vector_dot(a : Array[Double], b : Array[Double]) -> Double {
  let mut sum = 0.0
  for i in 0..<a.length() {
    sum = sum + a[i] * b[i]
  }
  sum
}

///|
pub fn native_matrix_vector_mul(
  row : Int,
  col : Int,
  mat : Array[Double],
  vec : Array[Double],
) -> Array[Double] {
  let res = Array::make(row, 0.0)
  let mut idx = 0
  for i = 0; i < row; i = i + 1 {
    let mut sum = 0.0
    for j = 0; j < col; j = j + 1 {
      sum = sum + mat[idx] * vec[j]
      idx += 1
    }
    res[i] = sum
  }
  res
}

///|
pub fn native_matrix_access(
  rows : Int,
  cols : Int,
  data : Array[Double],
) -> Double {
  let mut sum = 0.0
  let len = rows * cols
  for i = 0; i < len; i = i + 1 {
    sum = sum + data[i]
  }
  sum
}

///|
pub fn native_matrix_mapi(
  rows : Int,
  cols : Int,
  data : Array[Double],
  f : (Int, Int, Double) -> Double,
) -> Array[Double] {
  let res = Array::make(rows * cols, 0.0)
  for i = 0; i < rows; i = i + 1 {
    let offset = i * cols
    for j = 0; j < cols; j = j + 1 {
      res[offset + j] = f(i, j, data[offset + j])
    }
  }
  res
}

///|
pub fn native_matrix_map_inplace(
  _rows : Int,
  _cols : Int,
  data : Array[Double],
  f : (Double) -> Double,
) -> Unit {
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    data[i] = f(data[i])
  }
}
