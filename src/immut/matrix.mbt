///|
/// Define a new type called Matrix, which is a 2D array of 
/// elements of type T and have derived the Eq trait.
/// 
/// Parameters:
/// - `row`: The number of rows in the matrix.
/// - `col`: The number of columns in the matrix.
/// - `data`: The data of the matrix, which is stored as an immutable vector.
/// 
struct Matrix[T] {
  row : Int
  col : Int
  data : VecLib[T]
} derive(Eq)

///|
pub impl[T] HasShape for Matrix[T] with shape(self) {
  (self.row, self.col)
}

///|
/// Wrapper type enabling indexed access to elements of a container, typically
/// used for row access in matrices.
///
/// The `Indexed[T]` type encapsulates a function that maps integer indices to
/// values of type `T`. This design allows for efficient access to elements at
/// specific positions within a data structure, commonly employed to represent
/// individual rows of a matrix where column indices can be used to retrieve
/// specific elements.
///
/// Fields:
///
/// * `index` : Function that takes an integer index and returns the
///   corresponding element of type `T`.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row = m[0]  // Returns Indexed[Int] for the first row
/// inspect(row[1], content="2")  // Access second element of first row
/// ```
///
struct Indexed[T] {
  index : (Int) -> T
}

///|
/// Returns the number of rows in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to get the row count from.
///
/// Returns the number of rows as an integer.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(m.row(), content="2")
/// ```
///
pub fn[T] Matrix::row(self : Matrix[T]) -> Int {
  self.row
}

///|
/// Returns the number of columns in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to get the column count from.
///
/// Returns the number of columns as an integer.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(m.col(), content="3")
/// ```
///
pub fn[T] Matrix::col(self : Matrix[T]) -> Int {
  self.col
}

