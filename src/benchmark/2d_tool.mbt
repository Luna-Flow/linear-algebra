///|
pub fn m2d_matrix_access(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
) -> Double {
  let mut sum = 0.0
  for i = 0; i < rows; i = i + 1 {
    let row = data[i]
    for j = 0; j < cols; j = j + 1 {
      sum = sum + row[j]
    }
  }
  sum
}

///|
pub fn m2d_matrix_each_row_col(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
  f : (Int, Int, Double) -> Unit,
) -> Unit {
  for i = 0; i < rows; i = i + 1 {
    let row = data[i]
    for j = 0; j < cols; j = j + 1 {
      f(i, j, row[j])
    }
  }
}

///|
pub fn m2d_matrix_mapi(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
  f : (Int, Int, Double) -> Double,
) -> Array[Array[Double]] {
  let res = Array::makei(rows, fn(i) {
    let row = data[i]
    Array::makei(cols, fn(j) { f(i, j, row[j]) })
  })
  res
}

///|
pub fn m2d_matrix_map_inplace(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
  f : (Double) -> Double,
) -> Unit {
  for i = 0; i < rows; i = i + 1 {
    let row = data[i]
    for j = 0; j < cols; j = j + 1 {
      row[j] = f(row[j])
    }
  }
}
