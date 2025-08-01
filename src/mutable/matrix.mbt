///|
/// Two-dimensional matrix with mutable elements stored in row-major order.
///
/// Fields:
///
/// Since this struct is not marked with any visibility modifier, it is abstract
/// and users can only pass its value around without direct access to its
/// internal structure.
///
/// Example:
///
/// ```moonbit
/// // Create a 2x3 matrix filled with zeros
/// let m = @mutable.Matrix::new(2, 3, 0)
///
/// // Create from a 2D array
/// let m2 = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
///
/// // Access and modify elements
/// m2[0][1] = 10
/// inspect(m2[0][1], content="10")
///
/// // Get dimensions
/// inspect(m2.row(), content="2")
/// inspect(m2.col(), content="3")
///
/// // Create identity matrix
/// let id : Matrix[Int] = @mutable.identity(3)
/// ```
///
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)

///|
/// Indexing interface that provides mutable access to elements along a matrix
/// row.
///
/// Fields:
///
/// Since this struct is not marked with any visibility modifier, it is abstract
/// and users cannot directly access its fields. The struct can only be used
/// through its associated methods.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_lens = m[0]  // Get lens for first row
/// inspect(row_lens[1], content="2")  // Access element at column 1
/// row_lens[1] = 9     // Modify element at column 1
/// inspect(row_lens[1], content="9")
/// ```
///
struct Lens[T] {
  set : (Int, T) -> Unit
  get : (Int) -> T
}

///|
/// Returns the number of rows in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to query.
///
/// Returns the number of rows as an `Int`.
///
/// Example:
///
/// ```moonbit
/// let matrix =Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(matrix.row(), content="2")
/// ```
///
pub fn[T] row(self : Matrix[T]) -> Int {
  self.row
}

///|
/// Returns the number of columns in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to query.
///
/// Returns:
///
/// `Int` - The number of columns in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(m.col(), content="3")
/// ```
///
pub fn[T] col(self : Matrix[T]) -> Int {
  self.col
}

///|
/// Converts a matrix to its string representation in a readable format.
///
/// Parameters:
///
/// * `s` : The matrix to convert to a string.
///
/// Returns a string representation of the matrix where each row is enclosed in
/// vertical bars (`|`), elements are separated by commas and spaces, and rows
/// are separated by newlines.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(m.to_string(), content="|1, 2, 3|\n|4, 5, 6|")
/// ```
///
pub impl[T : Show] Show for Matrix[T] with to_string(s) {
  let res = StringBuilder::new()
  for i in 0..<s.row {
    res.write_char('|')
    s.eachi_row(i, (c, x) => {
      res.write_string(x.to_string())
      if c < s.col - 1 {
        res.write_string(", ")
      }
    })
    res.write_char('|')
    if i < s.row - 1 {
      res.write_string("\n")
    }
  }
  res.to_string()
}