///|
/// Converts a matrix to its string representation. The resulting string displays
/// the matrix in a row-by-row format, with each row enclosed in vertical bars
/// (|) and elements separated by commas.
///
/// Parameters:
///
/// * `self` : The matrix to be converted to string. Elements in the matrix
/// must implement the `Show` trait.
///
/// Returns a string representation of the matrix.
///
/// Example:
///
/// ```moonbit
///   let m = Matrix::from_2d_array([[1, 2], [3, 4]])
///   inspect(
///     m.to_string(),
///     content=
///       #||1, 2|
///       #||3, 4|
///     ,
///   )
/// ```
pub impl[T : Show] Show for Matrix[T] with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
/// Writes the string representation of a matrix to a buffer.
///
/// Parameters:
///
/// * `self` : The matrix to be written to the buffer. The elements in the
/// matrix must implement the `Show` trait.
/// * `logger` : A buffer to write the string representation to.
///
/// Example:
///
/// ```moonbit
///   let m = Matrix::from_2d_array([[1, 2], [3, 4]])
///   let buf = @buffer.new(size_hint=0)
///   m.output(buf)
///   inspect(
///     buf.to_string(),
///     content=
///       #||1, 2|
///       #||3, 4|
///     ,
///   )
/// ```
pub impl[T : Show] Show for Matrix[T] with output(self, logger) {
  for i in 0..<self.row {
    logger.write_char('|')
    for j in 0..<self.col {
      logger.write_object(self.data[i * self.col + j])
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
/// Apply `map` method to the `Matrix` type.
/// 
/// Parameters
/// - `self`: The matrix to apply the map method.
/// - `f`: The function to apply to each element of the matrix.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
/// let m2 = m.map(fn(x) { x * 2 })
/// inspect(m2, content=
///   #||4, 6, 8|
///   #||2, 4, 6|
/// )
/// ```
/// 
pub fn[T, U] Matrix::map(self : Matrix[T], f : (T) -> U) -> Matrix[U] {
  { row: self.row, col: self.col, data: self.data.map(f) }
}

///|
/// Apply `mapi` method to the `Matrix` type.
/// 
/// Parameters
/// - `self`: The matrix to apply the map method.
/// - `f`: The function to apply to each element of the matrix. The function takes the row index, column index and the element.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = m.mapi(fn(i, j, x) { x + i + j })
/// inspect(m2, content=
///   #||1, 3|
///   #||4, 6|
/// )
/// ```
pub fn[T, U] Matrix::mapi(
  self : Matrix[T],
  f : (Int, Int, T) -> U,
) -> Matrix[U] {
  let row = self.row
  let col = self.col
  let data = Vector::makei(row * col, fn(i) {
    f(i / col, i % col, self.data[i])
  })
  { row, col, data }
}

///|
/// Create a new `Matrix` type.
/// 
/// Parameters
/// - `row`: The number of rows in the matrix.
/// - `col`: The number of columns in the matrix.
/// - `f`: The function to apply to each element of the matrix.
///
/// Example
/// ```moonbit
/// let m = Matrix::make(2, 3, fn(i, j) { i + j })
/// inspect(m, content=
///   #||0, 1, 2|
///   #||1, 2, 3|
/// )
/// ```
/// 
pub fn[T] Matrix::make(row : Int, col : Int, f : (Int, Int) -> T) -> Matrix[T] {
  if row == 0 || col == 0 {
    return { row, col, data: Vector::from_array([]) }
  }
  {
    row,
    col,
    data: Vector::makei(row * col, fn(i) { f(i / col, i % col) }),
  }
}

///|
/// Create a new `Matrix` type with all elements initialized 
/// to a given value.
/// 
/// Parameters
/// - `row`: The number of rows in the matrix.
/// - `col`: The number of columns in the matrix.
/// - `elem`: The value to initialize the matrix with.
///
/// Example
/// ```moonbit
/// let m = Matrix::new(2, 3, 0)
/// inspect(m, content=
///   #||0, 0, 0|
///   #||0, 0, 0|
/// )
/// ```
/// 
pub fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T] {
  Matrix::make(row, col, (_, _) => elem)
}

///|
/// Shift the `Array[Array[T]]` type to the `Matrix` type.
/// 
/// Parameters
/// - `arr`: The array to shift to the `Matrix` type.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
/// inspect(m, content =
///   #||2, 3, 4|
///   #||1, 2, 3|
/// )
/// ```
pub fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T] {
  if arr.is_empty() {
    return { row: 0, col: 0, data: Vector::from_array([]) }
  }
  let col = arr[0].length()
  for row in arr {
    guard row.length() == col else {
      abort("Matrix rows must all have the same length")
    }
  }
  Matrix::make(arr.length(), col, fn(i, j) { arr[i][j] })
}

///|
/// Creates a new matrix from a one-dimensional immutable array with specified
/// dimensions.
///
/// Parameters:
///
/// * `row` : The number of rows in the resulting matrix.
/// * `col` : The number of columns in the resulting matrix.
/// * `arr` : The immutable vector containing the matrix elements in row-major
///   order.
///
/// Returns a new matrix with the specified dimensions containing the elements
/// from the array.
///
/// Panics if the length of the array does not equal `row * col`.
///
/// Example:
///
/// ```moonbit
/// let arr = Vector::from_array([1, 2, 3, 4, 5, 6])
/// let m = Matrix::from_array(2, 3, arr)
/// inspect(m, content=
///   #||1, 2, 3|
///   #||4, 5, 6|
/// )
/// ```
///
pub fn[T] Matrix::from_array(
  row : Int,
  col : Int,
  arr : VecLib[T],
) -> Matrix[T] {
  guard arr.length() == row * col else {
    abort("Invalid array length for matrix")
  }
  Matrix::{ row, col, data: arr }
}

///|
/// Get the `Indexed` type from the `Matrix` type.
/// You can get the whole row data of the matrix by using the `Indexed` type.
/// 
/// Parameters
/// - `self`: The matrix to get the indexed type from.
/// - `row`: The row index to get the data from.
pub fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Indexed[T] {
  { index: c => self.data[c + self.col * row] }
}

///|
/// From the `Indexed` type, you can get the element of the 
/// matrix by using this method.
/// 
/// Parameters
/// - `self`: The indexed type to get the element from.
/// - `col`: The column index to get the element from.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
/// inspect(m[0][1], content="3")
/// ```
/// 
pub fn[T] Indexed::op_get(self : Indexed[T], col : Int) -> T {
  (self.index)(col)
}

///|
/// Creates a new matrix with the element at the specified position replaced with
/// a new value.
///
/// Parameters:
///
/// * `self` : The original matrix.
/// * `row` : The row index of the element to be replaced (zero-based).
/// * `col` : The column index of the element to be replaced (zero-based).
/// * `value` : The new value to replace the original element.
///
/// Returns a new matrix with the element at position (row, col) replaced with
/// the specified value.
///
/// Example:
///
/// ```moonbit
///   let m = Matrix::from_2d_array([[1, 2], [3, 4]])
///   let m2 = m.set(0, 1, 5)
///   inspect(
///     m2,
///     content=
///       #||1, 5|
///       #||3, 4|
///     ,
///   )
/// ```
pub fn[T] Matrix::set(
  self : Matrix[T],
  i : Int,
  j : Int,
  elem : T,
) -> Matrix[T] {
  { row: self.row, col: self.col, data: self.data.set(i * self.col + j, elem) }
}

///|
/// Multiplies two matrices.
/// 
/// Parameters
/// - `self`: The left matrix.
/// - `other`: The right matrix.
/// 
/// Example
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 1], [0, 1]])
/// let m3 = m1 * m2
/// inspect(m3, content=
///   #||1, 3|
///   #||3, 7|
/// )
/// ```
pub impl[T : Mul + Add + Zero] Mul for Matrix[T] with mul(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  ensure_mul_compatible(self, other)
  if row == 0 || col == 0 {
    return Matrix::make(row, col, fn(_, _) { abort("unreachable") })
  }
  if inner == 0 {
    return Matrix::new(row, col, T::zero())
  }
  let left_data = self.data
  let right_data = other.data
  let right_t = Vector::makei(col * inner, fn(idx) {
    let out_col = idx / inner
    let k = idx % inner
    right_data[k * col + out_col]
  })
  let data = Vector::makei(row * col, fn(i) {
    let r = i / col
    let c = i % col
    let left_offset = r * inner
    let right_offset = c * inner
    let mut sum = left_data[left_offset] * right_t[right_offset]
    for k in 1..<inner {
      sum = sum + left_data[left_offset + k] * right_t[right_offset + k]
    }
    sum
  })
  { row, col, data }
}

