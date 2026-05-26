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
/// ### Performance Best Practices:
///
/// 1. **Avoid Repeated Lens Allocation**: Accessing `m[i][j]` in a loop creates a `Lens` object 
///    on every call to `m[i]`. For bulk operations on a row, it is much faster to cache the 
///    row lens:
///    ```moonbit
///    let row = m[i] // Allocate once
///    for j in 0..<m.col {
///      row[j] = ... // Reuse cached lens
///    }
///    ```
/// 2. **Prefer Built-in Row/Col Tools**: Methods like `map_row_inplace`, `each_row`, `eachi_row`,
///    and `iter_row` are highly optimized and bypass the `Lens` abstraction entirely.
/// 3. **Manual Index Tracking**: For custom low-level loops, manually incrementing a 1D offset 
///    is more efficient than calculating `row * col + j` in every iteration.
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
/// let matrix = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// inspect(matrix.row(), content="2")
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
pub fn[T] Matrix::col(self : Matrix[T]) -> Int {
  self.col
}

///|
/// Converts a matrix to its string representation in a readable format.
///
/// Parameters:
///
/// * `self` : The matrix to convert to a string.
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
pub impl[T : Show] Show for Matrix[T] with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
/// Implements output functionality for `Matrix[T]` by writing its string
/// representation to a logger.
///
/// Parameters:
///
/// * `self` : The matrix to be output.
/// * `logger` : The logger to write the matrix representation to.
///
pub impl[T : Show] Show for Matrix[T] with output(self, logger) {
  for i in 0..<self.row {
    logger.write_char('|')
    self.eachi_row(i, (c, x) => {
      logger.write_object(x)
      if c < self.col - 1 {
        logger.write_string(", ")
      }
    })
    logger.write_char('|')
    if i < self.row - 1 {
      logger.write_char('\n')
    }
  }
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
/// Applies a function to every element of the matrix with its index, creating a
/// new matrix with the transformed elements.
///
/// Parameters:
///
/// * `self` : The input matrix to transform.
/// * `f` : The function to apply to each element, taking the row index, column
///   index, and value of type `T`, and returning a value of type `U`.
///
/// Returns a new matrix with the same dimensions as the input matrix.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
/// let m2 = m.mapi(fn(i, j, x) { x + i + j })
/// inspect(m2, content="|1, 3|\n|4, 6|")
/// ```
///
pub fn[T, U] Matrix::mapi(
  self : Matrix[T],
  f : (Int, Int, T) -> U,
) -> Matrix[U] {
  let row = self.row
  let col = self.col
  if row == 0 || col == 0 {
    return { row, col, data: [] }
  }
  // Avoid division and modulo in the loop by using nested loops.
  // This is significantly faster for large matrices.
  let data = Array::make(row * col, f(0, 0, self.data[0]))
  let mut idx = 0
  for i in 0..<row {
    for j in 0..<col {
      data[idx] = f(i, j, self.data[idx])
      idx += 1
    }
  }
  { row, col, data }
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
#alias(map_in_place, deprecated)
pub fn[T] Matrix::map_inplace(self : Matrix[T], f : (T) -> T) -> Unit {
  self.data.map_in_place(f)
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
/// inspect(m.to_transpose(), content="|1, 4|\n|2, 5|\n|3, 6|")
/// // The transpose has 3 rows and 2 columns (original was 2x3)
/// ```
///
pub fn[T] Matrix::to_transpose(self : Matrix[T]) -> Transpose[T] {
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
#alias(map_row_in_place, deprecated)
pub fn[T] Matrix::map_row_inplace(
  self : Matrix[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  let offset = row * self.col
  let data = self.data
  for i in 0..<self.col {
    let idx = offset + i
    data[idx] = f(data[idx])
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
#alias(map_col_in_place, deprecated)
pub fn[T] Matrix::map_col_inplace(
  self : Matrix[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  let rows = self.row
  let cols = self.col
  let data = self.data
  for i in 0..<rows {
    let idx = i * cols + col
    data[idx] = f(data[idx])
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
  let rows = self.row
  let cols = self.col
  let data = self.data
  for i in 0..<rows {
    let offset = i * cols
    for j in 0..<cols {
      f(i, j, data[offset + j])
    }
  }
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
  let offset = row * self.col
  let data = self.data
  for i in 0..<self.col {
    f(data[offset + i])
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
  let offset = row * self.col
  let data = self.data
  for i in 0..<self.col {
    f(i, data[offset + i])
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
  let rows = self.row
  let cols = self.col
  let data = self.data
  for i in 0..<rows {
    f(data[i * cols + col])
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
/// inspect(identity, content="|1, 0, 0|\n|0, 1, 0|\n|0, 0, 1|")
/// // Create a matrix where each element equals its row index plus column index
/// let sum_matrix = Matrix::make(2, 3, fn(i, j) { i + j })
/// inspect(sum_matrix, content="|0, 1, 2|\n|1, 2, 3|")
/// ```
///
pub fn[A] Matrix::make(row : Int, col : Int, f : (Int, Int) -> A) -> Matrix[A] {
  if row <= 0 || col <= 0 {
    return { row, col, data: [] }
  }
  let init = f(0, 0)
  let data = Array::make(row * col, init)
  for i = 0; i < row; i = i + 1 {
    let r_off = i * col
    for j = 0; j < col; j = j + 1 {
      data[r_off + j] = f(i, j)
    }
  }
  { row, col, data }
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
  if row <= 0 || col <= 0 {
    return { row, col, data: [] }
  }
  { row, col, data: Array::make(row * col, elem) }
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
  let row = arr.length()
  if row == 0 {
    return { row: 0, col: 0, data: [] }
  }
  let col = arr[0].length()
  for row_arr in arr {
    guard row_arr.length() == col
  }
  if col == 0 {
    return { row, col, data: [] }
  }
  let data = Array::make(row * col, arr[0][0])
  for i in 0..<row {
    let offset = i * col
    let row_arr = arr[i]
    for j in 0..<col {
      data[offset + j] = row_arr[j]
    }
  }
  { row, col, data }
}

///|
pub fn[T] Matrix::get(self : Matrix[T], row : Int, col : Int) -> T {
  self.data[row * self.col + col]
}

///|
pub fn[T] Matrix::set(self : Matrix[T], row : Int, col : Int, elem : T) -> Unit {
  self.data[row * self.col + col] = elem
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
/// **Performance Note**: Calling `m[row]` allocates a new `Lens` object and two closures.
/// For performance-critical bulk operations on a row, it is highly recommended to:
/// 1. **Cache the lens**: Store the result of `m[row]` in a variable before the loop.
/// 2. **Use built-in tools**: For common operations, use `each_row`, `map_row_inplace`, 
///    or `iter_row` which avoid Lens overhead entirely.
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
/// let row_lens = m[1]  // Caching the lens for row 1
/// inspect(row_lens[0], content="4")  // Access element at column 0
/// row_lens[2] = 10  // Set element at column 2
/// inspect(m[1][2], content="10")
/// ```
///
pub fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Lens[T] {
  { data: self, fst: row, offset: row * self.col, is_transpose: false }
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
pub fn[T] Lens::op_get(self : Lens[T], snd : Int) -> T {
  if self.is_transpose {
    self.data.get(snd, self.fst)
  } else {
    self.data.data[self.offset + snd]
  }
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
///
pub fn[T] Lens::op_set(self : Lens[T], snd : Int, elem : T) -> Unit {
  if self.is_transpose {
    self.data.set(snd, self.fst, elem)
  } else {
    self.data.data[self.offset + snd] = elem
  }
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
pub impl[T : AddMonoid + Mul] Mul for Matrix[T] with mul(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  let row = self.row
  let col = other.col
  let inner = self.col
  guard inner == other.row
  // Hybrid Strategy for Performance:
  // 1. Small Case (N <= 64): Use i-j-k (dot-product) order to maximize register accumulation.
  //    Manual indexing hoisting is applied here to minimize instructions in the innermost loop.
  // 2. Large Case (N > 64): Use i-k-j (scan line) order to maximize L1/L2 cache locality.
  //    Natural indexing (i * n + j) is preferred to trigger compiler strength reduction and bounds check elimination.
  if row <= 64 && col <= 64 && inner <= 64 {
    let data = Array::make(row * col, T::zero())
    for i = 0; i < row; i = i + 1 {
      let row_offset = i * col // self[i][...]
      let self_row_offset = i * inner // result[i][...]
      for j = 0; j < col; j = j + 1 {
        let mut sum = T::zero()
        for k = 0; k < inner; k = k + 1 {
          // Calculation equivalent to: result[i][j] += self[i][k] * other[k][j]
          sum = sum + self.data[self_row_offset + k] * other.data[k * col + j]
        }
        data[row_offset + j] = sum
      }
    }
    { row, col, data }
  } else {
    let data = Array::make(row * col, T::zero())
    let mut res_idx = 0
    for i = 0; i < row; i = i + 1 {
      let self_row_start = i * inner
      for k = 0; k < inner; k = k + 1 {
        let aik = self.data[self_row_start + k]
        let other_row_start = k * col
        for j = 0; j < col; j = j + 1 {
          data[res_idx + j] = data[res_idx + j] +
            aik * other.data[other_row_start + j]
        }
      }
      res_idx += col
    }
    { row, col, data }
  }
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
pub impl[T : Neg] Neg for Matrix[T] with neg(self : Matrix[T]) -> Matrix[T] {
  self.map(T::neg)
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
/// inspect(result, content="|4, 5|\n|6, 7|")
/// ```
///
pub impl[T : Add + Neg] Sub for Matrix[T] with sub(
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
pub fn[T : Mul] Matrix::scale(self : Matrix[T], cst : T) -> Matrix[T] {
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
pub fn[T : Add] Matrix::add_constant(self : Matrix[T], cst : T) -> Matrix[T] {
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
pub fn[T : Zero + One] identity(size : Int) -> Matrix[T] {
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
pub fn[T : Compare + Zero] Matrix::null(self : Matrix[T]) -> Bool {
  !self.data.iter().any(fn(x) { x != T::zero() })
}

///|
/// Computes the adjoint (conjugate transpose) of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to compute the adjoint of.
///
/// Returns the conjugate transpose of the original matrix.
pub fn[T : Conjugate] Matrix::adjoint(self : Matrix[T]) -> Matrix[T] {
  self.transpose().map(T::conjugate)
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
pub fn[T] Matrix::transpose(self : Matrix[T]) -> Matrix[T] {
  Matrix::make(self.col, self.row, fn(i, j) {
    // self[j][i]
    self.data[j * self.col + i]
  })
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
pub fn[T] Matrix::swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Unit {
  let c = self.col
  if r1 == r2 {
    return
  }
  let r1_off = r1 * self.col
  let r2_off = r2 * self.col
  for i in 0..<c {
    let tmp = self.data[r1_off + i]
    self.data[r1_off + i] = self.data[r2_off + i]
    self.data[r2_off + i] = tmp
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
pub fn[T] Matrix::swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Unit {
  let r = self.row
  if c1 == c2 {
    return
  }
  let col = self.col
  for i in 0..<r {
    let row_off = i * col
    let idx1 = row_off + c1
    let idx2 = row_off + c2
    let tmp = self.data[idx1]
    self.data[idx1] = self.data[idx2]
    self.data[idx2] = tmp
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
/// inspect(m_squared, content="|7, 10|\n|15, 22|")
/// ```
///
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
/// * `self` : The matrix to be reduced to reduced row echelon form.
///
/// Returns the same matrix instance after performing the row elimination
/// operations.
///
/// Columns whose remaining entries are all zero are skipped. Pivot inversion is
/// only performed after a nonzero pivot has been selected.
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
/// inspect(result, content="|1, 0, 0, 1|\n|0, 1, 0, -3|\n|0, 0, 1, 4|")
/// ```
///
pub fn[T : Compare + Field + Num] Matrix::reduce_row_elimination(
  self : Matrix[T],
) -> Matrix[T] {
  let r = self.row
  let c = self.col
  let mut col = 0
  for i in 0..<r {
    while col < c {
      let mut max_row = i
      for j in (i + 1)..<r {
        // self[j][col].abs() > self[max_row][col].abs()
        if self.data[j * c + col].abs() > self.data[max_row * c + col].abs() {
          max_row = j
        }
      }
      ignore(self.swap_rows(i, max_row))
      // self[i][col]
      if self.data[i * c + col] == T::zero() {
        col = col + 1
        continue
      }
      // self[i][col]
      let factor_inv = self.data[i * c + col].inv()
      ignore(self.map_row_inplace(i, fn(x) { x * factor_inv }))
      for j in 0..<r {
        if j == i {
          continue
        }
        // self[j][col]
        let factor = self.data[j * c + col]
        for k in 0..<c {
          // self[j][k] = self[j][k] - self[i][k] * factor
          self.data[j * c + k] = self.data[j * c + k] -
            self.data[i * c + k] * factor
        }
      }
      col = col + 1
      break
    }
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
pub fn[T] Matrix::horizontal_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.row == other.row
  Matrix::make(self.row, self.col + other.col, fn(i, j) {
    if j < self.col {
      // self[i][j]
      self.data[i * self.col + j]
    } else {
      // other[i][j - self.col]
      other.data[i * other.col + (j - self.col)]
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
/// inspect(result, content="|1, 2|\n|3, 4|\n|5, 6|\n|7, 8|")
/// ```
///
pub fn[T] Matrix::vertical_combine(
  self : Matrix[T],
  other : Matrix[T],
) -> Matrix[T] {
  guard self.col == other.col
  let self_data = self.data
  let other_data = other.data
  let data = []
  data.push_iter(self_data.iter())
  data.push_iter(other_data.iter())
  { row: self.row + other.row, col: self.col, data }
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
pub fn[T] Matrix::col_to_array(self : Matrix[T], col : Int) -> Array[T] {
  let row_count = self.row
  let col_count = self.col
  if row_count == 0 {
    return []
  }
  let data = self.data
  let res = Array::make(row_count, data[col])
  for i in 1..<row_count {
    res[i] = data[i * col_count + col]
  }
  res
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
  self.data.copy()
}

///|
pub fn[T] Matrix::row_to_array(self : Matrix[T], row : Int) -> Array[T] {
  let col_count = self.col
  if col_count == 0 {
    return []
  }
  let data = self.data
  let res = Array::make(col_count, data[row * col_count])
  for i in 1..<col_count {
    res[i] = data[row * col_count + i]
  }
  res
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
pub fn[T] Matrix::to_2d_array(self : Matrix[T]) -> Array[Array[T]] {
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
/// inspect(row_vector, content="|4, 5, 6|")
/// ```
///
pub fn[T] Matrix::row_to_vector(self : Matrix[T], row : Int) -> Vector[T] {
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
/// inspect(col1, content="|2, 5|")
/// ```
///
pub fn[T] Matrix::col_to_vector(self : Matrix[T], col : Int) -> Vector[T] {
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
pub fn[T] Matrix::to_vector(self : Matrix[T]) -> Vector[T] {
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
pub fn[T : Compare + Field + Num + Tolerance] Matrix::rank(
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
      let mut max_abs = data[pivot_row * col_count + pivot_col].abs()
      for candidate_row in (pivot_row + 1)..<row_count {
        let candidate_abs = data[candidate_row * col_count + pivot_col].abs()
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
      let pivot_row_offset = pivot_row * col_count
      let pivot = data[pivot_row_offset + pivot_col]
      for eliminate_row in (pivot_row + 1)..<row_count {
        let eliminate_offset = eliminate_row * col_count
        let factor = data[eliminate_offset + pivot_col] / pivot
        if factor.abs() < tol {
          data[eliminate_offset + pivot_col] = T::zero()
          continue
        }
        data[eliminate_offset + pivot_col] = T::zero()
        for col in (pivot_col + 1)..<col_count {
          data[eliminate_offset + col] = data[eliminate_offset + col] - factor * data[pivot_row_offset + col]
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
pub fn[T : AddMonoid] Matrix::trace(self : Matrix[T]) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate trace")
  }
  let mut sum = T::zero()
  for i in 0..<self.row {
    // self[i][i]
    sum = sum + self.data[i * self.col + i]
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
/// let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
/// let row_iter = m.iter_row(1)
/// for elem in row_iter {
///   println(elem) // prints: 4, 5, 6
/// }
/// ```
pub fn[T] Matrix::iter_row(self : Matrix[T], row : Int) -> Iter[T] {
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
pub fn[T] Matrix::iter_col(self : Matrix[T], col : Int) -> Iter[T] {
  self.transpose().iter_row(col)
}

///|
/// Computes eigenpairs for symmetric real matrices using the QR algorithm.
///
/// This routine currently supports only symmetric real matrices. General real
/// matrices may require complex eigenvalues and eigenvectors, which are not yet
/// available in this package.
/// 
/// Parameters:
/// 
/// * `self` : The square matrix to compute eigenvalues and eigenvectors for.
///
/// Returns a tuple containing:
/// * A vector of eigenvalues.
/// * A matrix where each column is an eigenvector corresponding to an
///   eigenvalue for supported symmetric inputs.
/// 
/// Panics if the matrix is not square.
/// 
/// Example:
/// 
/// ```moonbit
/// let m = Matrix::from_2d_array([[6.0, -2.0], [-2.0, 9.0]])
/// let (eigenvals, _) = m.eigen()
/// // eigenvals should be close to [5.0, 10.0]
/// // eigenvecs should be close to [[1.0, 0.0], [0.0, 1.0]]
///  let v1_ok = (eigenvals[0] - 5.0).abs() < Tolerance::tolerance() &&
///    (eigenvals[1] - 10.0).abs() < Tolerance::tolerance()
///  let v2_ok = (eigenvals[0] - 10.0).abs() < Tolerance::tolerance() &&
///    (eigenvals[1] - 5.0).abs() < Tolerance::tolerance()
///  assert_true(v1_ok || v2_ok)
/// ```
pub fn[T : Compare + Field + Num + Sqrt + Tolerance] Matrix::eigen(
  self : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  guard self.is_square() else {
    abort("Matrix must be square for eigenvalue computation")
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
/// Implements the QR algorithm for computing eigenvalues and eigenvectors.
/// 
/// This path first reduces the symmetric matrix to tridiagonal form and then
/// applies an implicit symmetric tridiagonal iteration to recover eigenpairs.
fn[T : Compare + Field + Num + Sqrt + Tolerance] qr_algorithm(
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
  let (diagonal, off_diagonal, eigenvectors) = householder_tridiagonalize(matrix)
  symmetric_tridiagonal_eigen(diagonal, off_diagonal, eigenvectors)
}

///|
fn[T : Compare + Field + Num + Sqrt + Tolerance] householder_tridiagonalize(
  matrix : Matrix[T],
) -> (Array[T], Array[T], Matrix[T]) {
  let n = matrix.row
  let q = matrix.copy()
  let q_data = q.data
  let diagonal = Array::make(n, T::zero())
  let off_diagonal = Array::make(n, T::zero())
  if n == 0 {
    return (diagonal, off_diagonal, q)
  }
  for i = n - 1; i >= 1; i = i - 1 {
    let l = i - 1
    let mut h = T::zero()
    let mut scale = T::zero()
    if l > 0 {
      for k in 0..<(l + 1) {
        scale = scale + q_data[i * n + k].abs()
      }
      if scale <= T::tolerance() {
        off_diagonal[i] = q_data[i * n + l]
      } else {
        for k in 0..<(l + 1) {
          let idx = i * n + k
          q_data[idx] /= scale
          h = h + q_data[idx] * q_data[idx]
        }
        let f = q_data[i * n + l]
        let g_abs = h.sqrt()
        let g = if f >= T::zero() { -g_abs } else { g_abs }
        off_diagonal[i] = scale * g
        h = h - f * g
        q_data[i * n + l] = f - g
        let mut f_acc = T::zero()
        for j in 0..<(l + 1) {
          q_data[j * n + i] = q_data[i * n + j] / h
          let mut g_acc = T::zero()
          for k in 0..<(j + 1) {
            g_acc = g_acc + q_data[j * n + k] * q_data[i * n + k]
          }
          for k in (j + 1)..<(l + 1) {
            g_acc = g_acc + q_data[k * n + j] * q_data[i * n + k]
          }
          off_diagonal[j] = g_acc / h
          f_acc = f_acc + off_diagonal[j] * q_data[i * n + j]
        }
        let hh = f_acc / (h + h)
        for j in 0..<(l + 1) {
          let f_j = q_data[i * n + j]
          let g_j = off_diagonal[j] - hh * f_j
          off_diagonal[j] = g_j
          for k in 0..<(j + 1) {
            let idx = j * n + k
            q_data[idx] = q_data[idx] -
              (f_j * off_diagonal[k] + g_j * q_data[i * n + k])
          }
        }
      }
    } else {
      off_diagonal[i] = q_data[i * n + l]
    }
    diagonal[i] = h
  }
  diagonal[0] = T::zero()
  off_diagonal[0] = T::zero()
  for i in 0..<n {
    let l = i - 1
    if diagonal[i].abs() > T::tolerance() && l >= 0 {
      for j in 0..<(l + 1) {
        let mut g = T::zero()
        for k in 0..<(l + 1) {
          g = g + q_data[i * n + k] * q_data[k * n + j]
        }
        for k in 0..<(l + 1) {
          q_data[k * n + j] = q_data[k * n + j] - g * q_data[k * n + i]
        }
      }
    }
    diagonal[i] = q_data[i * n + i]
    q_data[i * n + i] = T::one()
    if l >= 0 {
      for j in 0..<(l + 1) {
        q_data[j * n + i] = T::zero()
        q_data[i * n + j] = T::zero()
      }
    }
  }
  (diagonal, off_diagonal, q)
}

///|
fn[T : Compare + Field + Num + Sqrt + Tolerance] symmetric_tridiagonal_eigen(
  diagonal : Array[T],
  off_diagonal : Array[T],
  eigenvectors : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  let n = diagonal.length()
  if n == 0 {
    return (Vector::from_array([]), eigenvectors)
  }
  let d = diagonal
  let e = off_diagonal
  let z_data = eigenvectors.data
  for i in 1..<n {
    e[i - 1] = e[i]
  }
  e[n - 1] = T::zero()
  let tol = T::tolerance()
  let two = T::one() + T::one()
  for l in 0..<n {
    let mut iter = 0
    while true {
      let mut m = l
      while m < n - 1 &&
        e[m].abs() > tol * (d[m].abs() + d[m + 1].abs() + T::one()) {
        m += 1
      }
      if m == l {
        break
      }
      if iter >= 60 {
        abort("symmetric_tridiagonal_eigen did not converge")
      }
      iter += 1
      let mut g = (d[l + 1] - d[l]) / (two * e[l])
      let mut r = (g * g + T::one()).sqrt()
      if g < T::zero() {
        r = -r
      }
      g = d[m] - d[l] + e[l] / (g + r)
      let mut s = T::one()
      let mut c = T::one()
      let mut p = T::zero()
      for i = m - 1; i >= l; i = i - 1 {
        let f = s * e[i]
        let b = c * e[i]
        if f.abs() >= g.abs() {
          c = g / f
          r = (c * c + T::one()).sqrt()
          e[i + 1] = f * r
          s = T::one() / r
          c = c * s
        } else {
          s = f / g
          r = (s * s + T::one()).sqrt()
          e[i + 1] = g * r
          c = T::one() / r
          s = s * c
        }
        g = d[i + 1] - p
        r = (d[i] - g) * s + two * c * b
        p = s * r
        d[i + 1] = g + p
        g = c * r - b
        for k in 0..<n {
          let idx_right = k * n + (i + 1)
          let idx_left = k * n + i
          let value = z_data[idx_right]
          z_data[idx_right] = s * z_data[idx_left] + c * value
          z_data[idx_left] = c * z_data[idx_left] - s * value
        }
      }
      d[l] = d[l] - p
      e[l] = g
      e[m] = T::zero()
    }
  }
  (Vector::from_array(d.copy()), eigenvectors)
}

///|
/// Performs QR decomposition of a matrix using the Gram-Schmidt process.
/// 
/// Parameters:
/// * `matrix` : The matrix to decompose.
/// 
/// Returns a tuple (Q, R) where Q is orthogonal and R is upper triangular.
fn[T : Compare + Field + Num + Sqrt + Tolerance] qr_decomposition(
  matrix : Matrix[T],
) -> (Matrix[T], Matrix[T]) {
  let m = matrix.row
  let n = matrix.col
  let q = identity(m)
  let r = matrix.copy()
  let q_data = q.data
  let r_data = r.data
  let two = T::one() + T::one()
  let tol = T::tolerance()
  let limit = if m < n { m } else { n }
  for k in 0..<limit {
    let mut norm_sq = T::zero()
    for i in k..<m {
      let value = r_data[i * n + k]
      norm_sq += value * value
    }
    let norm = norm_sq.sqrt()
    if norm <= tol {
      continue
    }
    let alpha = if r_data[k * n + k] >= T::zero() { -norm } else { norm }
    let v = Array::make(m - k, T::zero())
    v[0] = r_data[k * n + k] - alpha
    for i in (k + 1)..<m {
      v[i - k] = r_data[i * n + k]
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
        dot += v[i] * r_data[(k + i) * n + j]
      }
      for i in 0..<v.length() {
        let idx = (k + i) * n + j
        r_data[idx] -= two * v[i] * dot
      }
    }
    for i in 0..<m {
      let mut dot = T::zero()
      for t in 0..<v.length() {
        dot += q_data[i * m + (k + t)] * v[t]
      }
      for t in 0..<v.length() {
        let idx = i * m + (k + t)
        q_data[idx] -= two * dot * v[t]
      }
    }
    for i in (k + 1)..<m {
      let idx = i * n + k
      if r_data[idx].abs() <= tol {
        r_data[idx] = T::zero()
      }
    }
  }
  let q_out = Matrix::new(m, n, T::zero())
  let q_out_data = q_out.data
  for i in 0..<m {
    for j in 0..<n {
      q_out_data[i * n + j] = q_data[i * m + j]
    }
  }
  let r_out = Matrix::new(n, n, T::zero())
  let r_out_data = r_out.data
  let row_limit = if m < n { m } else { n }
  for i in 0..<row_limit {
    for j in 0..<n {
      r_out_data[i * n + j] = r_data[i * n + j]
    }
  }
  (q_out, r_out)
}

///|
/// Computes the dominant real eigenpair using the power method.
/// 
/// Parameters:
/// * `self` : The square matrix to compute the dominant eigenvalue and eigenvector for.
/// * `max_iterations` : The maximum number of iterations to perform.
/// 
/// Returns a tuple containing:
/// * The dominant eigenvalue.
/// * The corresponding eigenvector as a normalized vector.
///
/// Panics if the matrix is not square or if the iteration reaches a zero
/// vector, which happens for zero or nilpotent cases.
pub fn[T : Compare + Field + Num + Tolerance] Matrix::power_method(
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
  let x = Array::make(n, T::one())
  let y = Array::make(n, T::zero())
  let ax = Array::make(n, T::zero())
  for _ in 0..<max_iterations {
    self.mul_vec_into(Vector(x), y)
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
    for i in 0..<n {
      x[i] = y[i] / scale
    }
    self.mul_vec_into(Vector(x), ax)
    let mut numerator = T::zero()
    let mut denominator = T::zero()
    for i in 0..<n {
      let xi = x[i]
      numerator = numerator + xi * ax[i]
      denominator = denominator + xi * xi
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
      return Some((lambda, Vector(x.copy())))
    }
  }
  None
}

///|
/// Multiplies a matrix by a vector.
///
/// Parameters:
///
/// * `self` : The matrix to multiply.
/// * `vector` : The vector to multiply.
///
/// Returns a new vector that is the product of the matrix and the vector.
///
/// Panics if the number of columns in the matrix does not equal the length of
/// the vector.
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
  self.mul_vec_into(vector, res_data)
  Vector(res_data)
}

fn[T : AddMonoid + Mul] Matrix::mul_vec_into(
  self : Matrix[T],
  vector : Vector[T],
  out : Array[T],
) -> Unit {
  let m = self.row
  let n = self.col
  let v_data = vector.0
  guard n == v_data.length() else {
    abort("Matrix and vector dimensions are not compatible for multiplication")
  }
  guard m == out.length() else {
    abort("Output buffer length mismatch for matrix-vector multiplication")
  }
  let data = self.data
  let mut idx = 0
  for i = 0; i < m; i = i + 1 {
    let mut sum = T::zero()
    for j = 0; j < n; j = j + 1 {
      sum = sum + data[idx] * v_data[j]
      idx += 1
    }
    out[i] = sum
  }
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
fn[T : Compare + Field + Num + Sqrt + Tolerance] Matrix::eigen_2x2(
  self : Matrix[T],
) -> (Vector[T], Matrix[T]) {
  let n = self.col
  let a = self.data[0 * n + 0]
  let b = self.data[0 * n + 1]
  let c = self.data[1 * n + 0]
  let d = self.data[1 * n + 1]
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

///|
/// Example:
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[4.0, 3.0], [6.0, 3.0]])
/// inspect(m.determinant(), content="-6")
/// ```
pub fn[T : Compare + Field + Num + Tolerance] Matrix::determinant(
  self : Matrix[T],
) -> T {
  guard self.is_square() else {
    abort("Matrix must be square to calculate determinant")
  }
  let n = self.row
  match n {
    0 => T::one()
    1 => self.data[0]
    2 => self.data[0] * self.data[3] - self.data[1] * self.data[2]
    3 => {
      let d = self.data
      d[0] * (d[4] * d[8] - d[5] * d[7]) -
      d[1] * (d[3] * d[8] - d[5] * d[6]) +
      d[2] * (d[3] * d[7] - d[4] * d[6])
    }
    4 => {
      let d = self.data
      let s01 = d[0] * d[5] - d[1] * d[4]
      let s02 = d[0] * d[6] - d[2] * d[4]
      let s03 = d[0] * d[7] - d[3] * d[4]
      let s12 = d[1] * d[6] - d[2] * d[5]
      let s13 = d[1] * d[7] - d[3] * d[5]
      let s23 = d[2] * d[7] - d[3] * d[6]
      let c01 = d[8] * d[13] - d[9] * d[12]
      let c02 = d[8] * d[14] - d[10] * d[12]
      let c03 = d[8] * d[15] - d[11] * d[12]
      let c12 = d[9] * d[14] - d[10] * d[13]
      let c13 = d[9] * d[15] - d[11] * d[13]
      let c23 = d[10] * d[15] - d[11] * d[14]
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
  lu.solve_identity_internal()
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
pub fn[T : Compare + Field + Num + Tolerance] Matrix::is_invertible(
  self : Matrix[T],
) -> Bool {
  guard self.is_square() else {
    abort("Matrix must be square to check invertibility")
  }
  !self.lu_decompose_internal().singular
}

///|
pub fn[T : Compare + Field + Num + Sqrt + Tolerance] Matrix::cholesky_decomposition(
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
        sum = sum + l.data[i * n + k] * l.data[j * n + k]
      }
      if i == j {
        let val = self.data[i * n + i] - sum
        if val <= T::tolerance() {
          return None
        }
        l.data[i * n + i] = val.sqrt()
      } else {
        l.data[i * n + j] =
          T::one() / l.data[j * n + j] * (self.data[i * n + j] - sum)
      }
    }
  }
  Some(l)
}

///|
/// Calculates the mean (average) of all elements in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to calculate the mean of.
///
/// Returns the mean value.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
/// inspect(m.mean(), content="2.5")
/// ```
///
pub fn[T : Field] Matrix::mean(self : Matrix[T]) -> T {
  guard self.row * self.col > 0 else {
    abort("Matrix::mean requires at least one element")
  }
  let (sum, count) = self.data.iter().fold(init=(T::zero(), T::zero()), fn(acc, x) {
    let (sum, count) = acc
    (sum + x, count + T::one())
  })
  sum / count
}

///|
/// Calculates the variance of the elements in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to calculate the variance of.
///
/// Returns the variance.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
/// inspect(m.variance(), content="1.25")
/// ```
///
pub fn[T : Field] Matrix::variance(self : Matrix[T]) -> T {
  guard self.row * self.col > 0 else {
    abort("Matrix::variance requires at least one element")
  }
  let m = self.mean()
  let (sum_sq_diff, count) = self.data
    .iter()
    .fold(init=(T::zero(), T::zero()), fn(acc, x) {
      let (sum_sq_diff, count) = acc
      let diff = x - m
      (sum_sq_diff + diff * diff, count + T::one())
    })
  sum_sq_diff / count
}

///|
/// Calculates the standard deviation of the elements in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to calculate the standard deviation of.
///
/// Returns the standard deviation.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
/// // sqrt(1.25) ≈ 1.118
///
/// let std = m.std_dev()
/// ```
///
pub fn[T : Field + Sqrt] Matrix::std_dev(self : Matrix[T]) -> T {
  guard self.row * self.col > 0 else {
    abort("Matrix::std_dev requires at least one element")
  }
  self.variance().sqrt()
}

///|
/// Checks if the matrix is symmetric (A^T = A).
///
/// Parameters:
///
/// * `self` : The matrix to check.
///
/// Returns `true` if symmetric, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 1.0]])
/// inspect(m.is_symmetric(), content="true")
/// ```
///
pub fn[T : Compare + Num + Tolerance] Matrix::is_symmetric(
  self : Matrix[T],
) -> Bool {
  if self.row != self.col {
    return false
  }
  for i = 0; i < self.row; i = i + 1 {
    for j = i + 1; j < self.col; j = j + 1 {
      // (self[i][j] - self[j][i])
      if (self.data[i * self.col + j] - self.data[j * self.col + i]).abs() >
        T::tolerance() {
        return false
      }
    }
  }
  true
}

///|
/// Checks if the matrix is positive definite.
///
/// A matrix is positive definite if it is symmetric and all its eigenvalues are positive.
///
/// Parameters:
///
/// * `self` : The matrix to check.
///
/// Returns `true` if positive definite, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[2.0, 0.0], [0.0, 2.0]])
/// inspect(m.is_positive_definite(), content="true")
/// ```
///
pub fn[T : Compare + Field + Num + Sqrt + Tolerance] Matrix::is_positive_definite(
  self : Matrix[T],
) -> Bool {
  match self.cholesky_decomposition() {
    Some(_) => true
    None => false
  }
}

///|
/// Calculates the n-th power of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to raise to the power.
/// * `n` : The exponent.
///
/// Returns the matrix raised to the power `n`.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 1], [1, 0]])
/// let m2 = m.matrix_power(2)
/// inspect(m2, content="|2, 1|\n|1, 1|")
/// ```
///
pub fn[T : Semiring] Matrix::matrix_power(
  self : Matrix[T],
  n : Int,
) -> Matrix[T] {
  self.pow(n)
}

///|
/// Calculates the Frobenius norm of the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to calculate the norm of.
///
/// Returns the Frobenius norm.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
/// // sqrt(1^2 + 2^2 + 3^2 + 4^2) = sqrt(30) ≈ 5.477
///
/// let norm = m.frobenius_norm()
/// ```
///
pub fn[T : AddMonoid + Mul + Sqrt] Matrix::frobenius_norm(
  self : Matrix[T],
) -> T {
  let sum_sq = self.data.iter().fold(init=T::zero(), fn(acc, x) { acc + x * x })
  sum_sq.sqrt()
}

///|
/// Finds the maximum element in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to search.
///
/// Returns the maximum element.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[1, 5, 3], [2, 8, 1]])
/// inspect(m.max_element(), content="8")
/// ```
///
pub fn[T : Compare] Matrix::max_element(self : Matrix[T]) -> T {
  if self.data.length() == 0 {
    abort("Empty matrix")
  }
  let mut max_val = self.data[0]
  for i = 1; i < self.data.length(); i = i + 1 {
    if self.data[i] > max_val {
      max_val = self.data[i]
    }
  }
  max_val
}

///|
/// Finds the minimum element in the matrix.
///
/// Parameters:
///
/// * `self` : The matrix to search.
///
/// Returns the minimum element.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::from_2d_array([[5, 2, 8], [1, 9, 3]])
/// inspect(m.min_element(), content="1")
/// ```
///
pub fn[T : Compare] Matrix::min_element(self : Matrix[T]) -> T {
  if self.data.length() == 0 {
    abort("Empty matrix")
  }
  let mut min_val = self.data[0]
  for i = 1; i < self.data.length(); i = i + 1 {
    if self.data[i] < min_val {
      min_val = self.data[i]
    }
  }
  min_val
}