///|
/// Implements output functionality for `Matrix[T]` by writing its string
/// representation to a logger.
///
/// Parameters:
///
/// * `s` : The matrix to be output.
/// * `l` : The logger to write the matrix representation to.
///
pub impl[T : Show] Show for Matrix[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
/// Applies a function to every element of the matrix, creating a new matrix
/// with the transformed elements.
///
/// Parameters:
///
/// * `self` : The input matrix to transform.
/// * `f` : The function to apply to each element, taking a value of type `T`
///   and returning a value of type `U`.
///
/// Returns a new matrix with the same dimensions as the input matrix, where
/// each element is the result of applying the function `f` to the corresponding
/// element in the input matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let doubled = m.map(fn(x) { x * 2 })
/// inspect(doubled, content="|2, 4|\n|6, 8|")
/// ```
///
pub fn[T, U] Matrix::map(self : Matrix[T], f : (T) -> U) -> Matrix[U] {
  { row: self.row, col: self.col, data: self.data.map(f) }
}

///|
/// Applies a transformation function to all elements in the matrix in-place,
/// modifying the original matrix.
///
/// Parameters:
///
/// * `self` : The matrix whose elements will be transformed.
/// * `f` : The transformation function to apply to each element, taking a value
///   of type `T` and returning a transformed value of the same type.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// m.map_inplace(fn(x) { x * 2 })
/// inspect(m, content="|2, 4|\n|6, 8|")
/// ```
///
pub fn[T] Matrix::map_inplace(self : Matrix[T], f : (T) -> T) -> Unit {
  self.data.map_inplace(f)
}

///|
/// Converts a matrix to its transpose representation without copying the
/// underlying data.
///
/// Parameters:
///
/// * `self` : The matrix to convert to transpose form.
///
/// Returns a `Transpose[T]` that represents the transposed view of the original
/// matrix, where rows and columns are swapped but the underlying data array
/// remains shared.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let t = m.to_transpose()
/// // The transpose has 3 rows and 2 columns (original was 2x3)
/// ```
///
pub fn[T] to_transpose(self : Matrix[T]) -> Transpose[T] {
  self
}

///|
/// Applies a transformation function to all elements in a specific row of the
/// matrix in-place.
///
/// Parameters:
///
/// * `self` : The matrix to modify.
/// * `row` : The zero-based index of the row to transform.
/// * `f` : The transformation function to apply to each element in the row.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// m.map_row_inplace(0, fn(x) { x * 2 })
/// // The first row becomes [2, 4, 6], second row remains [4, 5, 6]
/// ```
///
pub fn[T] Matrix::map_row_inplace(
  self : Matrix[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  for i in 0..<self.col {
    self.data[row * self.col + i] = f(self.data[row * self.col + i])
  }
}

///|
/// Applies a transformation function to all elements in a specific column of
/// the matrix in-place.
///
/// Parameters:
///
/// * `self` : The matrix to modify.
/// * `col` : The index of the column to transform (0-based).
/// * `f` : The transformation function to apply to each element in the column.
///
/// Example:
///
/// ```moonbit
/// let matrix = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// matrix.map_col_inplace(1, fn(x) { x * 2 })
/// // matrix is now [[1, 4, 3], [4, 10, 6]]
/// ```
///
pub fn[T] Matrix::map_col_inplace(
  self : Matrix[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  for i in 0..<self.row {
    self.data[i * self.col + col] = f(self.data[i * self.col + col])
  }
}

///|
/// Applies a function to each element in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix whose elements will be processed.
/// * `f` : The function to apply to each element.
pub fn[T] Matrix::each(self : Matrix[T], f : (T) -> Unit) -> Unit {
  self.data.each(f)
}

///|
/// Iterates over each element of the matrix with its index, calling the
/// provided function for each element.
///
/// Parameters:
///
/// * `self` : The matrix to iterate over.
/// * `f` : A function that takes an index and an element value. The index
///   represents the linear position in the underlying array (calculated as `row
///   * col_count + col`).
pub fn[T] Matrix::eachi(self : Matrix[T], f : (Int, T) -> Unit) -> Unit {
  self.data.eachi(f)
}

///|
/// Iterates through all elements of the matrix, calling the provided function
/// with the row index, column index, and value for each element.
///
/// Parameters:
///
/// * `self` : The matrix to iterate through.
/// * `f` : A function that takes three parameters: the row index (Int), the
///   column index (Int), and the element value (T). This function is called for
///   each element in the matrix.
pub fn[T] Matrix::each_row_col(
  self : Matrix[T],
  f : (Int, Int, T) -> Unit,
) -> Unit {
  self.data.eachi((index, data) => f(index / self.col, index % self.col, data))
}

///|
/// Applies a function to each element in the specified row of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to iterate over.
/// * `row` : The index of the row to iterate through.
/// * `f` : The function to apply to each element in the row.
pub fn[T] Matrix::each_row(
  self : Matrix[T],
  row : Int,
  f : (T) -> Unit,
) -> Unit {
  for i in 0..<self.col {
    f(self.data[row * self.col + i])
  }
}

///|
/// Iterates over all elements in a specific row of the matrix with their column
/// indices, applying a function to each element.
///
/// Parameters:
///
/// * `self` : The matrix to iterate over.
/// * `row` : The zero-based index of the row to iterate through.
/// * `f` : A function that takes two parameters: the column index (Int) and the
///   element value (T). This function is called for each element in the
///   specified row.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// m.eachi_row(1, fn(col_index, value) {
///   println("Row 1, Column \{col_index}: \{value}")
/// })
/// // Prints:
/// // Row 1, Column 0: 4
/// // Row 1, Column 1: 5
/// // Row 1, Column 2: 6
/// ```
///
pub fn[T] Matrix::eachi_row(
  self : Matrix[T],
  row : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  for i in 0..<self.col {
    f(i, self.data[row * self.col + i])
  }
}

///|
/// Iterates over all elements in a specific column of the matrix, applying a
/// function to each element.
///
/// Parameters:
///
/// * `self` : The matrix to iterate over.
/// * `col` : The column index to iterate over.
/// * `f` : The function to apply to each element in the column.
pub fn[T] Matrix::each_col(
  self : Matrix[T],
  col : Int,
  f : (T) -> Unit,
) -> Unit {
  for i in 0..<self.row {
    f(self.data[i * self.col + col])
  }
}

///|
/// Iterates over all elements in a specific column of the matrix with their row
/// indices, applying a function to each element and its corresponding row
/// index.
///
/// Parameters:
///
/// * `self` : The matrix to iterate over.
/// * `col` : The zero-based index of the column to iterate through.
/// * `f` : The function to apply to each element in the column, which takes the
///   row index and the element value as parameters.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// m.eachi_col(1, fn(row_idx, value) {
///   println("Row \{row_idx}: \{value}")
/// })
/// // Output:
/// // Row 0: 2
/// // Row 1: 5
/// ```
///
pub fn[T] Matrix::eachi_col(
  self : Matrix[T],
  col : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  for i in 0..<self.row {
    f(i, self.data[i * self.col + col])
  }
}

///|
/// Creates a deep copy of the matrix with the same dimensions and element
/// values.
///
/// Parameters:
///
/// * `self` : The matrix to be copied.
///
/// Returns a new matrix that is an independent copy of the original matrix.
///
/// Example:
///
/// ```moonbit
/// let original = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let copy = original.copy()
/// copy[0][0] = 99
/// inspect(original[0][0], content="1") // Original remains unchanged
/// inspect(copy[0][0], content="99")    // Copy is modified
/// ```
///
pub fn[T] Matrix::copy(self : Matrix[T]) -> Matrix[T] {
  { row: self.row, col: self.col, data: self.data.copy() }
}

///|
/// Creates a new matrix with specified dimensions using a generator function.
///
/// Parameters:
///
/// * `row` : The number of rows in the matrix.
/// * `col` : The number of columns in the matrix.
/// * `f` : A function that takes row and column indices and returns the element
///   at that position.
///
/// Returns a new `Matrix[A]` with the specified dimensions where each element
/// is generated by calling the function with its row and column indices.
///
/// Example:
///
/// ```moonbit
/// // Create a 3x3 identity matrix
/// let identity = Matrix::make(3, 3, fn(i, j) { if i == j { 1 } else { 0 } })
///
/// // Create a matrix where each element equals its row index plus column index
/// let sum_matrix = Matrix::make(2, 3, fn(i, j) { i + j })
/// ```
///
pub fn[A] Matrix::make(row : Int, col : Int, f : (Int, Int) -> A) -> Matrix[A] {
  { row, col, data: Array::makei(row * col, fn(i) { f(i / col, i % col) }) }
}

///|
/// Creates a new matrix with the specified dimensions where all elements are
/// initialized to the same value.
///
/// Parameters:
///
/// * `row` : The number of rows in the matrix.
/// * `col` : The number of columns in the matrix.
/// * `elem` : The value to initialize all elements in the matrix.
///
/// Returns a new `Matrix[T]` with all elements set to `elem`.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::new(2, 3, 42)
/// inspect(m.to_string(), content="|42, 42, 42|\n|42, 42, 42|")
/// ```
///
pub fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T] {
  Matrix::make(row, col, (_, _) => elem)
}

///|
/// Creates a matrix from a 2D array.
///
/// Parameters:
///
/// * `arr` : A 2D array where each sub-array represents a row of the matrix.
///
/// Returns a new `Matrix[T]` with the same dimensions and elements as the input
/// 2D array.
///
/// Panics if the input array is empty or if any sub-array is empty.
///
/// Example:
///
/// ```moonbit
/// let data = [[1, 2, 3], [4, 5, 6]]
/// let matrix = Matrix::from_2d_array(data)
/// inspect(matrix.to_string(), content="|1, 2, 3|\n|4, 5, 6|")
/// ```
///
pub fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T] {
  Matrix::make(arr.length(), arr[0].length(), fn(i, j) { arr[i][j] })
}

///|
/// Creates a matrix from a flat array with specified dimensions.
///
/// Parameters:
///
/// * `row` : The number of rows in the matrix.
/// * `col` : The number of columns in the matrix.
/// * `data` : A flat array containing the matrix elements in row-major order.
///
/// Returns a new matrix with the specified dimensions.
///
/// Panics if the product of `row` and `col` does not equal the length of
/// `data`.
///
/// Example:
///
/// ```moonbit
/// let data = [1, 2, 3, 4, 5, 6]
/// let matrix = @mutable.Matrix::from_array(2, 3, data)
/// inspect(matrix, content="|1, 2, 3|\n|4, 5, 6|")
/// ```
///
pub fn[T] Matrix::from_array(
  row : Int,
  col : Int,
  data : Array[T],
) -> Matrix[T] {
  guard row * col == data.length()
  { row, col, data }
}

///|
/// Returns a lens that provides indexed access to a specific row of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to access.
/// * `row` : The zero-based index of the row to access.
///
/// Returns a `Lens[T]` object that allows getting and setting elements in the
/// specified row by column index.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_lens = m[1]  // Get lens for row 1
/// inspect(row_lens[0], content="4")  // Access element at column 0
/// row_lens[2] = 10  // Set element at column 2
/// inspect(m[1][2], content="10")
/// ```
///
pub fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Lens[T] {
  {
    set: (c, v) => self.data[c + self.col * row] = v,
    get: c => self.data[c + self.col * row],
  }
}

///|
/// Retrieves the value at the specified column index from the lens.
///
/// Parameters:
///
/// * `self` : The lens to access.
/// * `col` : The column index to retrieve the value from.
///
/// Returns the value at the specified column index.
///
pub fn[T] op_get(self : Lens[T], col : Int) -> T {
  (self.get)(col)
}

///|
/// Sets the value at the specified column index in the lens.
///
/// Parameters:
///
/// * `self` : The lens object to modify.
/// * `col` : The column index where the value should be set.
/// * `elem` : The value to set at the specified column index.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let lens = m[0]  // Get lens for first row
/// lens[1] = 10     // Set column 1 to value 10
/// inspect(m[0][1], content="10")
/// ```
///
pub fn[T] Lens::op_set(self : Lens[T], col : Int, elem : T) -> Unit {
  (self.set)(col, elem)
}

///|
/// Multiplies two matrices using standard matrix multiplication.
///
/// Parameters:
///
/// * `self` : The left matrix operand.
/// * `other` : The right matrix operand.
///
/// Returns a new matrix that is the product of `self` and `other`.
///
/// Panics if the number of columns in `self` does not equal the number of rows
/// in `other`.
///
/// Example:
///
/// ```moonbit
/// let a = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let b = @mutable.Matrix::from_2d_array([[5, 6], [7, 8]])
/// let result = a * b
/// inspect(result, content="|19, 22|\n|43, 50|")
/// ```
///
pub impl[T : Mul + Add] Mul for Matrix[T] with op_mul(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row
  let data = Array::makei(row * col, fn(i) {
    let r = i / col
    let c = i % col
    let mut sum = self[r][0] * other[0][c]
    for k in 1..<inner {
      sum += self[r][k] * other[k][c]
    }
    sum
  })
  { row, col, data }
}

///|
/// Adds two matrices element-wise.
///
/// Parameters:
///
/// * `self` : The first matrix.
/// * `other` : The second matrix to add to the first matrix.
///
/// Returns a new matrix where each element is the sum of the corresponding
/// elements from the input matrices.
///
/// Panics if the matrices have different dimensions (different number of rows
/// or columns).
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[5, 6], [7, 8]])
/// let result = m1 + m2
/// inspect(result, content="|6, 8|\n|10, 12|")
/// ```
///
pub impl[T : Add] Add for Matrix[T] with op_add(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.col == other.col
  guard self.row == other.row
  {
    data: array_zip_with(self.data, other.data, T::op_add),
    row: self.row,
    col: self.col,
  }
}

