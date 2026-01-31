///|
pub fn native_matrix_access(
  row : Int,
  col : Int,
  data : Array[Double],
) -> Double {
  let mut sum = 0.0
  let mut idx = 0
  for i = 0; i < row; i = i + 1 {
    for j = 0; j < col; j = j + 1 {
      sum = sum + data[idx]
      idx += 1
    }
  }
  sum
}

///|
pub fn native_matrix_each_row_col(
  row : Int,
  col : Int,
  data : Array[Double],
  f : (Int, Int, Double) -> Unit,
) -> Unit {
  let mut idx = 0
  for i = 0; i < row; i = i + 1 {
    for j = 0; j < col; j = j + 1 {
      f(i, j, data[idx])
      idx += 1
    }
  }
}

///|
pub fn native_matrix_mapi(
  row : Int,
  col : Int,
  data : Array[Double],
  f : (Int, Int, Double) -> Double,
) -> Array[Double] {
  if row == 0 || col == 0 {
    return []
  }
  let res = Array::make(row * col, f(0, 0, data[0]))
  let mut idx = 0
  for i = 0; i < row; i = i + 1 {
    for j = 0; j < col; j = j + 1 {
      res[idx] = f(i, j, data[idx])
      idx += 1
    }
  }
  res
}

///|
pub fn native_matrix_map_inplace(
  _row : Int,
  _col : Int,
  data : Array[Double],
  f : (Double) -> Double,
) -> Unit {
  data.map_in_place(f)
}
