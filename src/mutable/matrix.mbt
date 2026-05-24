///|
pub struct Matrix[T] {
  row : Int
  col : Int
  data : Array[Array[T]]
} derive(Eq)

///|
pub impl[T] HasShape for Matrix[T] with shape(self) {
  (self.row, self.col)
}

///|
pub fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Array[T] {
  self.data[row]
}

///|
pub fn[T] Matrix::make(
  row : Int,
  col : Int,
  init : (Int, Int) -> T,
) -> Matrix[T] {
  let data = Array::makei(row, fn(i) { Array::makei(col, fn(j) { init(i, j) }) })
  { row, col, data }
}

///|
pub fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T] {
  let data = Array::makei(row, fn(_) { Array::make(col, elem) })
  { row, col, data }
}

///|
pub fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T] {
  let row = arr.length()
  if row == 0 {
    return { row: 0, col: 0, data: [] }
  }
  let col = arr[0].length()
  for row_data in arr {
    guard row_data.length() == col
  }
  let data = arr.map(fn(row) { row.copy() })
  { row, col, data }
}

///|
pub fn[T] Matrix::from_array(
  row : Int,
  col : Int,
  data : Array[T],
) -> Matrix[T] {
  guard row * col == data.length()
  let mat_data = Array::makei(row, fn(i) {
    let row_arr = []
    let offset = i * col
    for j in 0..<col {
      row_arr.push(data[offset + j])
    }
    row_arr
  })
  { row, col, data: mat_data }
}

///|
pub fn[T] Matrix::row(self : Matrix[T]) -> Int {
  self.row
}

///|
pub fn[T] Matrix::col(self : Matrix[T]) -> Int {
  self.col
}

///|
pub fn[T] Matrix::get(self : Matrix[T], row : Int, col : Int) -> T {
  self.data[row][col]
}

///|
pub fn[T] Matrix::set(self : Matrix[T], row : Int, col : Int, val : T) -> Unit {
  self.data[row][col] = val
}

///|
pub impl[T : Show] Show for Matrix[T] with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
pub impl[T : Show] Show for Matrix[T] with output(self, logger) {
  for i in 0..<self.row {
    logger.write_char('|')
    let row = self.data[i]
    for j in 0..<self.col {
      logger.write_object(row[j])
      if j < self.col - 1 {
        logger.write_string(", ")
      }
    }
    logger.write_char('|')
    if i < self.row - 1 {
      logger.write_char('\n')
    }
  }
}

///|
pub fn[T, U] Matrix::map(self : Matrix[T], f : (T) -> U) -> Matrix[U] {
  let data = self.data.map(fn(row) { row.map(f) })
  { row: self.row, col: self.col, data }
}

///|
pub fn[T, U] Matrix::mapi(
  self : Matrix[T],
  f : (Int, Int, T) -> U,
) -> Matrix[U] {
  let data = self.data.mapi(fn(i, row) { row.mapi(fn(j, x) { f(i, j, x) }) })
  { row: self.row, col: self.col, data }
}

///|
pub fn[T] Matrix::map_inplace(self : Matrix[T], f : (T) -> T) -> Unit {
  self.data.each(fn(row) { row.map_in_place(f) })
}

///|
pub fn[T] Matrix::to_transpose(self : Matrix[T]) -> Transpose[T] {
  Transpose(self)
}