///|
/// Negates all elements in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to negate.
///
/// Returns a new matrix with all elements negated.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, -2], [3, -4]])
/// let negated = -m
/// inspect(negated.to_string(), content="|-1, 2|\n|-3, 4|")
/// ```
///
pub impl[T : Neg] Neg for Matrix[T] with op_neg(self : Matrix[T]) -> Matrix[T] {
  self.map(T::op_neg)
}

///|
/// Subtracts the second matrix from the first matrix element-wise.
///
/// Parameters:
///
/// * `self` : The matrix from which to subtract (minuend).
/// * `other` : The matrix to subtract (subtrahend).
///
/// Returns a new matrix containing the element-wise difference of the two
/// matrices.
///
/// Example:
///
/// ```moonbit
/// let m1 =Matrix::from_2d_array([[5, 7], [9, 11]])
/// let m2 =Matrix::from_2d_array([[1, 2], [3, 4]])
/// let result = m1 - m2
/// // result is |4, 5|
/// //           |6, 7|
/// ```
///
pub impl[T : Add + Neg] Sub for Matrix[T] with op_sub(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  self + -other
}

///|
/// Multiplies each element of the matrix by a scalar value.
///
/// Parameters:
///
/// * `self` : The matrix to be scaled.
/// * `cst` : The scalar value to multiply each element by.
///
/// Returns a new matrix where each element is the product of the corresponding
/// element in the original matrix and the scalar.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let scaled = m.scale(2)
/// inspect(scaled, content="|2, 4|\n|6, 8|")
/// ```
///
pub fn[T : Mul] scale(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(x => x * cst)
}