///|
/// Adds two matrices.
/// 
/// Parameters
/// - `self`: The left matrix.
/// - `other`: The right matrix.
///
/// Example
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 1], [0, 1]])
/// let m3 = m1 + m2
/// inspect(m3, content=
///   #||2, 3|
///   #||3, 5|
/// )
/// ```
pub impl[T : Add] Add for Matrix[T] with add(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.col == other.col
  guard self.row == other.row
  {
    data: self.data.zip_with(other.data, T::add),
    row: self.row,
    col: self.col,
  }
}

///|
/// Negates all elements of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to negate.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = -m
/// inspect(m1, content=
///   #||-1, -2|
///   #||-3, -4|
/// )
/// ```
pub impl[T : Neg] Neg for Matrix[T] with neg(self : Matrix[T]) -> Matrix[T] {
  self.map(T::neg)
}

///|
/// Subtracts two matrices.
/// 
/// Parameters
/// - `self`: The left matrix.
/// - `other`: The right matrix.
/// 
/// Example
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 1], [0, 1]])
/// let m3 = m1 - m2
/// inspect(m3, content=
///   #||0, 1|
///   #||3, 3|
/// )
/// ```
pub impl[T : Add + Neg] Sub for Matrix[T] with sub(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  self + -other
}

///|
/// Scales all elements of a matrix by a constant value.
/// 
/// Parameters
/// - `self`: The matrix to scale.
/// - `cst`: The constant value to scale the matrix by.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = m.scale(10)
/// inspect(m1, content=
///   #||10, 20|
///   #||30, 40|
/// )
/// ```
pub fn[T : Mul] Matrix::scale(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x * cst })
}

///|
/// Adds a constant value to all elements of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to add the constant value to.
/// - `cst`: The constant value to add to the matrix.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = m.add_constant(10)
/// inspect(m1, content=
///   #||11, 12|
///   #||13, 14|
/// )
/// ```
pub fn[T : Add] Matrix::add_constant(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(fn(x) { x + cst })
}

///|
/// Creates an identity matrix of a given size.
/// 
/// Parameters
/// - `size`: The size of the identity matrix to create.
/// 
/// Example
/// ```moonbit
/// let m : Matrix[Int] = Matrix::identity(3)
/// inspect(m, content=
///   #||1, 0, 0|
///   #||0, 1, 0|
///   #||0, 0, 1|
/// )
/// ```
pub fn[T : One + Zero] Matrix::identity(size : Int) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
/// Checks if a matrix is a null matrix.
/// 
/// Parameters
/// - `self`: The matrix to check.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[0, 0], [0, 0]])
/// inspect(m.null(), content="true")
/// ```
pub fn[T : Compare + Zero] Matrix::null(self : Matrix[T]) -> Bool {
  !self.data.iter().any(fn(x) { x != T::zero() })
}

