///|
pub struct Matrix[T] {
  row : Int
  col : Int
  data : Array[Array[T]]
} derive(Eq)

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
pub fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Array[T] {
  self.data[row]
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
#alias(map_in_place, deprecated)
pub fn[T] Matrix::map_inplace(self : Matrix[T], f : (T) -> T) -> Unit {
  self.data.each(fn(row) { row.map_in_place(f) })
}

///|
pub fn[T] Matrix::to_transpose(self : Matrix[T]) -> Transpose[T] {
  Transpose(self)
}

///|
#alias(map_row_in_place, deprecated)
pub fn[T] Matrix::map_row_inplace(
  self : Matrix[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  self.data[row].map_in_place(f)
}

///|
#alias(map_col_in_place, deprecated)
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
  self.map(T::conjugate)
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
  // Use array collection fallback to avoid Iter::new issues
  let arr = []
  for i in 0..<self.row {
    arr.push(self.data[i][col])
  }
  arr.iter()
}

///|
pub fn[T : @internal.HomomorphismNat] Matrix::from_nat_matrix(
  self : Matrix[Int],
) -> Matrix[T] {
  self.map(@internal.HomomorphismNat::from_nat)
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::power_method(
  self : Matrix[T],
  max_iterations : Int,
) -> (T, Vector[T]) {
  guard self.is_square() else {
    abort("Matrix must be square for power method")
  }
  let n = self.row
  let mut x = Vector::makei(n, fn(_) { T::one() })
  let mut lambda = T::zero()
  for _ in 0..<max_iterations {
    let y = self.mul_vec(x)
    let mut max_val = T::zero()
    for i in 0..<n {
      if y[i].abs() > max_val.abs() {
        max_val = y[i]
      }
    }
    let new_lambda = max_val
    x = y.map(fn(v) { v / new_lambda })
    if (new_lambda - lambda).abs() < Tolerance::tolerance() {
      return (new_lambda, x)
    }
    lambda = new_lambda
  }
  (lambda, x)
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
  let data = Array::makei(self.row, fn(i) {
    let new_row = Array::make(new_col, self.data[0][0])
    let row_self = self.data[i]
    for j in 0..<self.col {
      new_row[j] = row_self[j]
    }
    let row_other = other.data[i]
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
pub fn[T : Add + Div + @internal.HomomorphismNat] Matrix::mean(
  self : Matrix[T],
) -> T {
  let mut sum = T::from_nat(0)
  self.each(fn(x) { sum = sum + x })
  let count = self.row * self.col
  sum / T::from_nat(count)
}

///|
pub fn[T : Add + Sub + Mul + Div + @internal.HomomorphismNat] Matrix::variance(
  self : Matrix[T],
) -> T {
  let m = self.mean()
  let mut sum_sq_diff = T::from_nat(0)
  self.each(fn(x) {
    let diff = x - m
    sum_sq_diff = sum_sq_diff + diff * diff
  })
  let count = self.row * self.col
  sum_sq_diff / T::from_nat(count)
}

///|
pub fn[T : Add + Sub + Mul + Div + Sqrt + @internal.HomomorphismNat] Matrix::std_dev(
  self : Matrix[T],
) -> T {
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
    ignore(self.swap_rows(i, max_row))
    if self.data[i][col] == T::zero() {
      col = col + 1
      continue
    }
    let val = self.data[i][col]
    ignore(self.map_row_inplace(i, fn(x) { x * val.inv() }))
    for j in 0..<r {
      if j == i {
        continue
      }
      let factor = self.data[j][col]
      for k in 0..<c {
        self.data[j][k] = self.data[j][k] - self.data[i][k] * factor
      }
    }
    col = col + 1
  }
  self
}

///|
pub fn[T : Compare + Num + Inverse] Matrix::rank(self : Matrix[T]) -> Int {
  let m = self.copy()
  let _ = m.reduce_row_elimination()
  let mut rank = 0
  for i in 0..<m.row {
    for j in 0..<m.col {
      if m.data[i][j] != T::zero() {
        rank += 1
        break
      }
    }
  }
  rank
}

///|
pub fn[T : Semiring] Matrix::pow(self : Matrix[T], power : Int) -> Matrix[T] {
  loop (identity(self.col), power, self) {
    (s, 0, _) => s
    (s, 1, m) => s * m
    (s, p, m) => continue (if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m)
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
  let m = self.copy()
  let n = m.row
  if n == 0 {
    return T::one()
  }
  let mut det_sign = T::one()
  for j in 0..<n {
    let mut max_row = j
    for i in (j + 1)..<n {
      if m.data[i][j].abs() > m.data[max_row][j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      m.swap_rows(j, max_row)
      det_sign = -det_sign
    }
    let pivot = m.data[j][j]
    if pivot.abs() < T::tolerance() {
      return T::zero()
    }
    for i in (j + 1)..<n {
      let factor = m.data[i][j] / pivot
      for k in (j + 1)..<n {
        m.data[i][k] -= factor * m.data[j][k]
      }
    }
  }
  let mut det = det_sign
  for i in 0..<n {
    det *= m.data[i][i]
  }
  det
}

///|
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
  if not(self.is_invertible()) {
    return None
  }
  let identity_matrix = identity(n)
  let augmented = self.horizontal_combine(identity_matrix)
  let reduced = augmented.reduce_row_elimination()
  let inverse_matrix = Matrix::make(n, n, fn(i, j) { reduced.data[i][j + n] })
  return Some(inverse_matrix)
}

///|
pub fn[T : Compare + Num + Div + Tolerance] Matrix::is_invertible(
  self : Matrix[T],
) -> Bool {
  guard self.is_square() else {
    abort("Matrix must be square to check invertibility")
  }
  let det = self.determinant()
  return det.abs() > T::tolerance()
}

///|
pub fn[T : Compare + Num + Div + Sqrt + Tolerance] Matrix::is_positive_definite(
  self : Matrix[T],
) -> Bool {
  if not(self.is_symmetric()) {
    return false
  }
  let (eigenvals, _) = self.eigen()
  for val in eigenvals {
    if val <= T::zero() {
      return false
    }
  }
  true
}

///|
fn[T : Compare + Num + Div + Sqrt] Matrix::eigen_2x2(
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
  let (l1, l2) = if disc_prime >= T::zero() {
    let s = disc_prime.sqrt()
    (mid + s, mid - s)
  } else {
    (mid, mid)
  }
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
    abort("Matrix must be square for eigenvalue computation")
  }
  if self.row == 2 && self.col == 2 {
    return self.eigen_2x2()
  }
  qr_algorithm(self)
}

///|
fn[T : Compare + Num + Div + Sqrt + Tolerance] qr_algorithm(
  matrix : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  let n = matrix.row
  let a = matrix.copy()
  let q_total = identity(n)
  let mut m = n
  let max_iterations = 1000
  while m > 1 {
    let mut iter = 0
    while iter < max_iterations {
      if a.data[m - 1][m - 2].abs() <= T::tolerance() {
        break
      }
      let two = T::one() + T::one()
      let d = (a.data[m - 2][m - 2] - a.data[m - 1][m - 1]) / two
      let mut sgn = T::one()
      if d < T::zero() {
        sgn = -T::one()
      }
      let a_m1_m2 = a.data[m - 1][m - 2]
      let num = sgn * a_m1_m2 * a_m1_m2
      let den = d.abs() + (d * d + a_m1_m2 * a_m1_m2).sqrt()
      let mu = a.data[m - 1][m - 1] - num / den
      for i in 0..<m {
        a.data[i][i] -= mu
      }
      let sub_a = Matrix::new(m, m, T::zero())
      for i in 0..<m {
        for j in 0..<m {
          sub_a.data[i][j] = a.data[i][j]
        }
      }
      let (sub_q, sub_r) = qr_decomposition(sub_a)
      let new_sub_a = sub_r * sub_q
      for i in 0..<m {
        for j in 0..<m {
          a.data[i][j] = new_sub_a.data[i][j]
        }
        a.data[i][i] += mu
      }
      let temp_cols = Matrix::new(n, m, T::zero())
      for i in 0..<n {
        for j in 0..<m {
          let mut sum = T::zero()
          for k in 0..<m {
            sum += q_total.data[i][k] * sub_q.data[k][j]
          }
          temp_cols.data[i][j] = sum
        }
      }
      for i in 0..<n {
        for j in 0..<m {
          q_total.data[i][j] = temp_cols.data[i][j]
        }
      }
      iter += 1
    }
    m -= 1
  }
  let eigenvalues = Vector::makei(n, i => a.data[i][i])
  (eigenvalues, q_total)
}

///|
fn[T : Compare + AddMonoid + Sub + Mul + Div + Tolerance + Sqrt] qr_decomposition(
  matrix : Matrix[T],
) -> (Matrix[T], Matrix[T]) {
  let m = matrix.row
  let n = matrix.col
  let q = Matrix::new(m, n, T::zero())
  let r = Matrix::new(n, n, T::zero())
  for j in 0..<n {
    for i in 0..<m {
      q.data[i][j] = matrix.data[i][j]
    }
    for k in 0..<j {
      let mut dot_product = T::zero()
      for i in 0..<m {
        dot_product += q.data[i][k] * q.data[i][j]
      }
      r.data[k][j] = dot_product
      for i in 0..<m {
        q.data[i][j] -= r.data[k][j] * q.data[i][k]
      }
    }
    let mut norm = T::zero()
    for i in 0..<m {
      norm += q.data[i][j] * q.data[i][j]
    }
    norm = norm.sqrt()
    r.data[j][j] = norm
    if norm > T::tolerance() {
      for i in 0..<m {
        q.data[i][j] /= norm
      }
    }
  }
  (q, r)
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