///|
/// Adds a constant value to each element of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to which the constant will be added.
/// * `cst` : The constant value to add to each element.
///
/// Returns a new matrix with the constant added to each element of the original
/// matrix.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let result = m.add_constant(5)
/// inspect(result, content="|6, 7|\n|8, 9|")
/// ```
///
pub fn[T : Add] add_constant(self : Matrix[T], cst : T) -> Matrix[T] {
  self.map(x => x + cst)
}

///|
/// Creates an identity matrix of the specified size.
///
/// Parameters:
///
/// * `size` : The number of rows and columns of the identity matrix.
///
/// Returns a square matrix where diagonal elements are one and all other
/// elements are zero.
///
/// Panics if `size` is negative.
///
/// Example:
///
/// ```moonbit
/// let id : Matrix[Int] = @mutable.identity(3)
/// inspect(id, content="|1, 0, 0|\n|0, 1, 0|\n|0, 0, 1|")
/// ```
///
pub fn[T : One + Zero] identity(size : Int) -> Matrix[T] {
  Matrix::make(size, size, fn(i, j) {
    guard i == j else { T::zero() }
    T::one()
  })
}

///|
/// Checks whether the matrix is a null (zero) matrix by testing if all elements
/// are equal to zero.
///
/// Parameters:
///
/// * `self` : The matrix to check for nullity.
///
/// Returns `true` if all elements in the matrix are zero, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let zero_matrix = @mutable.Matrix::new(2, 2, 0)
/// let non_zero_matrix = @mutable.Matrix::from_2d_array([[1, 0], [0, 1]])
/// inspect(zero_matrix.null(), content="true")
/// inspect(non_zero_matrix.null(), content="false")
/// ```
///
pub fn[T : Compare + Zero] null(self : Matrix[T]) -> Bool {
  not(self.data.iter().any(fn(x) { x != T::zero() }))
}

///|
/// Computes the adjoint (conjugate transpose) of the matrix by applying the
/// conjugate operation to each element.
///
/// Parameters:
///
/// * `self` : The matrix to compute the adjoint of.
///
/// Returns a new matrix where each element is the conjugate of the
/// corresponding element in the original matrix.
pub fn[T : Conjugate] adjoint(self : Matrix[T]) -> Matrix[T] {
  self.map(T::conjugate)
}

///|
/// Transposes the matrix by swapping rows and columns.
///
/// Parameters:
///
/// * `self` : The matrix to transpose.
///
/// Returns a new matrix that is the transpose of the input matrix, where the
/// element at position (i, j) in the original matrix becomes the element at
/// position (j, i) in the transposed matrix.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let transposed = m.transpose()
/// inspect(transposed, content="|1, 4|\n|2, 5|\n|3, 6|")
/// ```
///
pub fn[T] transpose(self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) { self[j][i] })
}

///|
/// Swaps the positions of two rows in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to perform the row swap operation on.
/// * `r1` : The index of the first row to swap.
/// * `r2` : The index of the second row to swap.
///
/// Panics if either `r1` or `r2` is out of bounds (negative or greater than or
/// equal to the number of rows in the matrix).
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// m.swap_rows(0, 1)
/// inspect(m.to_string(), content="|4, 5, 6|\n|1, 2, 3|")
/// ```
///
pub fn[T] swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Unit {
  let r = self.row
  let c = self.col
  guard r1 < r && r2 < r && r1 >= 0 && r2 >= 0
  if r1 == r2 {
    return
  }
  let temp = Array::makei(c, fn(i) { self.data[r1 * self.col + i] })
  for i in 0..<c {
    self.data[r1 * self.col + i] = self.data[r2 * self.col + i]
  }
  for i in 0..<c {
    self.data[r2 * self.col + i] = temp[i]
  }
}

///|
/// Swaps two columns in the matrix in-place.
///
/// Parameters:
///
/// * `self` : The matrix whose columns will be swapped.
/// * `c1` : The index of the first column to swap.
/// * `c2` : The index of the second column to swap.
///
/// Panics if either `c1` or `c2` is negative or greater than or equal to the
/// number of columns in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// m.swap_cols(0, 2)
/// inspect(m, content="|3, 2, 1|\n|6, 5, 4|")
/// ```
///
pub fn[T] swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Unit {
  let r = self.row
  let c = self.col
  guard c1 < c && c2 < c && c1 >= 0 && c2 >= 0
  if c1 == c2 {
    return
  }
  let temp = Array::makei(r, fn(i) { self.data[i * self.col + c1] })
  for i in 0..<r {
    self.data[i * self.col + c1] = self.data[i * self.col + c2]
  }
  for i in 0..<r {
    self.data[i * self.col + c2] = temp[i]
  }
}

