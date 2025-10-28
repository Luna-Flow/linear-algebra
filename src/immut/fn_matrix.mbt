///|
/// Function-based matrix implementation using lazy evaluation.
///
/// Unlike the standard `Matrix[T]` type which stores elements in an array,
/// `MatrixFn[T]` represents a matrix as a function that computes elements
/// on-demand. This approach is memory-efficient for large sparse matrices or
/// matrices with regular patterns, and supports infinite or very large matrices
/// that would be impractical to store explicitly.
///
/// Fields:
///
/// * `data` : Function that computes the element at position (row, column).
/// * `grid` : Tuple containing the dimensions (number of rows, number of
///   columns).
struct MatrixFn[T] {
  data : (Int, Int) -> T
  grid : (Int, Int)
}

///|
/// Gets a row of the matrix as an indexed accessor.
///
/// Parameters:
///
/// * `self` : The matrix to access.
/// * `i` : The row index to retrieve.
///
/// Returns an `Indexed[T]` object that allows accessing elements in the
/// specified row by column index.
///
/// Example:
///
/// ```moonbit
/// let matrix = @immut.MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row = matrix[0]  // Gets the first row
/// inspect(row[1], content="2")  // Access column 1 of the first row
/// ```
///
pub fn[T] MatrixFn::op_get(self : MatrixFn[T], i : Int) -> Indexed[T] {
  { index: c => (self.data)(i, c) }
}

///|
/// Compares two matrices for structural equality by checking if all
/// corresponding elements are equal.
///
/// Parameters:
///
/// * `self` : The first matrix to compare.
/// * `other` : The second matrix to compare.
///
/// Returns `true` if the matrices have the same dimensions and all
/// corresponding elements are equal, `false` otherwise.
///
/// Panics if the matrices have different dimensions during the `zip_with`
/// operation.
pub impl[T : Eq] Eq for MatrixFn[T] with equal(self, other) {
  self.zip_with(other, T::op_equal).fold(init=true, fn(acc, x) { acc && x })
}

///|
/// Reduces the matrix to a single value by applying a binary function to each
/// element and an accumulator.
///
/// Parameters:
///
/// * `self` : The matrix to fold over.
/// * `init` : The initial value of the accumulator.
/// * `f` : The binary function that takes the current accumulator value and a
///   matrix element, returning the new accumulator value.
///
/// Returns the final accumulator value after processing all matrix elements.
///
/// Example:
///
/// ```moonbit
/// let matrix = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let sum = matrix.fold(init=0, fn(acc, x) { acc + x })
/// inspect(sum, content="10")
/// ```
///
pub fn[T, U] MatrixFn::fold(
  self : MatrixFn[T],
  init~ : U,
  f : (U, T) -> U,
) -> U {
  let (r, c) = self.grid
  let mut acc = init
  for i in 0..<r {
    for j in 0..<c {
      acc = f(acc, (self.data)(i, j))
    }
  }
  acc
}

///|
/// Creates a new matrix with the specified dimensions, where all elements are
/// initialized to the default value of type `T`.
///
/// Parameters:
///
/// * `row` : The number of rows in the matrix.
/// * `col` : The number of columns in the matrix.
///
/// Returns a new `MatrixFn[T]` with all elements set to `T::default()`.
///
/// Panics if an attempt is made to access an element outside the specified
/// dimensions.
///
/// Example:
///
/// ```moonbit
/// let matrix : @immut.MatrixFn[Int] = @immut.MatrixFn::new(2, 3)
/// // Creates a 2x3 matrix with all elements initialized to 0 (default value for Int)
/// ```
///
pub fn[T : Default] MatrixFn::new(row : Int, col : Int) -> MatrixFn[T] {
  {
    data: (i, j) => {
      guard 0 <= i && i < row && 0 <= j && j < col else {
        abort("Index out of bounds")
      }
      T::default()
    },
    grid: (row, col),
  }
}

