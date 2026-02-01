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