///|
pub fn[T] Matrix::map_row_inplace(
  self : Matrix[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  self.data[row].map_in_place(f)
}

///|
pub fn[T] Matrix::map_col_inplace(
  self : Matrix[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  for i in 0..<self.row {
    self.data[i][col] = f(self.data[i][col])
  }
}

///|
pub fn[T] Matrix::each(self : Matrix[T], f : (T) -> Unit) -> Unit {
  self.data.each(fn(row) { row.each(f) })
}

///|
pub fn[T] Matrix::eachi(self : Matrix[T], f : (Int, T) -> Unit) -> Unit {
  let mut idx = 0
  for i in 0..<self.row {
    for j in 0..<self.col {
      f(idx, self.data[i][j])
      idx += 1
    }
  }
}

///|
pub fn[T] Matrix::each_row_col(
  self : Matrix[T],
  f : (Int, Int, T) -> Unit,
) -> Unit {
  self.data.eachi(fn(i, row) { row.eachi(fn(j, x) { f(i, j, x) }) })
}

///|
pub fn[T] Matrix::each_row(
  self : Matrix[T],
  row : Int,
  f : (T) -> Unit,
) -> Unit {
  self.data[row].each(f)
}

///|
pub fn[T] Matrix::eachi_row(
  self : Matrix[T],
  row : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  self.data[row].eachi(f)
}

///|
pub fn[T] Matrix::each_col(
  self : Matrix[T],
  col : Int,
  f : (T) -> Unit,
) -> Unit {
  for i in 0..<self.row {
    f(self.data[i][col])
  }
}

///|
pub fn[T] Matrix::eachi_col(
  self : Matrix[T],
  col : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  for i in 0..<self.row {
    f(i, self.data[i][col])
  }
}

///|
pub fn[T] Matrix::copy(self : Matrix[T]) -> Matrix[T] {
  { row: self.row, col: self.col, data: self.data.map(fn(row) { row.copy() }) }
}

///|
pub impl[T : AddMonoid + Mul] Mul for Matrix[T] with mul(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row

  // Optimized for JS Array[Array] access
  // We use i-k-j loop order.
  let data = Array::makei(row, fn(_) { Array::make(col, T::zero()) })
  for i in 0..<row {
    let row_a = self.data[i]
    let row_c = data[i]
    for k in 0..<inner {
      let val_a = row_a[k]
      // Inner loop over J
      let row_b = other.data[k]
      for j in 0..<col {
        row_c[j] = row_c[j] + val_a * row_b[j]
      }
    }
  }
  { row, col, data }
}

///|
pub impl[T : Add] Add for Matrix[T] with add(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.row == other.row && self.col == other.col
  let data = Array::makei(self.row, fn(i) {
    let row_a = self.data[i]
    let row_b = other.data[i]
    Array::makei(self.col, fn(j) { row_a[j] + row_b[j] })
  })
  { row: self.row, col: self.col, data }
}

///|
pub impl[T : Neg] Neg for Matrix[T] with neg(self : Matrix[T]) -> Matrix[T] {
  self.map(T::neg)
}

///|
pub impl[T : Add + Neg] Sub for Matrix[T] with sub(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  self + -other
}

///|
pub fn[T : Mul] Matrix::scale(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x * cst })
}

///|
pub fn[T : Add] Matrix::add_constant(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x + cst })
}

///|
pub fn[T : Zero + One] identity(size : Int) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    if i == j {
      T::one()
    } else {
      T::zero()
    }
  })
}

///|
pub fn[T : Compare + Zero] Matrix::null(self : Matrix[T]) -> Bool {
  for i in 0..<self.row {
    for j in 0..<self.col {
      if self.data[i][j] != T::zero() {
        return false
      }
    }
  }
  true
}

///|
pub fn[T : Conjugate] Matrix::adjoint(self : Matrix[T]) -> Matrix[T] {
  self.transpose().map(T::conjugate)
}

///|
pub fn[T] Matrix::transpose(self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) { self.data[j][i] })
}

///|
pub fn[T] Matrix::swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Unit {
  if r1 == r2 {
    return
  }
  let temp = self.data[r1]
  self.data[r1] = self.data[r2]
  self.data[r2] = temp
}

///|
pub fn[T] Matrix::swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Unit {
  if c1 == c2 {
    return
  }
  for i in 0..<self.row {
    let temp = self.data[i][c1]
    self.data[i][c1] = self.data[i][c2]
    self.data[i][c2] = temp
  }
}

///|
pub fn[T] Matrix::row_to_array(self : Matrix[T], row : Int) -> Array[T] {
  self.data[row].copy()
}

///|
pub fn[T] Matrix::col_to_array(self : Matrix[T], col : Int) -> Array[T] {
  let res = Array::makei(self.row, fn(i) { self.data[i][col] })
  res
}

///|
pub fn[T] Matrix::to_array(self : Matrix[T]) -> Array[T] {
  let res = []
  for i in 0..<self.row {
    res.push_iter(self.data[i].iter())
  }
  res
}