///|
/// Computes the adjoint of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to compute the adjoint of.
pub fn[T : Conjugate] Matrix::adjoint(self : Matrix[T]) -> Matrix[T] {
  self.transpose().map(T::conjugate)
}

///|
/// Computes the transpose of a matrix by swapping its rows and columns. The
/// transpose of an m × n matrix is an n × m matrix where the element at position
/// (i, j) in the original matrix becomes the element at position (j, i) in the
/// transposed matrix.
///
/// Parameters:
///
/// * `matrix` : The input matrix to be transposed.
///
/// Returns a new matrix that is the transpose of the input matrix.
///
/// Example:
///
/// ```moonbit
///   let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
///   inspect(
///     m.transpose(),
///     content=
///       #||1, 4|
///       #||2, 5|
///       #||3, 6|
///     ,
///   )
/// ```
pub fn[T] Matrix::transpose(self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) { self[j][i] })
}

///|
/// Computes the trace of a matrix (the sum of the diagonal elements).
/// 
/// Parameters
/// - `self`: The matrix to compute the trace of.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// inspect(m.trace(), content="5")
/// ```
pub fn[T : Add + Zero] Matrix::trace(self : Matrix[T]) -> T {
  guard self.is_square() else { abort("Matrix must be square to calculate trace") }
  let n = self.row
  let mut sum = T::zero()
  for i in 0..<n {
    sum = sum + self[i][i]
  }
  sum
}

///|
/// Checks if the matrix is square (i.e., has the same number of rows and columns).
/// 
/// Parameters:
/// * `self` : The matrix to check for squareness.
/// 
/// Returns `true` if the matrix is square, `false` otherwise.
/// 
/// Example:
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(m1.is_square(), content="true")  // 2x2 matrix is
/// inspect(m2.is_square(), content="false") // 2x3 matrix is not square
/// ```
pub fn[T] Matrix::is_square(self : Matrix[T]) -> Bool {
  self.row == self.col
}

///|
/// Make a iterator over the matrix elements.
/// 
/// Parameters:
/// * `self` : The matrix to iterate over.
/// 
/// Returns an iterator that yields each element of the matrix in row-major
/// 
/// Example:
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let iter = m.iter()
/// inspect(iter.collect(), content="[1, 2, 3, 4]") // Collects all elements in row-major order
/// ```
pub fn[T] Matrix::iter(self : Matrix[T]) -> Iter[T] {
  self.data.iter()
}

///|
/// Creates an iterator over the elements of a specific row in the matrix.
/// 
/// Parameters:
/// * `self` : The matrix to iterate over.
/// * `row` : The zero-based index of the row to iterate.
/// 
/// Returns an iterator that yields each element in the specified row from left to right.
/// 
/// Panics if `row` is negative or greater than or equal to the number of rows.
/// 
/// Example:
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_iter = m.iter_row(1)
/// for elem in row_iter {
///   println(elem) // prints: 4, 5, 6
/// }
/// ```
pub fn[T] Matrix::iter_row(self : Matrix[T], row : Int) -> Iter[T] {
  guard row >= 0 && row < self.row else { abort("Row index out of bounds") }
  let start = row * self.col
  let end = start + self.col
  let mut i = start
  Iter::new(() => if i < end {
    let value = self.data[i]
    i = i + 1
    Some(value)
  } else {
    None
  }).iter()
}

///|
/// Creates an iterator over the elements of a specific column in the matrix.
/// 
/// Parameters:
/// * `self` : The matrix to iterate over.
/// * `col` : The zero-based index of the column to iterate.
/// 
/// Returns an iterator that yields each element in the specified column from top to bottom.
/// 
/// Panics if `col` is negative or greater than or equal to the number of columns.
/// 
/// Example:
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let col_iter = m.iter_col(1)
/// for elem in col_iter {
///   println(elem) // prints: 2, 5
/// }
/// ```
pub fn[T] Matrix::iter_col(self : Matrix[T], col : Int) -> Iter[T] {
  guard col >= 0 && col < self.col else { abort("Column index out of bounds") }
  let mut i = 0
  Iter::new(() => if i < self.row {
    let value = self.data[i * self.col + col]
    i = i + 1
    Some(value)
  } else {
    None
  }).iter()
}