///|
/// Transforms each element of the matrix using the provided function.
///
/// Parameters:
///
/// * `self` : The matrix to transform.
/// * `f` : The function to apply to each element of the matrix.
///
/// Returns a new matrix with the same dimensions where each element is the
/// result of applying `f` to the corresponding element in the original matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let doubled = m.map(fn(x) { x * 2 })
/// inspect(doubled, content=
///   #||2, 4|
///   #||6, 8|
/// )
/// ```
///
pub fn[T, U] MatrixFn::map(self : MatrixFn[T], f : (T) -> U) -> MatrixFn[U] {
  { data: (i, j) => f((self.data)(i, j)), grid: self.grid }
}

///|
/// Implements the `Show` trait for `MatrixFn[T]` by converting the matrix to a
/// string representation.
///
/// Converts the matrix to a human-readable string format where each row is
/// enclosed in vertical bars (`|`) and elements within rows are separated by
/// commas and spaces. Rows are separated by newlines.
///
/// Parameters:
///
/// * `s` : The `MatrixFn[T]` instance to convert to a string.
///
/// Returns a `String` representation of the matrix in the format `|element1,
/// element2|` for each row, with rows separated by newlines.
pub impl[T : Show] Show for MatrixFn[T] with to_string(s) {
  let mut res = ""
  for i in 0..<s.grid.0 {
    res = res + "|"
    for j in 0..<s.grid.1 {
      res = res + (s.data)(i, j).to_string()
      if j < s.grid.1 - 1 {
        res = res + ", "
      }
    }
    res = res + "|"
    if i < s.grid.0 - 1 {
      res = res + "\n"
    }
  }
  res
}