///|
pub fn[T] Matrix::to_2d_array(self : Matrix[T]) -> Array[Array[T]] {
  self.data.map(fn(r) { r.copy() })
}

///|
pub fn[T] Matrix::iter(self : Matrix[T]) -> Iter[T] {
  self.data.iter().flat_map(fn(row) { row.iter() })
}

///|
pub fn[T] Matrix::iter_row(self : Matrix[T], row : Int) -> Iter[T] {
  self.data[row].iter()
}

///|
pub fn[T] Matrix::iter_col(self : Matrix[T], col : Int) -> Iter[T] {
  let arr = []
  for i in 0..<self.row {
    arr.push(self.data[i][col])
  }
  arr.iter()
}

///|
pub fn[T : HomomorphismNat] Matrix::from_nat_matrix(
  self : Matrix[Int],
) -> Matrix[T] {
  self.map(HomomorphismNat::from_nat)
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::power_method(
  self : Matrix[T],
  max_iterations : Int,
) -> (T, Vector[T])? {
  guard self.is_square() else {
    abort("Matrix must be square for power method")
  }
  let n = self.row
  if n == 0 {
    abort("Matrix::power_method requires a non-empty square matrix")
  }
  let tol = T::tolerance()
  let mut x = Vector::makei(n, fn(_) { T::one() })
  for _ in 0..<max_iterations {
    let y = self.mul_vec(x)
    let mut scale = T::zero()
    for i in 0..<n {
      let candidate = y[i].abs()
      if candidate > scale {
        scale = candidate
      }
    }
    if scale <= tol {
      return None
    }
    x = y.map(fn(v) { v / scale })
    let ax = self.mul_vec(x)
    let mut numerator = T::zero()
    let mut denominator = T::zero()
    for i in 0..<n {
      numerator = numerator + x[i] * ax[i]
      denominator = denominator + x[i] * x[i]
    }
    if denominator.abs() <= tol {
      return None
    }
    let lambda = numerator / denominator
    let mut residual = T::zero()
    for i in 0..<n {
      let delta = (ax[i] - x[i] * lambda).abs()
      if delta > residual {
        residual = delta
      }
    }
    if residual <= tol {
      return Some((lambda, x))
    }
  }
  None
}

///|
pub fn[T] Matrix::is_square(self : Matrix[T]) -> Bool {
  self.row == self.col
}

///|
pub fn[T : Compare + Num + Tolerance] Matrix::is_symmetric(
  self : Matrix[T],
) -> Bool {
  if self.row != self.col {
    return false
  }
  for i = 0; i < self.row; i = i + 1 {
    for j = i + 1; j < self.col; j = j + 1 {
      if (self.data[i][j] - self.data[j][i]).abs() > T::tolerance() {
        return false
      }
    }
  }
  true
}

///|
pub fn[T] Matrix::to_vector(self : Matrix[T]) -> Vector[T] {
  Vector(self.to_array())
}

///|
pub fn[T] Matrix::row_to_vector(self : Matrix[T], row : Int) -> Vector[T] {
  Vector(self.row_to_array(row))
}

///|
pub fn[T] Matrix::col_to_vector(self : Matrix[T], col : Int) -> Vector[T] {
  Vector(self.col_to_array(col))
}

///|
pub fn[T : AddMonoid + Mul] Matrix::mul_vec(
  self : Matrix[T],
  vector : Vector[T],
) -> Vector[T] {
  let m = self.row
  let n = self.col
  let v_data = vector.0
  guard n == v_data.length() else {
    abort("Matrix and vector dimensions are not compatible for multiplication")
  }
  let res_data = Array::make(m, T::zero())
  for i = 0; i < m; i = i + 1 {
    let mut sum = T::zero()
    let row_data = self.data[i]
    for j = 0; j < n; j = j + 1 {
      sum = sum + row_data[j] * v_data[j]
    }
    res_data[i] = sum
  }
  Vector(res_data)
}

///|
pub fn[T] Matrix::horizontal_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.row == other.row
  let new_col = self.col + other.col
  if self.row == 0 {
    return { row: 0, col: new_col, data: [] }
  }
  if new_col == 0 {
    return Matrix::make(self.row, 0, fn(_, _) { abort("unreachable") })
  }
  let data = Array::makei(self.row, fn(i) {
    let row_self = self.data[i]
    let row_other = other.data[i]
    let new_row = if self.col > 0 {
      Array::make(new_col, row_self[0])
    } else if other.col > 0 {
      Array::make(new_col, row_other[0])
    } else {
      []
    }
    for j in 0..<self.col {
      new_row[j] = row_self[j]
    }
    for j in 0..<other.col {
      new_row[self.col + j] = row_other[j]
    }
    new_row
  })
  { row: self.row, col: new_col, data }
}

