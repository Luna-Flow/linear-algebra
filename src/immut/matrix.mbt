///|
/// Create a new type called IArray, which is an alias for 
/// the immutable array type.
/// 
typealias @immut/array.T as IArray

///|
/// Define a new type called Matrix, which is a 2D array of 
/// elements of type T and have derived the Eq trait.
/// 
/// Parameters:
/// - `row`: The number of rows in the matrix.
/// - `col`: The number of columns in the matrix.
/// - `data`: The data of the matrix, which is an immutable array of type `IArray[T]`.
/// 
struct Matrix[T] {
  row : Int
  col : Int
  data : IArray[T]
} derive(Eq)

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
/// * `matrix` : The matrix to be converted to string. Elements in the matrix
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
pub impl[T : Show] Show for Matrix[T] with to_string(s) {
  let mut res = ""
  for i in 0..<s.row {
    res = res + "|"
    for j in 0..<s.col {
      res = res + s.data[i * s.col + j].to_string()
      if j < s.col - 1 {
        res = res + ", "
      }
    }
    res = res + "|"
    if i < s.row - 1 {
      res = res + "\n"
    }
  }
  res
}

///|
/// Writes the string representation of a matrix to a buffer.
///
/// Parameters:
///
/// * `matrix` : The matrix to be written to the buffer. The elements in the
/// matrix must implement the `Show` trait.
/// * `buffer` : A buffer to write the string representation to.
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
pub impl[T : Show] Show for Matrix[T] with output(s, l) {
  l.write_string(s.to_string())
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
  {
    row,
    col,
    data: @immut/array.makei(row * col, fn(i) { f(i / col, i % col) }),
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
  Matrix::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
}

///|
/// Creates a new matrix from a one-dimensional immutable array with specified
/// dimensions.
///
/// Parameters:
///
/// * `row` : The number of rows in the resulting matrix.
/// * `col` : The number of columns in the resulting matrix.
/// * `arr` : The immutable array containing the matrix elements in row-major
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
/// let arr = @immut/array.from_array([1, 2, 3, 4, 5, 6])
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
  arr : IArray[T],
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
pub impl[T : Mul + Add] Mul for Matrix[T] with mul(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row
  let data = @immut/array.makei(row * col, fn(i) {
    let r = i / col
    let c = i % col
    let mut sum = self[r][0] * other[0][c]
    for k in 1..<inner {
      sum = sum + self[r][k] * other[k][c]
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
    data: array_zip_with(self.data, other.data, T::add),
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
  not(self.data.iter().any(fn(x) { x != T::zero() }))
}

///|
/// Computes the adjoint of a matrix.
/// 
/// Parameters
/// - `self`: The matrix to compute the adjoint of.
pub fn[T : Conjugate] Matrix::adjoint(self : Matrix[T]) -> Matrix[T] {
  self.map(T::conjugate)
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
pub fn[T : Mul + Add + One + Neg + Zero] Matrix::determinant(
  self : Matrix[T],
) -> T {
  let n = self.row
  guard n == self.col
  letrec view = (f, j) => match j {
    1 => f(0, 0)
    n => {
      let mut det = T::zero()
      for i in 0..<n {
        let sub_view = (j, k) => f(j + 1, if k < i { k } else { k + 1 })
        let sign = if i % 2 == 0 { T::one() } else { -T::one() }
        det += sign * f(0, i) * view(sub_view, n - 1)
      }
      det
    }
  }

  view((i, j) => self[i][j], n)
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
  loop (Matrix::identity(self.col), power, self) {
    (s, 0, _) => s
    (s, 1, m) => s * m
    (s, p, m) => continue (if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m)
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
  self.transpose().swap_rows(c1, c2).transpose()
}