///|
/// Computes the power of a square matrix using fast exponentiation.
///
/// Parameters:
///
/// * `self` : The square matrix to be raised to a power.
/// * `power` : The non-negative integer exponent.
///
/// Returns the matrix raised to the specified power.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m_squared = m.pow(2)
/// // Equivalent to m * m
/// ```
///
pub fn[T : Semiring] pow(self : Matrix[T], power : Int) -> Matrix[T] {
  loop (identity(self.col), power, self) {
    (s, 0, _) => s
    (s, 1, m) => s * m
    (s, p, m) => continue (if (p & 1) == 1 { s * m } else { s }, p >> 1, m * m)
  }
}

///|
/// Performs Gaussian elimination with partial pivoting to reduce the matrix to
/// reduced row echelon form (RREF).
///
/// This method applies the Gauss-Jordan elimination algorithm, which includes:
///
/// 1. Partial pivoting: selecting the row with the largest absolute value in
/// the current column as the pivot
/// 2. Row swapping to move the pivot to the diagonal position
/// 3. Scaling the pivot row to make the pivot element equal to 1
/// 4. Eliminating all other elements in the current column to make them zero
///
/// The matrix is modified in-place during the elimination process.
///
/// Parameters:
///
/// * `self` : The matrix to be reduced to row echelon form.
///
/// Returns the same matrix instance after performing the row elimination
/// operations.
///
/// Panics if any pivot element cannot be inverted (i.e., when `val.inv()` is
/// called on a zero element that wasn't properly handled).
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([
///   [1.0, 2.0, 3.0, 7.0],
///   [1.0, 1.0, 1.0, 2.0], 
///   [2.0, 3.0, 3.0, 5.0]
/// ])
/// let result = m.reduce_row_elimination()
/// // Result will be in reduced row echelon form:
/// // |1, 0, 0, 1|
/// // |0, 1, 0, -3|
/// // |0, 0, 1, 4|
/// ```
///
pub fn[T : Compare + Num + Sub + Inverse] reduce_row_elimination(
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
      if self[j][col].abs() > self[max_row][col].abs() {
        max_row = j
      }
    }
    ignore(self.swap_rows(i, max_row))
    if self[i][col] == T::zero() {
      col = col + 1
      continue
    }
    let val = self[i][col]
    ignore(self.map_row_inplace(i, fn(x) { x * val.inv() }))
    for j in 0..<r {
      if j == i {
        continue
      }
      let factor = self[j][col]
      for k in 0..<c {
        self[j][k] = self[j][k] - self[i][k] * factor
      }
    }
    col = col + 1
  }
  self
}

///|
/// Combines two matrices horizontally by placing them side by side.
///
/// Parameters:
///
/// * `self` : The left matrix to be combined.
/// * `other` : The right matrix to be combined.
///
/// Returns a new matrix with the same number of rows as the input matrices and
/// columns equal to the sum of both matrices' column counts.
///
/// Panics if the two matrices have different numbers of rows.
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[5, 6], [7, 8]])
/// let result = m1.horizontal_combine(m2)
/// inspect(result, content="|1, 2, 5, 6|\n|3, 4, 7, 8|")
/// ```
///
pub fn[T] horizontal_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  guard self.row == other.row
  Matrix::make(self.row, self.col + other.col, fn(i, j) {
    if j < self.col {
      self[i][j]
    } else {
      other[i][j - self.col]
    }
  })
}

///|
/// Combines two matrices vertically by stacking the second matrix below the
/// first matrix.
///
/// Parameters:
///
/// * `self` : The first matrix to be placed on top.
/// * `other` : The second matrix to be placed below the first matrix.
///
/// Returns a new matrix with the rows of `self` followed by the rows of
/// `other`.
///
/// Panics if the two matrices have different numbers of columns.
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = Matrix::from_2d_array([[5, 6], [7, 8]])
/// let result = m1.vertical_combine(m2)
/// // Result is a 4x2 matrix: [[1, 2], [3, 4], [5, 6], [7, 8]]
/// ```
///
pub fn[T] vertical_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T] {
  guard self.col == other.col
  let array = self.data
  array.push_iter(other.data.iter())
  return { row: self.row + other.row, col: self.col, data: array }
}

///|
/// Extracts a specific row from the matrix and returns it as an array.
///
/// Parameters:
///
/// * `self` : The matrix from which to extract the row.
/// * `row` : The zero-based index of the row to extract.
///
/// Returns an array containing all elements from the specified row in column
/// order.
///
/// Panics if `row` is negative or greater than or equal to the number of rows
/// in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_array = m.row_to_array(1)
/// inspect(row_array, content="[4, 5, 6]")
/// ```
///
pub fn[T] row_to_array(self : Matrix[T], row : Int) -> Array[T] {
  guard row >= 0 && row < self.row
  let start = row * self.col
  let end = start + self.col
  self.data[start:end].to_array()
}