///|
pub fn[T] Matrix::vertical_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.col == other.col
  let data = []
  for i in 0..<self.row {
    data.push(self.data[i].copy())
  }
  for i in 0..<other.row {
    data.push(other.data[i].copy())
  }
  { row: self.row + other.row, col: self.col, data }
}

///|
pub fn[T : Add + Div + HomomorphismNat] Matrix::mean(
  self : Matrix[T],
) -> T {
  let count = self.row * self.col
  guard count > 0 else {
    abort("Matrix::mean requires at least one element")
  }
  let mut sum = T::from_nat(0)
  self.each(fn(x) { sum = sum + x })
  sum / T::from_nat(count)
}

///|
pub fn[T : Add + Sub + Mul + Div + HomomorphismNat] Matrix::variance(
  self : Matrix[T],
) -> T {
  let count = self.row * self.col
  guard count > 0 else {
    abort("Matrix::variance requires at least one element")
  }
  let m = self.mean()
  let mut sum_sq_diff = T::from_nat(0)
  self.each(fn(x) {
    let diff = x - m
    sum_sq_diff = sum_sq_diff + diff * diff
  })
  sum_sq_diff / T::from_nat(count)
}

///|
pub fn[T : Add + Sub + Mul + Div + Sqrt + HomomorphismNat] Matrix::std_dev(
  self : Matrix[T],
) -> T {
  guard self.row * self.col > 0 else {
    abort("Matrix::std_dev requires at least one element")
  }
  self.variance().sqrt()
}

///|
pub fn[T : AddMonoid + Mul + Sqrt] Matrix::frobenius_norm(
  self : Matrix[T],
) -> T {
  let mut sum_sq = T::zero()
  self.each(fn(x) { sum_sq = sum_sq + x * x })
  sum_sq.sqrt()
}

///|
pub fn[T : Compare] Matrix::max_element(self : Matrix[T]) -> T {
  if self.row == 0 || self.col == 0 {
    abort("Empty matrix")
  }
  let mut max_val = self.data[0][0]
  self.each(fn(x) { if x > max_val { max_val = x } })
  max_val
}

///|
pub fn[T : Compare] Matrix::min_element(self : Matrix[T]) -> T {
  if self.row == 0 || self.col == 0 {
    abort("Empty matrix")
  }
  let mut min_val = self.data[0][0]
  self.each(fn(x) { if x < min_val { min_val = x } })
  min_val
}

///|
pub fn[T : AddMonoid] Matrix::trace(self : Matrix[T]) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate trace")
  }
  let mut sum = T::zero()
  for i in 0..<self.row {
    sum = sum + self.data[i][i]
  }
  sum
}