///|
/// Creates a copy of the matrix's underlying data as a new array.
///
/// Parameters:
///
/// * `self` : The matrix whose data will be copied.
///
/// Returns a new array containing all elements of the matrix in row-major
/// order.
///
/// Example:
///
/// ```moonbit
/// let matrix = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let array = matrix.to_array()
/// inspect(array, content="[1, 2, 3, 4, 5, 6]")
/// ```
///
pub fn[T] Matrix::to_array(self : Matrix[T]) -> Array[T] {
  let arr = []
  self.data.iter().each(fn(x) { arr.push(x) })
  arr
}

///|
/// Converts a matrix to a 2D array representation where each sub-array
/// represents a row of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to convert to a 2D array.
///
/// Returns a 2D array where each element is an array representing a row from
/// the original matrix, preserving the order of rows and elements within each
/// row.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let array_2d = m.to_2d_array()
/// inspect(array_2d, content="[[1, 2, 3], [4, 5, 6]]")
/// ```
///
pub fn[T] Matrix::to_2d_array(self : Matrix[T]) -> Array[Array[T]] {
  let row = self.row
  let arr_2d = []
  for i in 0..<row {
    let row_arr = []
    for j in 0..<self.col {
      row_arr.push(self.data[i * self.col + j])
    }
    arr_2d.push(row_arr)
  }
  arr_2d
}

///|
fn[T] swap_dense_rows(data : Array[T], row_size : Int, r1 : Int, r2 : Int) -> Unit {
  if r1 == r2 {
    return
  }
  let offset1 = r1 * row_size
  let offset2 = r2 * row_size
  for j in 0..<row_size {
    let temp = data[offset1 + j]
    data[offset1 + j] = data[offset2 + j]
    data[offset2 + j] = temp
  }
}

///|
/// Compute the determinant of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to compute the determinant of.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// inspect(m.determinant(), content="-2")
/// ```
pub fn[T : Compare + Num + Div] Matrix::determinant(
  self : Matrix[T],
) -> T {
  let n = self.row
  ensure_square(self)
  match n {
    0 => T::one()
    1 => self.data[0]
    2 => {
      let a = self.data
      a[0] * a[3] - a[1] * a[2]
    }
    3 => {
      let a = self.data
      a[0] * (a[4] * a[8] - a[5] * a[7]) -
      a[1] * (a[3] * a[8] - a[5] * a[6]) +
      a[2] * (a[3] * a[7] - a[4] * a[6])
    }
    4 => {
      let a = self.data
      let s01 = a[0] * a[5] - a[1] * a[4]
      let s02 = a[0] * a[6] - a[2] * a[4]
      let s03 = a[0] * a[7] - a[3] * a[4]
      let s12 = a[1] * a[6] - a[2] * a[5]
      let s13 = a[1] * a[7] - a[3] * a[5]
      let s23 = a[2] * a[7] - a[3] * a[6]
      let c01 = a[8] * a[13] - a[9] * a[12]
      let c02 = a[8] * a[14] - a[10] * a[12]
      let c03 = a[8] * a[15] - a[11] * a[12]
      let c12 = a[9] * a[14] - a[10] * a[13]
      let c13 = a[9] * a[15] - a[11] * a[13]
      let c23 = a[10] * a[15] - a[11] * a[14]
      s01 * c23 - s02 * c13 + s03 * c12 + s12 * c03 - s13 * c02 + s23 * c01
    }
    _ => {
      let work = self.to_array()
      let mut sign = T::one()
      for k in 0..<(n - 1) {
        let mut pivot_row = k
        let mut pivot_abs = work[k * n + k].abs()
        for i in (k + 1)..<n {
          let candidate = work[i * n + k].abs()
          if candidate > pivot_abs {
            pivot_abs = candidate
            pivot_row = i
          }
        }
        if work[pivot_row * n + k] == T::zero() {
          return T::zero()
        }
        if pivot_row != k {
          swap_dense_rows(work, n, pivot_row, k)
          sign = -sign
        }
        let pivot = work[k * n + k]
        let denom = if k == 0 { T::one() } else { work[(k - 1) * n + (k - 1)] }
        for i in (k + 1)..<n {
          let left = work[i * n + k]
          for j in (k + 1)..<n {
            let idx = i * n + j
            work[idx] = (work[idx] * pivot - left * work[k * n + j]) / denom
          }
          work[i * n + k] = T::zero()
        }
      }
      sign * work[n * n - 1]
    }
  }
}