///|
/// Extracts a specific column from the matrix and returns it as an array.
///
/// Parameters:
///
/// * `self` : The matrix from which to extract the column.
/// * `col` : The zero-based index of the column to extract.
///
/// Returns an array containing all elements from the specified column, ordered
/// from top to bottom.
///
/// Panics if `col` is negative or greater than or equal to the number of
/// columns in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let col1 = m.col_to_array(1)
/// inspect(col1, content="[2, 5]")
/// ```
///
pub fn[T] col_to_array(self : Matrix[T], col : Int) -> Array[T] {
  guard col >= 0 && col < self.col
  let arr = []
  for i in 0..<self.row {
    arr.push(self.data[i * self.col + col])
  }
  arr
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
pub fn[T] to_array(self : Matrix[T]) -> Array[T] {
  self.data.copy()
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
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let array_2d = m.to_2d_array()
/// inspect(array_2d, content="[[1, 2, 3], [4, 5, 6]]")
/// ```
///
pub fn[T] to_2d_array(self : Matrix[T]) -> Array[Array[T]] {
  let row = self.row
  let arr_2d = []
  for i in 0..<row {
    arr_2d.push(self.row_to_array(i))
  }
  arr_2d
}

///|
/// Extracts a specific row from the matrix and returns it as a vector.
///
/// Parameters:
///
/// * `self` : The matrix from which to extract the row.
/// * `row` : The zero-based index of the row to extract.
///
/// Returns a new vector containing all elements from the specified row in
/// column order.
///
/// Panics if `row` is negative or greater than or equal to the number of rows
/// in the matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_vector = m.row_to_vector(1)
/// // row_vector contains [4, 5, 6]
/// ```
///
pub fn[T] row_to_vector(self : Matrix[T], row : Int) -> Vector[T] {
  self.row_to_array(row)
}

///|
/// Extracts a specific column from the matrix and returns it as a Vector.
///
/// Parameters:
///
/// * `self` : The matrix from which to extract the column.
/// * `col` : The zero-based index of the column to extract.
///
/// Returns a Vector containing all elements from the specified column, ordered
/// from top to bottom.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let col1 = m.col_to_vector(1)
/// // col1 is a Vector containing [2, 5]
/// ```
///
pub fn[T] col_to_vector(self : Matrix[T], col : Int) -> Vector[T] {
  self.col_to_array(col)
}

///|
/// Converts the matrix to a vector by copying its internal array
/// representation.
///
/// Parameters:
///
/// * `self` : The matrix to be converted to a vector.
///
/// Returns a new vector containing all elements of the matrix in row-major
/// order (elements are stored row by row from left to right, top to bottom).
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let vector = m.to_vector()
/// inspect(vector, content="|1, 2, 3, 4, 5, 6|")
/// ```
///
pub fn[T] to_vector(self : Matrix[T]) -> Vector[T] {
  self.data.copy()
}

///|
/// Calculates the rank of the matrix using row reduction.
/// 
/// Parameters:
/// 
/// * `self` : The matrix to get the rank of.
///
/// Returns the rank of the matrix, which is the dimension of the vector space
/// spanned by its rows or columns.
/// 
/// Example:
/// 
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [7.0, 8.0, 9.0]])
/// let rank = m.rank()
/// inspect(rank, content="2")  // The rank of the matrix is 2
/// ```
pub fn[T : Compare + Num + Inverse + Sub] Matrix::rank(self : Matrix[T]) -> Int {
  let m = self.copy()
  let _ = m.reduce_row_elimination()
  let mut rank = 0
  for i in 0..<m.row {
    for j in 0..<m.col {
      if m[i][j] != T::zero() {
        rank += 1
        break
      }
    }
  }
  rank
}

///|
pub fn[T : @internal.HomomorphismNat] Matrix::from_nat_matrix(
  self : Matrix[Int],
) -> Matrix[T] {
  self.map(@internal.HomomorphismNat::from_nat)
}