///|
pub fn[T : Compare + Num + Inverse] Matrix::reduce_row_elimination(
  self : Matrix[T],
) -> Matrix[T] {
  let r = self.row
  let c = self.col
  let mut col = 0
  for i in 0..<r {
    if col >= c {
      break
    }
    let mut max_row = i
    for j in (i + 1)..<r {
      if self.data[j][col].abs() > self.data[max_row][col].abs() {
        max_row = j
      }
    }
    self.swap_rows(i, max_row)
    if self.data[i][col] == T::zero() {
      col = col + 1
      continue
    }
    let val = self.data[i][col]
    let inv_val = val.inv()
    let row_i = self.data[i]
    for k in 0..<c {
      row_i[k] = row_i[k] * inv_val
    }
    for j in 0..<r {
      if j == i {
        continue
      }
      let factor = self.data[j][col]
      let row_j = self.data[j]
      for k in 0..<c {
        row_j[k] = row_j[k] - row_i[k] * factor
      }
    }
    col = col + 1
  }
  self
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::rank(
  self : Matrix[T],
) -> Int {
  let mut rank = 0
  let reduced = self.copy()
  let row_count = reduced.row
  let col_count = reduced.col
  let data = reduced.data
  let tol = T::tolerance()
  let mut pivot_col = 0
  for pivot_row in 0..<row_count {
    while pivot_col < col_count {
      let mut max_row = pivot_row
      let mut max_abs = data[pivot_row][pivot_col].abs()
      for candidate_row in (pivot_row + 1)..<row_count {
        let candidate_abs = data[candidate_row][pivot_col].abs()
        if candidate_abs > max_abs {
          max_abs = candidate_abs
          max_row = candidate_row
        }
      }
      if max_abs < tol {
        pivot_col += 1
        continue
      }
      reduced.swap_rows(pivot_row, max_row)
      let pivot = data[pivot_row][pivot_col]
      for eliminate_row in (pivot_row + 1)..<row_count {
        let factor = data[eliminate_row][pivot_col] / pivot
        if factor.abs() < tol {
          data[eliminate_row][pivot_col] = T::zero()
          continue
        }
        data[eliminate_row][pivot_col] = T::zero()
        for col in (pivot_col + 1)..<col_count {
          data[eliminate_row][col] = data[eliminate_row][col] - factor * data[pivot_row][col]
        }
      }
      rank += 1
      pivot_col += 1
      break
    }
  }
  rank
}

///|
pub fn[T : Semiring] Matrix::pow(self : Matrix[T], power : Int) -> Matrix[T] {
  guard self.is_square() else {
    abort("Matrix must be square to calculate powers")
  }
  guard power >= 0 else {
    abort("Matrix::pow requires a non-negative exponent")
  }
  for state = identity(self.col), exp = power, base = self {
    if exp == 0 {
      break state
    }
    if exp == 1 {
      break state * base
    }
    let next_state = if (exp & 1) == 1 { state * base } else { state }
    continue next_state, exp >> 1, base * base
  }
}

///|
pub fn[T : Semiring] Matrix::matrix_power(
  self : Matrix[T],
  n : Int,
) -> Matrix[T] {
  self.pow(n)
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::determinant(
  self : Matrix[T],
) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate determinant")
  }
  let n = self.row
  match n {
    0 => T::one()
    1 => self.data[0][0]
    2 => {
      let r0 = self.data[0]
      let r1 = self.data[1]
      r0[0] * r1[1] - r0[1] * r1[0]
    }
    3 => {
      let r0 = self.data[0]
      let r1 = self.data[1]
      let r2 = self.data[2]
      r0[0] * (r1[1] * r2[2] - r1[2] * r2[1]) -
      r0[1] * (r1[0] * r2[2] - r1[2] * r2[0]) +
      r0[2] * (r1[0] * r2[1] - r1[1] * r2[0])
    }
    4 => {
      let r0 = self.data[0]
      let r1 = self.data[1]
      let r2 = self.data[2]
      let r3 = self.data[3]
      let s01 = r0[0] * r1[1] - r0[1] * r1[0]
      let s02 = r0[0] * r1[2] - r0[2] * r1[0]
      let s03 = r0[0] * r1[3] - r0[3] * r1[0]
      let s12 = r0[1] * r1[2] - r0[2] * r1[1]
      let s13 = r0[1] * r1[3] - r0[3] * r1[1]
      let s23 = r0[2] * r1[3] - r0[3] * r1[2]
      let c01 = r2[0] * r3[1] - r2[1] * r3[0]
      let c02 = r2[0] * r3[2] - r2[2] * r3[0]
      let c03 = r2[0] * r3[3] - r2[3] * r3[0]
      let c12 = r2[1] * r3[2] - r2[2] * r3[1]
      let c13 = r2[1] * r3[3] - r2[3] * r3[1]
      let c23 = r2[2] * r3[3] - r2[3] * r3[2]
      s01 * c23 - s02 * c13 + s03 * c12 + s12 * c03 - s13 * c02 + s23 * c01
    }
    _ => {
      self.lu_decompose_internal().determinant_internal()
    }
  }
}