///|
/// Raises a matrix to a power. Power must be a non-negative integer.
/// 
/// Parameters
/// - `self`: The matrix to raise to a power.
/// - `power`: The power to raise the matrix to.
/// 
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = m.pow(2)
/// inspect(m1, content=
///   #||7, 10|
///   #||15, 22|
/// )
/// ```
pub fn[T : Semiring] Matrix::pow(self : Matrix[T], power : Int) -> Matrix[T] {
  guard self.is_square() else {
    abort("Matrix must be square to calculate powers")
  }
  guard power >= 0 else {
    abort("Matrix::pow requires a non-negative exponent")
  }
  for state = Matrix::identity(self.col), exp = power, base = self {
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
/// Combines two matrices horizontally by concatenating their columns.
/// The rows of this two matrices must be the same.
/// 
/// Parameters
/// - `self`: The left matrix.
/// - `other`: The right matrix.
/// 
/// Example
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
/// let m3 = m1.horizontal_combine(m2)
/// inspect(m3, content=
///   #||1, 2, 1, 0|
///   #||3, 4, 0, 1|
/// )
/// ```
pub fn[T] Matrix::horizontal_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let r1 = self.row
  let c1 = self.col
  let r2 = other.row
  let c2 = other.col
  guard r1 == r2
  Matrix::make(r1, c1 + c2, fn(i, j) {
    if j < c1 {
      self[i][j]
    } else {
      other[i][j - c1]
    }
  })
}

///|
/// Combines two matrices vertically by concatenating their rows.
/// The columns of this two matrices must be the same.
/// 
/// Parameters
/// - `self`: The left matrix.
/// - `other`: The right matrix.
/// 
/// Example
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
/// let m3 = m1.vertical_combine(m2)
/// inspect(m3, content=
///   #||1, 2|
///   #||3, 4|
///   #||1, 0|
///   #||0, 1|
/// )
/// ```
pub fn[T] Matrix::vertical_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let r1 = self.row
  let r2 = other.row
  let c1 = self.col
  let c2 = other.col
  guard c1 == c2
  Matrix::make(r1 + r2, c1, fn(i, j) {
    if i < r1 {
      self[i][j]
    } else {
      other[i - r1][j]
    }
  })
}

///|
/// Swaps two rows of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to swap the rows of.
/// - `r1`: The index of the first row to swap.
/// - `r2`: The index of the second row to swap.
///
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = m.swap_rows(0, 1)
/// inspect(m1, content=
///   #||3, 4|
///   #||1, 2|
/// )
/// ```
pub fn[T] Matrix::swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Matrix[T] {
  guard r1 < self.row && r2 < self.row
  guard r1 >= 0 && r2 >= 0
  guard r1 != r2
  let new_matrix = Matrix::make(self.row, self.col, fn(i, j) {
    if i == r1 {
      self[r2][j]
    } else if i == r2 {
      self[r1][j]
    } else {
      self[i][j]
    }
  })
  new_matrix
}

///|
/// Swaps two columns of a matrix. The c1 and c2 must be less than
/// the number of columns in the matrix.
/// 
/// Parameters
/// - `self`: The matrix to swap the columns of.
/// - `c1`: The index of the first column to swap.
/// - `c2`: The index of the second column to swap.
///
/// Example
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m1 = m.swap_cols(0, 1)
/// inspect(m1, content=
///   #||2, 1|
///   #||4, 3|
/// )
/// ```
pub fn[T] Matrix::swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Matrix[T] {
  guard c1 < self.col && c2 < self.col
  guard c1 >= 0 && c2 >= 0
  guard c1 != c2
  let new_matrix = Matrix::make(self.row, self.col, fn(i, j) {
    if j == c1 {
      self[i][c2]
    } else if j == c2 {
      self[i][c1]
    } else {
      self[i][j]
    }
  })
  new_matrix
}