///|
/// Calculates the trace of a square matrix.
/// 
/// The trace is the sum of all diagonal elements of the matrix.
/// This function only works on square matrices (where row count equals column count).
/// 
/// Parameters:
/// 
/// * `self` : The square matrix to calculate the trace of.
///
/// Returns the sum of all diagonal elements.
/// 
/// Panics if the matrix is not square (row count != column count).
/// 
/// Example:
/// 
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
/// let trace = m.trace()
/// inspect(trace, content="15")  // 1 + 5 + 9 = 15
/// ```
pub fn[T : Add + Zero] trace(self : Matrix[T]) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate trace")
  }
  let mut sum = T::zero()
  for i in 0..<self.row {
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
/// let m1 = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
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
/// let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let iter = m.iter()
/// inspect(iter.collect(), content="[1, 2, 3, 4]") // Collects all elements in row-major order
/// ```
pub fn[T] iter(self : Matrix[T]) -> Iter[T] {
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
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_iter = m.iter_row(1)
/// for elem in row_iter {
///   println(elem) // prints: 4, 5, 6
/// }
/// ```
pub fn[T] iter_row(self : Matrix[T], row : Int) -> Iter[T] {
  guard row >= 0 && row < self.row else { abort("Row index out of bounds") }
  let start = row * self.col
  let end = start + self.col
  self.data[start:end].iter()
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
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let col_iter = m.iter_col(1)
/// for elem in col_iter {
///   println(elem) // prints: 2, 5
/// }
/// ```
pub fn[T] iter_col(self : Matrix[T], col : Int) -> Iter[T] {
  guard col >= 0 && col < self.col else { abort("Column index out of bounds") }
  self.transpose().iter_row(col)
}

///|
/// Computes the eigenvalues and eigenvectors of a square matrix using the QR algorithm.
/// 
/// This function implements the QR algorithm with shifts to compute eigenvalues,
/// and then uses inverse iteration to find the corresponding eigenvectors.
/// 
/// **Note**: This is a complex numerical algorithm. For non-symmetric matrices, eigenvalues can be complex,
/// which are not fully supported by this implementation (it would require a Complex number type).
/// This implementation works best for symmetric matrices with real eigenvalues.
/// 
/// Parameters:
/// 
/// * `self` : The square matrix to compute eigenvalues and eigenvectors for.
///
/// Returns a tuple containing:
/// * A vector of eigenvalues.
/// * A matrix where each column is an eigenvector corresponding to an eigenvalue.
/// 
/// Panics if the matrix is not square.
/// 
/// Example:
/// 
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
/// let (eigenvals, eigenvecs) = m.eigen()
/// // eigenvals should be close to [3.0, 2.0]
/// // eigenvecs contains the corresponding eigenvectors as columns
/// ```
pub fn[T : Compare + Add + Mul + Sub + Neg + Num + Div + Sqrt + Tolerance] eigen(
  self : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  guard self.is_square() else {
    abort("Matrix must be square for eigenvalue computation")
  }
  qr_algorithm(self)
}

///|
/// Implements the QR algorithm for computing eigenvalues and eigenvectors.
/// 
/// This is the core algorithm that iteratively applies QR decomposition
/// to converge to a matrix with eigenvalues on the diagonal.
fn[T : Compare + Add + Mul + Sub + Neg + Num + Div + Sqrt + Tolerance] qr_algorithm(
  matrix : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  let n = matrix.row
  let mut a = matrix.copy()
  let mut q_total = identity(n)
  let max_iterations = 100
  for _ in 0..<max_iterations {
    // Apply QR decomposition
    let (q, r) = qr_decomposition(a)

    // Update A = RQ
    a = r * q

    // Accumulate Q matrices for eigenvectors
    q_total = q_total * q

    // Check for convergence (off-diagonal elements should be small)
    if is_upper_triangular(a) {
      break
    }
  }

  // Extract eigenvalues from diagonal
  let eigenvalues = Vector::makei(n, i => a[i][i])
  (eigenvalues, q_total)
}

///|
/// Performs QR decomposition of a matrix using the Gram-Schmidt process.
/// 
/// Parameters:
/// * `matrix` : The matrix to decompose.
/// 
/// Returns a tuple (Q, R) where Q is orthogonal and R is upper triangular.
fn[T : Compare + Add + Mul + Sub + Num + Div + Tolerance + Sqrt] qr_decomposition(
  matrix : Matrix[T],
) -> (Matrix[T], Matrix[T]) {
  let m = matrix.row
  let n = matrix.col
  let q = Matrix::new(m, n, T::zero())
  let r = Matrix::new(n, n, T::zero())

  // Modified Gram-Schmidt process
  for j in 0..<n {
    // Copy column j from A to Q
    for i in 0..<m {
      q[i][j] = matrix[i][j]
    }

    // Orthogonalize against previous columns
    for k in 0..<j {
      // Compute r[k][j] = q_k^T * q_j
      let mut dot_product = T::zero()
      for i in 0..<m {
        dot_product += q[i][k] * q[i][j]
      }
      r[k][j] = dot_product

      // q_j = q_j - r[k][j] * q_k
      for i in 0..<m {
        q[i][j] -= r[k][j] * q[i][k]
      }
    }

    // Normalize q_j
    let mut norm = T::zero()
    for i in 0..<m {
      norm += q[i][j] * q[i][j]
    }
    norm = norm.sqrt()
    r[j][j] = norm
    if norm > T::tolerance() {
      for i in 0..<m {
        q[i][j] /= norm
      }
    }
  }
  (q, r)
}

///|
/// Checks if a matrix is approximately upper triangular within a given tolerance.
fn[T : Compare + Num + Tolerance] is_upper_triangular(
  matrix : Matrix[T],
) -> Bool {
  let n = matrix.row
  for i in 0..<n {
    for j in 0..<i {
      if matrix[i][j].abs() > T::tolerance() {
        return false
      }
    }
  }
  true
}

///|
/// Computes the dominant eigenvalue and eigenvector using the power method.
/// This is an alternative method for finding the largest eigenvalue.
/// 
/// Parameters:
/// * `self` : The square matrix to compute the dominant eigenvalue and eigenvector for.
/// * `max_iterations` : The maximum number of iterations to perform.
/// 
/// Returns a tuple containing:
/// * The dominant eigenvalue.
/// * The corresponding eigenvector as a normalized vector.
/// 
/// Panics if the matrix is not square.
pub fn[T : Compare + Add + Mul + Sub + Div + Num + Tolerance] power_method(
  self : Matrix[T],
  max_iterations : Int,
) -> (T, Vector[T]) {
  guard self.is_square() else {
    abort("Matrix must be square for power method")
  }
  let n = self.row
  let mut x = Vector::makei(n, _ => T::one())
  let mut lambda = T::zero()
  for _ in 0..<max_iterations {
    let y = matrix_vector_multiply(self, x)
    let mut max_val = T::zero()
    for i in 0..<n {
      if y[i].abs() > max_val.abs() {
        max_val = y[i]
      }
    }
    let new_lambda = max_val
    x = y.map(v => v / new_lambda)
    if (new_lambda - lambda).abs() < Tolerance::tolerance() {
      return (new_lambda, x)
    }
    lambda = new_lambda
  }
  (lambda, x)
}

///|
/// Helper function to multiply a matrix by a vector.
fn[T : Add + Mul + Zero] matrix_vector_multiply(
  matrix : Matrix[T],
  vector : Vector[T],
) -> Vector[T] {
  let m = matrix.row
  let n = matrix.col
  guard n == vector.length() else {
    abort("Matrix and vector dimensions are not compatible for multiplication")
  }
  Vector::makei(m, i => {
    let mut sum = T::zero()
    for j in 0..<n {
      sum += matrix[i][j] * vector[j]
    }
    sum
  })
}

///|
/// Computes eigenvalues for 2x2 matrices analytically.
/// 
/// This function uses the characteristic polynomial to find the eigenvalues
/// of a 2x2 matrix.
///
///  Parameters:
/// * `self` : The 2x2 matrix to compute eigenvalues for.
///
/// Returns a vector containing the two eigenvalues.
/// 
/// Panics if the matrix is not 2x2.
pub fn[T : Compare + Add + Mul + Sub + Num + Div + Sqrt + SMul] eigen_2x2(
  self : Matrix[T],
) -> Vector[T] {
  guard self.row == 2 && self.col == 2 else {
    abort("This function is only for 2x2 matrices")
  }
  let a = self[0][0]
  let b = self[0][1]
  let c = self[1][0]
  let d = self[1][1]
  let trace = a + d
  let det = a * d - b * c
  let discriminant = trace * trace - T::one().scalar(4.0) * det
  if discriminant >= T::zero() {
    let sqrt_disc = discriminant.sqrt()
    let lambda1 = (trace + sqrt_disc) / T::one().scalar(2.0)
    let lambda2 = (trace - sqrt_disc) / T::one().scalar(2.0)
    Vector::from_array([lambda1, lambda2])
  } else {
    // This case results in complex eigenvalues.
    // This implementation returns only the real part.
    let real_part = trace / T::one().scalar(2.0)
    Vector::from_array([real_part, real_part])
  }
}

///|
pub trait SMul {
  scalar(Self, Double) -> Self
}

///|
pub impl SMul for Double with scalar(self, rhs : Double) -> Double {
  self * rhs
}

///|
pub impl SMul for Float with scalar(self, rhs : Double) -> Float {
  self * rhs.to_float()
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

///|
/// Calculates the determinant of a square matrix.
///
/// This method uses an efficient algorithm based on self decomposition with partial
/// pivoting. It transforms the matrix into an upper triangular form while tracking
/// row swaps. The determinant is then the product of the diagonal elements of
/// the resulting matrix, adjusted by the sign determined by the number of swaps.
/// This approach is numerically stable and has a time complexity of O(n³).
///
/// Parameters:
/// * `self`: The square matrix.
///
/// Returns the determinant of the matrix.
///
/// Panics if the matrix is not square.
///
/// Example:
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[4.0, 3.0], [6.0, 3.0]])
/// inspect(m.determinant(), content="-6")
/// ```
pub fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] determinant(
  self : Matrix[T],
) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate determinant")
  }

  let m = self.copy()
  let n = m.row
  if n == 0 {
    return T::one() // By definition, determinant of a 0x0 matrix is 1.
  }
  let mut det_sign = T::one()
  for j in 0..<n {
    // Find pivot using partial pivoting for numerical stability.
    let mut max_row = j
    for i in (j + 1)..<n {
      if m[i][j].abs() > m[max_row][j].abs() {
        max_row = i
      }
    }
    if max_row != j {
      m.swap_rows(j, max_row)
      det_sign = -det_sign
    }
    let pivot = m[j][j]
    if pivot.abs() < T::tolerance() {
      // If a pivot is zero (or very close to it), the matrix is singular.
      return T::zero()
    }

    // Perform elimination for rows below the pivot.
    for i in (j + 1)..<n {
      let factor = m[i][j] / pivot
      for k in (j + 1)..<n {
        m[i][k] -= factor * m[j][k]
      }
    }
  }

  // The determinant is the product of the diagonal elements of the
  // resulting upper triangular matrix, adjusted by the sign.
  let mut det = det_sign
  for i in 0..<n {
    det *= m[i][i]
  }
  det
}