///|
/// Computes the inverse of a square matrix using LU decomposition with partial pivoting.
///
/// This method factorizes the matrix once and then solves against the identity
/// matrix. If successful, the resulting matrix is the inverse.
pub fn[T : Compare + Field + Num + Tolerance] Matrix::inverse(
  self : Matrix[T],
) -> Matrix[T]? {
  guard self.is_square() else {
    abort("Matrix must be square to compute inverse")
  }
  let n = self.row
  if n == 0 {
    return Some(Matrix::new(0, 0, T::zero()))
  }
  let lu = self.lu_decompose_internal()
  if lu.singular {
    return None
  }
  lu.solve_internal(identity(n))
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::is_invertible(
  self : Matrix[T],
) -> Bool {
  guard self.is_square() else {
    abort("Matrix must be square to check invertibility")
  }
  !self.lu_decompose_internal().singular
}

///|
/// Computes the Cholesky decomposition of a symmetric positive definite matrix.
///
/// Returns `Some(L)` where `L` is a lower triangular matrix such that `self = L * L.transpose()`.
/// Returns `None` if the matrix is not positive definite.
///
/// The algorithms is based on the Cholesky-Banachiewicz algorithm.
/// Time Complexity: O(n^3/3)
pub fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::cholesky_decomposition(
  self : Matrix[T],
) -> Matrix[T]? {
  if !self.is_symmetric() {
    return None
  }
  let n = self.row
  let l = Matrix::new(n, n, T::zero())
  for i in 0..<n {
    for j in 0..<=i {
      let mut sum = T::zero()
      for k in 0..<j {
        sum = sum + l.data[i][k] * l.data[j][k]
      }
      if i == j {
        let val = self.data[i][i] - sum
        if val <= T::tolerance() {
          return None
        }
        l.data[i][i] = val.sqrt()
      } else {
        l.data[i][j] = T::one() / l.data[j][j] * (self.data[i][j] - sum)
      }
    }
  }
  Some(l)
}

///|
pub fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::is_positive_definite(
  self : Matrix[T],
) -> Bool {
  match self.cholesky_decomposition() {
    Some(_) => true
    None => false
  }
}

///|
fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::eigen_2x2(
  self : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  let a = self.data[0][0]
  let b = self.data[0][1]
  let c = self.data[1][0]
  let d = self.data[1][1]
  let half = T::one() / (T::one() + T::one())
  let mid = (a + d) * half
  let det = a * d - b * c
  let disc_prime = mid * mid - det
  if disc_prime < -T::tolerance() {
    abort(
      "Matrix::eigen currently requires real eigenvalues; complex eigenvalues require luna complex support",
    )
  }
  let s = if disc_prime.abs() <= T::tolerance() {
    T::zero()
  } else {
    disc_prime.sqrt()
  }
  let l1 = mid + s
  let l2 = mid - s
  let mut v11 = T::one()
  let mut v21 = T::zero()
  let mut v12 = T::zero()
  let mut v22 = T::one()
  if b != T::zero() {
    v11 = b
    v21 = l1 - a
  } else if c != T::zero() {
    v11 = l1 - d
    v21 = c
  } else {
    v11 = T::one()
    v21 = T::zero()
  }
  if b != T::zero() {
    v12 = b
    v22 = l2 - a
  } else if c != T::zero() {
    v12 = l2 - d
    v22 = c
  } else {
    v12 = T::zero()
    v22 = T::one()
  }
  (Vector::from_array([l1, l2]), Matrix::from_array(2, 2, [v11, v12, v21, v22]))
}

///|
pub fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::eigen(
  self : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  guard self.is_square() else {
    abort("Matrix must be square to compute eigenvalues")
  }
  guard self.is_symmetric() else {
    abort(
      "Matrix::eigen currently supports only symmetric real matrices; general real matrices require complex eigenvalue support",
    )
  }
  if self.row == 2 && self.col == 2 {
    return self.eigen_2x2()
  }
  qr_algorithm(self)
}

///|
/// Reduces the matrix to Upper Hessenberg form using Householder similarity transformations.
/// Returns (H, Q) where H is the Hessenberg matrix and Q is the unitary matrix such that A = Q * H * Q^T.
fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::hessenberg_reduction(
  self : Matrix[T],
) -> (Matrix[T], Matrix[T]) {
  let n = self.row
  let h = self.copy()
  let q = identity(n)
  for k in 0..<(n - 2) {
    // Compute Householder vector for column k below diagonal
    let mut norm_sq = T::zero()
    for i in (k + 1)..<n {
      norm_sq = norm_sq + h.data[i][k] * h.data[i][k]
    }
    let norm = norm_sq.sqrt()
    // Skip if already zero
    if norm < T::tolerance() {
      continue
    }
    let alpha = if h.data[k + 1][k] > T::zero() { -norm } else { norm }
    let two = T::one() + T::one()
    let r = (T::one() / two * (alpha * alpha - h.data[k + 1][k] * alpha)).sqrt()
    let v = Array::make(n, T::zero())
    v[k + 1] = (h.data[k + 1][k] - alpha) / (two * r)
    for i in (k + 2)..<n {
      v[i] = h.data[i][k] / (two * r)
    }

    // Apply Householder transformation to H from left: P * H
    // H = H - 2 v v^T H
    // Let w = v^T H, then H = H - 2 v w
    let w = Array::make(n, T::zero())
    for j in k..<n {
      let mut sum = T::zero()
      for i in (k + 1)..<n {
        sum = sum + v[i] * h.data[i][j]
      }
      w[j] = sum
    }
    for i in (k + 1)..<n {
      for j in k..<n {
        h.data[i][j] = h.data[i][j] - two * v[i] * w[j]
      }
    }

    // Apply Householder transformation to H from right: H * P
    // H = H - 2 H v v^T
    // Let q_vec = H v, then H = H - 2 q_vec v^T
    let q_vec = Array::make(n, T::zero())
    for i in 0..<n {
      let mut sum = T::zero()
      for j in (k + 1)..<n {
        sum = sum + h.data[i][j] * v[j]
      }
      q_vec[i] = sum
    }
    for i in 0..<n {
      for j in (k + 1)..<n {
        h.data[i][j] = h.data[i][j] - two * q_vec[i] * v[j]
      }
    }

    // Accumulate Q: Q = Q * P
    // Q = Q - 2 Q v v^T
    // Let z = Q v, then Q = Q - 2 z v^T
    let z = Array::make(n, T::zero())
    for i in 0..<n {
      let mut sum = T::zero()
      for j in (k + 1)..<n {
        sum = sum + q.data[i][j] * v[j]
      }
      z[i] = sum
    }
    for i in 0..<n {
      for j in (k + 1)..<n {
        q.data[i][j] = q.data[i][j] - two * z[i] * v[j]
      }
    }
  }
  (h, q)
}

///|
fn[T : Compare + Num + Div + Sqrt + Tolerance] qr_algorithm(
  matrix : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  guard matrix.is_square() else {
    abort("qr_algorithm requires a square matrix")
  }
  guard matrix.is_symmetric() else {
    abort(
      "qr_algorithm currently supports only symmetric real matrices; general real matrices require complex eigenvalue support",
    )
  }
  let n = matrix.row
  let (h, q_total) = matrix.hessenberg_reduction()
  let a = h
  let mut m = n
  let max_iterations = 1000
  let tol = T::tolerance()
  while m > 1 {
    if a.data[m - 1][m - 2].abs() <= tol {
      a.data[m - 1][m - 2] = T::zero()
      m -= 1
      continue
    }
    let mut iter = 0
    while iter < max_iterations && a.data[m - 1][m - 2].abs() > tol {
      let two = T::one() + T::one()
      let d = (a.data[m - 2][m - 2] - a.data[m - 1][m - 1]) / two
      let b = a.data[m - 1][m - 2]
      let sign = if d < T::zero() { -T::one() } else { T::one() }
      let den = d.abs() + (d * d + b * b).sqrt()
      let mu = if den <= tol {
        a.data[m - 1][m - 1] - b.abs()
      } else {
        a.data[m - 1][m - 1] - sign * b * b / den
      }
      let mut x = a.data[0][0] - mu
      let mut z = a.data[1][0]
      for k in 0..<(m - 1) {
        let norm = (x * x + z * z).sqrt()
        if norm <= tol {
          if k + 1 < m - 1 {
            x = a.data[k + 1][k]
            z = a.data[k + 2][k]
          }
          continue
        }
        let c = x / norm
        let s = -z / norm
        for j in k..<m {
          let top = a.data[k][j]
          let bottom = a.data[k + 1][j]
          a.data[k][j] = c * top - s * bottom
          a.data[k + 1][j] = s * top + c * bottom
        }
        for i in 0..<m {
          let left = a.data[i][k]
          let right = a.data[i][k + 1]
          a.data[i][k] = c * left - s * right
          a.data[i][k + 1] = s * left + c * right
        }
        for i in 0..<n {
          let left = q_total.data[i][k]
          let right = q_total.data[i][k + 1]
          q_total.data[i][k] = c * left - s * right
          q_total.data[i][k + 1] = s * left + c * right
        }
        if k + 1 < m - 1 {
          x = a.data[k + 1][k]
          z = a.data[k + 2][k]
        }
      }
      iter += 1
    }
    if a.data[m - 1][m - 2].abs() <= tol {
      a.data[m - 1][m - 2] = T::zero()
    }
    m -= 1
  }
  let eigenvalues = Vector::makei(n, i => a.data[i][i])
  (eigenvalues, q_total)
}

///|
fn[T : Compare + Num + Div + Tolerance + Sqrt] qr_decomposition(
  matrix : Matrix[T],
) -> (Matrix[T], Matrix[T]) {
  let m = matrix.row
  let n = matrix.col
  let q = identity(m)
  let r = matrix.copy()
  let two = T::one() + T::one()
  let tol = T::tolerance()
  let limit = if m < n { m } else { n }
  for k in 0..<limit {
    let mut norm_sq = T::zero()
    for i in k..<m {
      norm_sq += r.data[i][k] * r.data[i][k]
    }
    let norm = norm_sq.sqrt()
    if norm <= tol {
      continue
    }
    let alpha = if r.data[k][k] >= T::zero() { -norm } else { norm }
    let v = Array::make(m - k, T::zero())
    v[0] = r.data[k][k] - alpha
    for i in (k + 1)..<m {
      v[i - k] = r.data[i][k]
    }
    let mut vnorm_sq = T::zero()
    for i in 0..<v.length() {
      vnorm_sq += v[i] * v[i]
    }
    let vnorm = vnorm_sq.sqrt()
    if vnorm <= tol {
      continue
    }
    for i in 0..<v.length() {
      v[i] /= vnorm
    }
    for j in k..<n {
      let mut dot = T::zero()
      for i in 0..<v.length() {
        dot += v[i] * r.data[k + i][j]
      }
      for i in 0..<v.length() {
        r.data[k + i][j] -= two * v[i] * dot
      }
    }
    for i in 0..<m {
      let mut dot = T::zero()
      for t in 0..<v.length() {
        dot += q.data[i][k + t] * v[t]
      }
      for t in 0..<v.length() {
        q.data[i][k + t] -= two * dot * v[t]
      }
    }
    for i in (k + 1)..<m {
      if r.data[i][k].abs() <= tol {
        r.data[i][k] = T::zero()
      }
    }
  }
  let q_out = Matrix::new(m, n, T::zero())
  for i in 0..<m {
    for j in 0..<n {
      q_out.data[i][j] = q.data[i][j]
    }
  }
  let r_out = Matrix::new(n, n, T::zero())
  let row_limit = if m < n { m } else { n }
  for i in 0..<row_limit {
    for j in 0..<n {
      r_out.data[i][j] = r.data[i][j]
    }
  }
  (q_out, r_out)
}

///|
pub trait Tolerance {
  tolerance() -> Self
}

///|
pub impl Tolerance for Double with tolerance() -> Double {
  0.00000000001
}

///|
pub impl Tolerance for Float with tolerance() -> Float {
  0.00000000001
}

///|
pub trait Sqrt {
  sqrt(Self) -> Self
}

///|
pub impl Sqrt for Double with sqrt(a) -> Double {
  Double::sqrt(a)
}

///|
pub impl Sqrt for Float with sqrt(a) -> Float {
  Float::sqrt(a)
}
