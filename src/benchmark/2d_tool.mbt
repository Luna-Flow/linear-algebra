///|
pub fn _2d_matrix_access(
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
pub fn _2d_matrix_each(
  data : Array[Array[Double]],
  f : (Double) -> Unit,
) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    let row = data[i]
    for j = 0; j < row.length(); j = j + 1 {
      f(row[j])
    }
  }
}

///|
pub fn _2d_matrix_each_row_col(
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
pub fn _2d_matrix_mapi(
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
pub fn _2d_matrix_map_inplace(
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

///|
pub fn _2d_matrix_set_access(
  rows : Int,
  cols : Int,
  data : Array[Array[Double]],
  val : Double,
) -> Unit {
  for i = 0; i < rows; i = i + 1 {
    let row = data[i]
    for j = 0; j < cols; j = j + 1 {
      row[j] = val
    }
  }
}