///|
/// Computes the inverse of a square matrix using the Gauss-Jordan elimination method.
///
/// This method constructs an augmented matrix by horizontally combining the original
/// matrix with an identity matrix of the same size, then applies row elimination to
/// reduce it to reduced row echelon form (RREF). If successful, the right half of
/// the resulting matrix contains the inverse.
///
/// Parameters:
///
/// * `self` : The square matrix to compute the inverse of.
///
/// Returns an `Option[Matrix[T]]` where:
/// * `Some(inverse_matrix)` if the matrix is invertible
/// * `None` if the matrix is singular (non-invertible)
///
/// Panics if the matrix is not square.
/// 
///
pub fn[T : Compare + Num + Sub + Inverse + Zero + One + Tolerance + Div] inverse(
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

  // Create augmented matrix [A | I]
  let identity_matrix = identity(n)
  let augmented = self.horizontal_combine(identity_matrix)
  
  // Apply Gauss-Jordan elimination
  let reduced = augmented.reduce_row_elimination()

  // Extract the inverse from the right half of the augmented matrix
  let inverse_matrix = Matrix::make(n, n, fn(i, j) { reduced[i][j + n] })
  return Some(inverse_matrix)
}
///|
/// Checks if a matrix is invertible (non-singular).
///
/// A matrix is invertible if its determinant is non-zero.
///
/// Parameters:
///
/// * `self` : The square matrix to check for invertibility.
///
/// Returns `true` if the matrix is invertible, `false` otherwise.
///
/// Panics if the matrix is not square.
///
/// Example:
///
/// ```moonbit
/// let m1 = @mutable.Matrix::from_2d_array([
///   [1.0, 2.0],
///   [3.0, 4.0]
/// ])
/// let m2 = @mutable.Matrix::from_2d_array([
///   [1.0, 2.0],
///   [2.0, 4.0]  // This is singular (second row is 2 times first row)
/// ])
/// inspect(m1.is_invertible(), content="true")
/// inspect(m2.is_invertible(), content="false")
/// ```
///
pub fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] is_invertible(
  self : Matrix[T],
) -> Bool {
  guard self.is_square() else {
    abort("Matrix must be square to check invertibility")
  }
  
  let det = self.determinant()
  return det.abs() > T::tolerance()
}