///|
/// Outputs the matrix to a logger using string representation.
///
/// Parameters:
///
/// * `s` : The matrix to be output.
/// * `l` : The logger to write the string representation to.
///
pub impl[T : Show] Show for MatrixFn[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
/// Applies a function to all elements in a specific row of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to transform.
/// * `row` : The index of the row to apply the function to.
/// * `f` : The function to apply to each element in the specified row.
///
/// Returns a new matrix with the function applied to all elements in the
/// specified row, while keeping all other elements unchanged.
///
/// Example:
///
/// ```moonbit
/// let matrix = @immut.MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let result = matrix.map_row(0, fn(x) { x * 2 })
/// inspect(result, content="|2, 4, 6|\n|4, 5, 6|")
/// ```
///
pub fn[T] MatrixFn::map_row(
  self : MatrixFn[T],
  row : Int,
  f : (T) -> T,
) -> MatrixFn[T] {
  {
    data: (i, j) => if i == row {
      f((self.data)(i, j))
    } else {
      (self.data)(i, j)
    },
    grid: self.grid,
  }
}

///|
/// Applies a function to all elements in a specific column of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to operate on.
/// * `col` : The column index to apply the function to.
/// * `f` : The function to apply to each element in the specified column.
///
/// Returns a new matrix with the function applied to all elements in the
/// specified column, while other elements remain unchanged.
///
/// Example:
///
/// ```moonbit
/// let m = @immut.MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let doubled_col = m.map_col(1, fn(x) { x * 2 })
/// // Column 1 elements (2, 5) become (4, 10)
/// // Result: [[1, 4, 3], [4, 10, 6]]
/// ```
///
pub fn[T] MatrixFn::map_col(
  self : MatrixFn[T],
  col : Int,
  f : (T) -> T,
) -> MatrixFn[T] {
  {
    data: (i, j) => if j == col {
      f((self.data)(i, j))
    } else {
      (self.data)(i, j)
    },
    grid: self.grid,
  }
}

///|
/// Returns a new matrix that is the transpose of the input matrix, where rows
/// and columns are swapped.
///
/// Parameters:
///
/// * `self` : The matrix to transpose.
///
/// Returns a new `MatrixFn[T]` where the element at position (i, j) in the
/// original matrix becomes the element at position (j, i) in the transposed
/// matrix.
///
/// Example:
///
/// ```moonbit
/// let m = MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let transposed = m.transpose()
/// // transposed is now [[1, 4], [2, 5], [3, 6]]
/// inspect(transposed, content="|1, 4|\n|2, 5|\n|3, 6|")
/// ```
///
pub fn[T] MatrixFn::transpose(self : MatrixFn[T]) -> MatrixFn[T] {
  { data: (i, j) => (self.data)(j, i), grid: (self.grid.1, self.grid.0) }
}

///|
/// Creates a functional matrix with specified dimensions using a generator
/// function.
///
/// Parameters:
///
/// * `row` : The number of rows in the matrix.
/// * `col` : The number of columns in the matrix.
/// * `f` : A generator function that takes row and column indices and returns
///   the value at that position.
///
/// Returns a `MatrixFn[T]` where each element at position `(i, j)` is computed
/// by calling `f(i, j)`.
///
/// Example:
///
/// ```moonbit
/// // Create a 3x3 matrix where each element equals i + j
/// let matrix = @immut.MatrixFn::make(3, 3, fn(i, j) { i + j })
/// // matrix[0][0] = 0, matrix[0][1] = 1, matrix[1][0] = 1, etc.
///
/// // Create a 2x2 identity-like matrix
/// let identity = @immut.MatrixFn::make(2, 2, fn(i, j) { if i == j { 1 } else { 0 } })
/// ```
///
pub fn[T] MatrixFn::make(
  row : Int,
  col : Int,
  f : (Int, Int) -> T,
) -> MatrixFn[T] {
  { data: f, grid: (row, col) }
}

///|
/// Converts a 2D array into a functional matrix representation.
///
/// Parameters:
///
/// * `arr` : A 2D array where each inner array represents a row of the matrix.
///
/// Returns a `MatrixFn[T]` that provides functional access to the matrix
/// elements.
///
/// Panics if the input array is empty (when `arr.length()` is 0) or if any row
/// is empty (when `arr[0].length()` is 0), as this would cause an index out of
/// bounds error.
///
/// Example:
///
/// ```moonbit
/// let arr = [[1, 2, 3], [4, 5, 6]]
/// let matrix = MatrixFn::from_2d_array(arr)
/// inspect(matrix, content="|1, 2, 3|\n|4, 5, 6|")
/// ```
///
pub fn[T] MatrixFn::from_2d_array(arr : Array[Array[T]]) -> MatrixFn[T] {
  MatrixFn::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
}

///|
/// Adds two matrices element-wise.
///
/// Parameters:
///
/// * `self` : The first matrix.
/// * `other` : The second matrix to add.
///
/// Returns a new matrix where each element is the sum of the corresponding
/// elements from the input matrices.
///
/// Panics if the dimensions of the two matrices do not match.
pub impl[T : Add] Add for MatrixFn[T] with add(self, other) {
  self.zip_with(other, Add::add)
}

///|
/// Implements element-wise negation for MatrixFn.
///
/// Parameters:
///
/// * `self` : The matrix function to negate.
///
/// Returns a new MatrixFn where each element is the negation of the
/// corresponding element in the input matrix.
pub impl[T : Neg] Neg for MatrixFn[T] with neg(self) {
  self.map(T::op_neg)
}

///|
/// Implements the subtraction operator for functional matrices.
///
/// Performs element-wise subtraction by adding the negation of the second
/// matrix to the first matrix.
///
/// Parameters:
///
/// * `self` : The minuend matrix from which to subtract.
/// * `other` : The subtrahend matrix to be subtracted from the first matrix.
///
/// Returns a new `MatrixFn[T]` containing the element-wise difference of the
/// two matrices.
///
/// Panics if the dimensions of the two matrices do not match.
pub impl[T : Add + Neg] Sub for MatrixFn[T] with sub(self, other) {
  self + -other
}

///|
/// Scales all elements of the matrix by multiplying each element with the given
/// constant.
///
/// Parameters:
///
/// * `self` : The matrix to be scaled.
/// * `cst` : The scalar constant to multiply each matrix element by.
///
/// Returns a new matrix where each element is the product of the corresponding
/// element in the original matrix and the scalar constant.
///
/// Example:
///
/// ```moonbit
/// let m = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let scaled = m.scale(2)
/// // Result: [[2, 4], [6, 8]]
/// ```
///
pub fn[T : Mul] MatrixFn::scale(self : MatrixFn[T], cst : T) -> MatrixFn[T] {
  self.map(fn(x) { x * cst })
}

///|
/// Creates an identity matrix of the specified size.
///
/// Parameters:
///
/// * `size` : The number of rows and columns in the identity matrix.
///
/// Returns a square `MatrixFn[T]` where diagonal elements are `T::one()` and
/// all other elements are `T::zero()`.
///
/// Example:
///
/// ```moonbit
/// let id3 : @immut.MatrixFn[Int] = @immut.MatrixFn::identity(3)
/// inspect(
///   id3,
///   content=(
///     #||1, 0, 0|
///     #||0, 1, 0|
///     #||0, 0, 1|
///   ),
/// )
/// ```
///
pub fn[T : One + Zero] MatrixFn::identity(size : Int) -> MatrixFn[T] {
  MatrixFn::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
/// Computes the matrix power by raising the matrix to the given non-negative
/// integer exponent.
///
/// Parameters:
///
/// * `self` : The square matrix to be raised to a power. Must have equal number
///   of rows and columns.
/// * `power` : The non-negative integer exponent to raise the matrix to.
///
/// Returns the matrix raised to the specified power.
pub fn[T : Semiring] MatrixFn::pow(
  self : MatrixFn[T],
  power : Int,
) -> MatrixFn[T] {
  loop (MatrixFn::identity(self.grid.1), power, self) {
    (s, 0, _) => s
    (s, 1, m) => s * m
    (s, p, m) => continue (if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m)
  }
}

///|
/// Computes the adjoint (conjugate transpose) of a matrix by applying the
/// conjugate operation to each element.
///
/// Parameters:
///
/// * `self` : The matrix to compute the adjoint of.
///
/// Returns a new matrix where each element is the conjugate of the
/// corresponding element in the input matrix.
///
pub fn[T : Conjugate] MatrixFn::adjoint(self : MatrixFn[T]) -> MatrixFn[T] {
  self.map(T::conjugate)
}

///|
/// Swaps two columns in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix in which to swap columns.
/// * `col1` : The index of the first column to swap.
/// * `col2` : The index of the second column to swap.
///
/// Returns a new matrix with the specified columns swapped.
///
/// Panics if either `col1` or `col2` is negative or greater than or equal to
/// the number of rows in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @immut.MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let swapped = m.swap_cols(0, 2)
/// inspect(swapped, content="|3, 2, 1|\n|6, 5, 4|")
/// ```
///
pub fn[T] MatrixFn::swap_cols(
  self : MatrixFn[T],
  r1 : Int,
  r2 : Int,
) -> MatrixFn[T] {
  self.transpose().swap_rows(r1, r2).transpose()
}

///|
/// Swaps two rows in a matrix by their row indices.
///
/// Parameters:
///
/// * `self` : The matrix to perform the row swap on.
/// * `row1` : The index of the first row to swap.
/// * `row2` : The index of the second row to swap.
///
/// Returns a new matrix with the specified rows swapped.
///
/// Panics if either `row1` or `row2` is negative or greater than or equal to
/// the number of rows in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4], [5, 6]])
/// let swapped = m.swap_rows(0, 2)
/// inspect(swapped, content="|5, 6|\n|3, 4|\n|1, 2|")
/// ```
///
pub fn[T] MatrixFn::swap_rows(
  self : MatrixFn[T],
  r1 : Int,
  r2 : Int,
) -> MatrixFn[T] {
  let (r, c) = self.grid
  guard r1 < r && r2 < r && r1 >= 0 && r2 >= 0
  if r1 == r2 {
    self
  } else {
    MatrixFn::make(r, c, (i, j) => match (i, j) {
      (i, j) if i == r1 => (self.data)(r2, j)
      (i, j) if i == r2 => (self.data)(r1, j)
      (i, j) => (self.data)(i, j)
    })
  }
}

///|
/// Implements matrix multiplication for `MatrixFn`.
///
/// Parameters:
///
/// * `self` : The left matrix operand.
/// * `other` : The right matrix operand.
///
/// Returns the product of the two matrices.
///
/// Panics if the number of columns in the left matrix does not equal the number
/// of rows in the right matrix.
impl[T : Mul + Add] Mul for MatrixFn[T] with mul(self, other) {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard c1 == r2
  MatrixFn::make(r1, c2, fn(i, j) {
    let mut sum = (self.data)(i, 0) * (other.data)(0, j)
    for k in 1..<c1 {
      sum += (self.data)(i, k) * (other.data)(k, j)
    }
    sum
  })
}

///|
/// Applies a binary function element-wise to corresponding elements of two
/// matrices, producing a new matrix with the transformed values.
///
/// Parameters:
///
/// * `self` : The first matrix of type `T`.
/// * `other` : The second matrix of type `U`.
/// * `f` : A binary function that takes an element from each matrix and
///   produces a result of type `W`.
///
/// Returns a new matrix of type `W` where each element is the result of
/// applying function `f` to the corresponding elements from the input matrices.
///
/// Panics if the dimensions of the two matrices do not match.
///
/// Example:
///
/// ```moonbit
/// let m1 = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let m2 = @immut.MatrixFn::from_2d_array([[5, 6], [7, 8]])
/// let result = m1.zip_with(m2, fn(a, b) { a + b })
/// // Result: [[6, 8], [10, 12]]
/// ```
///
pub fn[T, U, W] MatrixFn::zip_with(
  self : MatrixFn[T],
  other : MatrixFn[U],
  f : (T, U) -> W,
) -> MatrixFn[W] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard r1 == r2 && c1 == c2 else {
    abort("Matrix dimensions do not match for addition")
  }
  MatrixFn::make(r1, c1, fn(i, j) { f((self.data)(i, j), (other.data)(i, j)) })
}

///|
/// Computes the determinant of a square matrix using cofactor expansion along
/// the first row.
///
/// Parameters:
///
/// * `self` : The square matrix whose determinant is to be calculated.
///
/// Returns the determinant value of the matrix.
///
/// Panics if the matrix is not square (number of rows does not equal number of
/// columns).
pub fn[T : Mul + Add + One + Neg + Zero] MatrixFn::determinant(
  self : MatrixFn[T],
) -> T {
  let (n, m) = self.grid
  guard m == n else { abort("determinant: not a square matrix") }
  letrec view = (f, i) => match i {
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
/// Horizontally concatenates two matrices by placing them side by side.
///
/// Parameters:
///
/// * `self` : The left matrix in the concatenation.
/// * `other` : The right matrix to be concatenated.
///
/// Returns a new matrix with the same number of rows as the input matrices and
/// the combined number of columns.
///
/// Panics if the two matrices have different numbers of rows.
///
/// Example:
///
/// ```moonbit
/// let m1 = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let m2 = @immut.MatrixFn::from_2d_array([[5, 6], [7, 8]])
/// let result = m1.horizontal_combine(m2)
/// // result is [[1, 2, 5, 6], [3, 4, 7, 8]]
/// ```
///
pub fn[T] MatrixFn::horizontal_combine(
  self : MatrixFn[T],
  other : MatrixFn[T],
) -> MatrixFn[T] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard r1 == r2
  MatrixFn::make(r1, c1 + c2, fn(i, j) {
    if j < c1 {
      (self.data)(i, j)
    } else {
      (other.data)(i, j - c1)
    }
  })
}

///|
/// Combines two matrices vertically by stacking the second matrix below the
/// first matrix.
///
/// Parameters:
///
/// * `self` : The matrix to be placed on top.
/// * `other` : The matrix to be placed at the bottom.
///
/// Returns a new matrix with `self` stacked on top of `other`.
///
/// Panics if the two matrices have different numbers of columns.
///
/// Example:
///
/// ```moonbit
/// let m1 = @immut.MatrixFn::from_2d_array([[1, 2], [3, 4]])
/// let m2 = @immut.MatrixFn::from_2d_array([[5, 6], [7, 8]])
/// let result = m1.vertical_combine(m2)
/// // Result is:
/// // |1, 2|
/// // |3, 4|
/// // |5, 6|
/// // |7, 8|
/// ```
///
pub fn[T] MatrixFn::vertical_combine(
  self : MatrixFn[T],
  other : MatrixFn[T],
) -> MatrixFn[T] {
  let (r1, c1) = self.grid
  let (r2, c2) = other.grid
  guard c1 == c2
  MatrixFn::make(r1 + r2, c1, fn(i, j) {
    if i < r1 {
      (self.data)(i, j)
    } else {
      (other.data)(i - r1, j)
    }
  })
}
