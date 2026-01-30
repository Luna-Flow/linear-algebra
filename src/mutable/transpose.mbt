///|
/// Returns a lens that provides indexed access to a specific row of the 
/// transposed matrix.
///
/// **Performance Note**: Calling `t[row]` allocates a new `Lens` object and several closures.
/// Since this is a transposed view, every access `t[row][col]` maps back to 
/// the underlying matrix. For performance-critical bulk operations, it is 
/// highly recommended to:
/// 1. **Cache the lens**: Store the result of `t[row]` in a variable before the loop.
/// 2. **Use built-in tools**: For common operations, use `eachi_row`, `map_row_in_place`, 
///    or `iter_row` which avoid Lens overhead entirely.
///
/// Parameters:
///
/// * `self` : The transposed matrix to access.
/// * `row` : The zero-based index of the row to access.
///
/// Returns a `Lens[T]` object for accessing elements in the specified row by 
/// column index.
pub fn[T] Transpose::op_get(self : Transpose[T], row : Int) -> Lens[T] {
  guard row >= 0 && row < self.row()
  {
    get: fn(col) {
      guard col >= 0 && col < self.col()
      // Index mapping for Transpose view:
      // Transpose[i][j] maps to UnderlyingMatrix[j][i]
      self.0.data[col * self.0.col + row]
    },
    set: fn(col, val) {
      guard col >= 0 && col < self.col()
      // Mapping: Transpose[i][j] = val -> UnderlyingMatrix[j][i] = val
      self.0.data[col * self.0.col + row] = val
    },
  }
}

///|
/// Matrix transpose view providing transposed access to an underlying matrix
/// without copying data.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::make(2, 3, fn(i, j) { i * 3 + j })
/// let t = m.to_transpose()
/// inspect(t.row(), content="3")  // Original matrix cols become rows
/// inspect(t.col(), content="2")  // Original matrix rows become cols
/// ```
///
pub struct Transpose[T](Matrix[T])

///|
/// Adds two transposed matrices element-wise.
///
/// Parameters:
///
/// * `a` : The first transposed matrix.
/// * `b` : The second transposed matrix.
///
/// Returns a new transposed matrix containing the element-wise sum of the input
/// matrices.
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::make(2, 3, (i, j) => i + j)
/// let m2 = Matrix::make(2, 3, (i, j) => i * j)
/// let t1 = m1.to_transpose()
/// let t2 = m2.to_transpose()
/// let sum = t1 + t2
/// inspect(sum, content=
///   #||0, 1|
///   #||1, 3|
///   #||2, 5|
/// )
/// ```
///
pub impl[T : Add] Add for Transpose[T] with add(a, b) {
  Transpose(a.0 + b.0)
}

///|
/// Converts a transposed matrix to its string representation with elements
/// arranged in rows and columns.
///
/// Parameters:
///
/// * `s` : The transposed matrix to convert to a string.
///
/// Returns a string representation where each row is enclosed in pipe
/// characters (`|`) and elements within each row are separated by commas and
/// spaces. Rows are separated by newlines.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::make(2, 3, (i, j) => i + j)
/// let t = m.to_transpose()
/// inspect(t.to_string(), content="|0, 1|\n|1, 2|\n|2, 3|")
/// ```
///
pub impl[T : Show] Show for Transpose[T] with to_string(s) {
  let res = StringBuilder::new()
  for i in 0..<s.row() {
    res.write_char('|')
    s.eachi_row(i, (c, x) => {
      res.write_string(x.to_string())
      if c < s.col() - 1 {
        res.write_string(", ")
      }
    })
    res.write_char('|')
    if i < s.row() - 1 {
      res.write_string("\n")
    }
  }
  res.to_string()
}

///|
/// Provides default output formatting for transposed matrices by delegating to
/// their string representation.
///
/// Parameters:
///
/// * `s` : The transposed matrix to output.
/// * `l` : The logger or output stream to write the formatted representation
///   to.
pub impl[T : Show] Show for Transpose[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
/// Implements matrix multiplication for transposed matrices.
///
/// Parameters:
///
/// * `a` : The left operand (first transposed matrix).
/// * `b` : The right operand (second transposed matrix).
///
/// Returns the result of multiplying the two transposed matrices, where the
/// multiplication is performed as `b * a` on the underlying matrices due to the
/// transposed nature.
///
/// Example:
///
/// ```moonbit
/// let m1 = @mutable.Matrix::make(2, 3, fn(i, j) { i + j })
/// let m2 = @mutable.Matrix::make(3, 2, fn(i, j) { i * j + 1 })
/// let t1 = m1.to_transpose()
/// let t2 = m2.to_transpose()
/// let result = t1 * t2
/// inspect(result, content=
///   #||1, 2, 3|
///   #||3, 5, 7|
///   #||5, 8, 11|
/// )
/// ```
///
pub impl[T : AddMonoid + Mul] Mul for Transpose[T] with mul(a, b) {
  // Leverage the matrix identity: A^T * B^T = (B * A)^T
  // This allows us to reuse the heavily optimized Matrix multiplication logic
  // by just swapping the operand order, effectively performing the multiplication 
  // on the transposed views without any data movement or manual loop management.
  Transpose(b.0 * a.0)
}

///|
/// Implements the negation operation for transposed matrices.
///
/// Parameters:
///
/// * `a` : The transposed matrix to negate.
///
/// Returns a new `Transpose[T]` where each element is the negation of the
/// corresponding element in the input transposed matrix.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::make(2, 2, (i, j) => i + j)
/// let t = m.to_transpose()
/// let neg_t = -t
/// inspect(neg_t, content="|0, -1|\n|-1, -2|")
/// ```
///
pub impl[T : Neg] Neg for Transpose[T] with neg(a) {
  Transpose(-a.0)
}

///|
/// Subtracts one transpose matrix from another.
///
/// Parameters:
///
/// * `a` : The transpose matrix to subtract from.
/// * `b` : The transpose matrix to subtract.
///
/// Returns a new transpose matrix that is the result of the subtraction.
///
pub impl[T : Add + Neg] Sub for Transpose[T] with sub(a, b) {
  Transpose(a.0 - b.0)
}

///|
/// Compares two transposed matrices for equality.
///
/// Parameters:
///
/// * `a` : The first transposed matrix to compare.
/// * `b` : The second transposed matrix to compare.
///
/// Returns `true` if the two transposed matrices are equal, `false` otherwise.
///
pub impl[T : Eq] Eq for Transpose[T] with equal(a, b) {
  a.0 == b.0
}

///|
/// Returns the number of rows in the transpose matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix.
///
/// Returns the number of rows, which equals the number of columns in the
/// original matrix.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::make(3, 4, (i, j) => i + j)
/// let t = m.to_transpose()
/// inspect(t.row(), content="4")  // Original matrix has 4 columns, so transpose has 4 rows
/// ```
///
pub fn[T] Transpose::row(self : Transpose[T]) -> Int {
  self.0.col
}

///|
/// Returns the number of columns in the transpose matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix to get the column count from.
///
/// Returns the number of columns in the transpose matrix (which corresponds to
/// the number of rows in the original matrix).
///
/// Example:
///
/// ```moonbit
/// let matrix = @mutable.Matrix::make(3, 4, (i, j) => i * j)
/// let transpose = matrix.to_transpose()
/// inspect(transpose.col(), content="3")
/// ```
///
pub fn[T] Transpose::col(self : Transpose[T]) -> Int {
  self.0.row
}

///|
/// Iterates over each element in the transpose matrix and applies the given
/// function to each element.
///
/// Parameters:
///
/// * `self` : The transpose matrix to iterate over.
/// * `f` : A function that takes an element of type `T` and performs some
///   operation on it.
///
/// Example:
///
/// ```moonbit
/// let matrix = @mutable.Matrix::make(2, 3, (i, j) => i + j)
/// let transpose = matrix.to_transpose()
/// inspect(transpose, content="|0, 1|\n|1, 2|\n|2, 3|")
/// ```
///
pub fn[T] Transpose::each(self : Transpose[T], f : (T) -> Unit) -> Unit {
  self.0.each(f)
}

///|
/// Iterates over each element in the transpose with its linear index.
///
/// Parameters:
///
/// * `self` : The transpose matrix to iterate over.
/// * `f` : A function that takes the linear index and the element value. The
///   linear index is calculated in row-major order of the transpose (which
///   corresponds to column-major order of the underlying matrix).
pub fn[T] Transpose::eachi(self : Transpose[T], f : (Int, T) -> Unit) -> Unit {
  self.0.each_row_col((i, j, v) => f(j * self.0.row + i, v))
}

///|
/// Iterates over all elements in the specified row of the transposed matrix,
/// applying the given function to each element.
///
/// Parameters:
///
/// * `self` : The transposed matrix to iterate over.
/// * `row` : The zero-based index of the row to iterate over.
/// * `f` : The function to apply to each element in the row.
///
/// Panics if `row` is out of bounds (less than 0 or greater than or equal to
/// the number of rows).
pub fn[T] Transpose::each_row(
  self : Transpose[T],
  row : Int,
  f : (T) -> Unit,
) -> Unit {
  self.0.each_col(row, f)
}

///|
/// Iterates over each element in the specified row of the transposed matrix
/// with its column index, applying the given function to each index-element
/// pair.
///
/// Parameters:
///
/// * `self` : The transposed matrix to iterate over.
/// * `row` : The zero-based index of the row to iterate over.
/// * `f` : The function to apply to each column index and element in the row.
///   The first parameter is the column index, and the second parameter is the
///   element value.
///
/// Panics if `row` is out of bounds (less than 0 or greater than or equal to
/// the number of rows).
pub fn[T] Transpose::eachi_row(
  self : Transpose[T],
  row : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  self.0.eachi_col(row, f)
}

///|
/// Iterates over all elements in the specified column of the transposed matrix,
/// applying the given function to each element.
///
/// Parameters:
///
/// * `self` : The transposed matrix to iterate over.
/// * `col` : The column index to iterate through.
/// * `f` : The function to apply to each element in the column.
///
/// Panics if `col` is out of bounds (less than 0 or greater than or equal to
/// the number of columns).
pub fn[T] Transpose::each_col(
  self : Transpose[T],
  col : Int,
  f : (T) -> Unit,
) -> Unit {
  self.0.each_row(col, f)
}

///|
/// Iterates over each element in the specified column of the transposed matrix
/// with their indices within that column.
///
/// Parameters:
///
/// * `self` : The transposed matrix to iterate over.
/// * `col` : The zero-based index of the column to iterate through.
/// * `f` : A function that takes the element index within the column and the
///   element value.
///
/// Panics if `col` is out of bounds (negative or greater than or equal to the
/// number of columns).
pub fn[T] Transpose::eachi_col(
  self : Transpose[T],
  col : Int,
  f : (Int, T) -> Unit,
) -> Unit {
  self.0.eachi_row(col, f)
}

///|
/// Iterates over all elements in the transpose matrix with their row and column
/// indices.
///
/// Parameters:
///
/// * `self` : The transpose matrix to iterate over.
/// * `f` : A function that takes the row index, column index, and element
///   value. Called for each element in the transpose matrix.
pub fn[T] Transpose::each_row_col(
  self : Transpose[T],
  f : (Int, Int, T) -> Unit,
) -> Unit {
  self.0.each_row_col((i, j, v) => f(j, i, v))
}

///|
/// Creates a deep copy of the transpose matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix to copy.
///
/// Returns a new transpose matrix that is a deep copy of the original.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::make(2, 3, fn(i, j) { i + j })
/// let t = m.to_transpose()
/// let t_copy = t.copy()
/// // t_copy is a separate copy of t
/// inspect(t_copy, content="|0, 1|\n|1, 2|\n|2, 3|")
/// ```
///
pub fn[T] Transpose::copy(self : Transpose[T]) -> Transpose[T] {
  Transpose(self.0.copy())
}

///|
/// Horizontally combines two transpose matrices by placing them side by side.
///
/// Parameters:
///
/// * `self` : The left transpose matrix.
/// * `other` : The right transpose matrix to be combined with the left one.
///
/// Returns a new transpose matrix with `other` placed to the right of `self`.
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::make(2, 3, (i, j) => i + j)
/// let m2 = Matrix::make(2, 3, (i, j) => (i + j) * 10)
/// let t1 = m1.to_transpose()
/// let t2 = m2.to_transpose()
/// let combined = t1.horizontal_combine(t2)
/// inspect(combined.col(), content="4")
/// inspect(combined.row(), content="3")
/// ```
///
pub fn[T] Transpose::horizontal_combine(
  self : Transpose[T],
  other : Transpose[T],
) -> Transpose[T] {
  Transpose(self.0.vertical_combine(other.0))
}

///|
/// Vertically combines this transposed matrix with another transposed matrix,
/// placing the other matrix below this matrix.
///
/// Parameters:
///
/// * `self` : The transposed matrix to be placed on top.
/// * `other` : The transposed matrix to be placed below this matrix.
///
/// Returns a new transposed matrix with the combined content.
///
/// Example:
///
/// ```moonbit
/// let m1 = Matrix::make(2, 3, (i, j) => i + j)
/// let m2 = Matrix::make(2, 3, (i, j) => (i + j) * 10)
/// let t1 = m1.to_transpose()
/// let t2 = m2.to_transpose()
/// let combined = t1.vertical_combine(t2)
/// inspect(combined.row(), content="6") // 3 + 3 columns becomes 6 rows in transpose
/// inspect(combined.col(), content="2") // 2 rows becomes 2 columns in transpose
/// ```
///
pub fn[T] Transpose::vertical_combine(
  self : Transpose[T],
  other : Transpose[T],
) -> Transpose[T] {
  Transpose(self.0.horizontal_combine(other.0))
}

///|
/// Applies a function to each element of the transpose matrix and returns a new
/// transpose matrix with the transformed elements.
///
/// Parameters:
///
/// * `self` : The transpose matrix to transform.
/// * `f` : The function to apply to each element.
///
/// Returns a new transpose matrix where each element is the result of applying
/// `f` to the corresponding element in the original transpose matrix.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::make(2, 3, (i, j) => i + j)
/// let t = m.to_transpose()
/// let doubled = t.map(x => x * 2)
/// inspect(doubled, content="|0, 2|\n|2, 4|\n|4, 6|")
/// ```
///
pub fn[T] Transpose::map(self : Transpose[T], f : (T) -> T) -> Transpose[T] {
  Transpose(self.0.map(f))
}

///|
/// Applies a function to each element of the transpose matrix in-place,
/// modifying the original matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix to modify.
/// * `f` : The function to apply to each element, which takes an element and
///   returns a new element of the same type.
///
/// Example:
/// ```moonbit
/// let matrix = @mutable.Matrix::make(2, 3, fn(i, j) { i + j })
/// inspect(matrix, content=>
///   #||0, 1, 2|
///   #||1, 2, 3|
/// )
/// let transpose = matrix.to_transpose()
/// transpose.map_in_place(fn(x) { x + 1 })
/// inspect(transpose, content=>
///   #||1, 2|
///   #||2, 3|
///   #||3, 4|
/// )
/// ```
/// 
#alias(map_inplace, deprecated)
pub fn[T] Transpose::map_in_place(self : Transpose[T], f : (T) -> T) -> Unit {
  self.0.map_in_place(f)
}

///|
/// Applies a transformation function to each element in the specified column of
/// the transpose matrix in-place.
///
/// Parameters:
///
/// * `self` : The transpose matrix to modify.
/// * `col` : The zero-based index of the column to transform.
/// * `f` : The transformation function to apply to each element in the column.
///
/// Panics if `col` is out of bounds (negative or greater than or equal to the
/// number of columns).
///
/// Example:
///
/// ```moonbit
/// let matrix = @mutable.Matrix::make(2, 3, fn(i, j) { i + j })
/// let transpose = matrix.to_transpose()
/// // Double all elements in column 1
/// transpose.map_col_in_place(1, fn(x) { x * 2 })
/// ```
///
#alias(map_col_inplace, deprecated)
pub fn[T] Transpose::map_col_in_place(
  self : Transpose[T],
  col : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_row_in_place(col, f)
}

///|
/// Applies a transformation function to each element in the specified row of
/// the transposed matrix in-place.
///
/// Parameters:
///
/// * `self` : The transposed matrix to modify.
/// * `row` : The index of the row to transform.
/// * `f` : The transformation function to apply to each element in the row.
///
/// Panics if `row` is out of bounds (less than 0 or greater than or equal to
/// the number of rows).
///
/// Example:
///
/// ```moonbit
/// let matrix = @mutable.Matrix::make(3, 2, (i, j) => i + j)
/// let transposed = matrix.to_transpose()
/// // Double all elements in row 1
/// transposed.map_row_in_place(1, (x) => x * 2)
/// ```
///
#alias(map_row_inplace, deprecated)
pub fn[T] Transpose::map_row_in_place(
  self : Transpose[T],
  row : Int,
  f : (T) -> T,
) -> Unit {
  self.0.map_col_in_place(row, f)
}

///|
/// Extracts the specified row of the transpose matrix as an array.
///
/// Parameters:
///
/// * `self` : The transpose matrix to extract from.
/// * `row` : The index of the row to extract.
///
/// Returns an array containing all elements in the specified row.
///
/// Panics if `row` is out of bounds (negative or greater than or equal to the
/// number of rows in the transpose matrix).
///
///
pub fn[T] Transpose::row_to_array(self : Transpose[T], row : Int) -> Array[T] {
  self.0.col_to_array(row)
}

///|
/// Extracts a column from the transpose matrix as an array.
///
/// Parameters:
///
/// * `self` : The transpose matrix to extract the column from.
/// * `col` : The zero-based index of the column to extract.
///
/// Returns an array containing all elements in the specified column of the
/// transpose matrix.
///
/// Panics if the column index is out of bounds.
///
pub fn[T] Transpose::col_to_array(self : Transpose[T], col : Int) -> Array[T] {
  self.0.row_to_array(col)
}

///|
/// Extracts the specified row from the transposed matrix and returns it as a
/// vector.
///
/// Parameters:
///
/// * `self` : The transposed matrix to extract the row from.
/// * `row` : The index of the row to extract (0-based indexing).
///
/// Returns a `Vector[T]` containing the elements from the specified row of the
/// transposed matrix.
///
pub fn[T] Transpose::row_to_vector(self : Transpose[T], row : Int) -> Vector[T] {
  self.0.col_to_vector(row)
}

///|
/// Extracts the specified column from a transposed matrix as a vector.
///
/// Parameters:
///
/// * `self` : The transposed matrix to extract the column from.
/// * `col` : The zero-based index of the column to extract.
///
/// Returns a `Vector[T]` containing the elements of the specified column.
///
/// Example:
///
/// ```moonbit
/// let m = @mutable.Matrix::make(3, 2, (i, j) => i + j)
/// inspect(m, content=
///   #||0, 1|
///   #||1, 2|
///   #||2, 3|
/// )
/// let t = m.to_transpose()
/// inspect(t, content=
///   #||0, 1, 2|
///   #||1, 2, 3|
/// )
/// let col_vec = t.col_to_vector(0)
/// // col_vec contains the first column of the transposed matrix
/// inspect(col_vec, content="|0, 1|")
/// ```
///
pub fn[T] Transpose::col_to_vector(self : Transpose[T], col : Int) -> Vector[T] {
  self.0.row_to_vector(col)
}

///|
/// Adds a constant value to all elements of a transposed matrix.
///
/// Parameters:
///
/// * `self` : The transposed matrix to which the constant will be added.
/// * `constant` : The constant value to add to each element.
///
/// Returns a new transposed matrix where each element is the sum of the
/// corresponding element in the original matrix and the constant.
///
/// Example:
///
/// ```moonbit
/// let matrix = Matrix::make(2, 3, (i, j) => i + j)
/// inspect(matrix, content=
///   #||0, 1, 2|
///   #||1, 2, 3|
/// )
/// let transpose = matrix.to_transpose()
/// inspect(transpose, content=
///   #||0, 1|
///   #||1, 2|
///   #||2, 3|
/// ) 
/// let result = transpose.add_constant(5)
/// // Each element in the result will be 5 more than the corresponding element in the original transpose
/// inspect(result, content=
///   #||5, 6|
///   #||6, 7|
///   #||7, 8|
/// )
/// ```
///
pub fn[T : Add] Transpose::add_constant(
  self : Transpose[T],
  cst : T,
) -> Transpose[T] {
  Transpose(self.0.add_constant(cst))
}

///|
/// Scales all elements of the transposed matrix by a constant factor.
///
/// Parameters:
///
/// * `self` : The transposed matrix to scale.
/// * `constant` : The scaling factor to multiply each element by.
///
/// Returns a new transposed matrix where each element is multiplied by the
/// scaling factor.
///
/// Example:
///
/// ```moonbit
/// let matrix = Matrix::make(2, 3, (i, j) => i + j)
/// inspect(matrix, content=
///   #||0, 1, 2|
///   #||1, 2, 3|
/// )
/// let transpose = matrix.to_transpose()
/// inspect(transpose, content=
///   #||0, 1|
///   #||1, 2|
///   #||2, 3|
/// )
/// let scaled = transpose.scale(3)
/// inspect(scaled, content=
///   #||0, 3|
///   #||3, 6|
///   #||6, 9|
/// )
/// // Each element in the result will be 3 times the corresponding element in the original transpose
/// ```
///
pub fn[T : Mul] Transpose::scale(self : Transpose[T], cst : T) -> Transpose[T] {
  Transpose(self.0.scale(cst))
}

///|
/// Swaps two rows in the transpose matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix to modify.
/// * `r1` : The index of the first row to swap.
/// * `r2` : The index of the second row to swap.
///
pub fn[T] Transpose::swap_rows(self : Transpose[T], r1 : Int, r2 : Int) -> Unit {
  self.0.swap_cols(r1, r2)
}

///|
/// Swaps two columns in the transpose matrix.
///
/// Parameters:
///
/// * `self` : The transpose matrix to modify.
/// * `c1` : The index of the first column to swap.
/// * `c2` : The index of the second column to swap.
///
pub fn[T] Transpose::swap_cols(self : Transpose[T], c1 : Int, c2 : Int) -> Unit {
  self.0.swap_rows(c1, c2)
}

///|
/// Returns the underlying matrix by converting the transposed matrix back to
/// its original form.
///
/// Parameters:
///
/// * `self` : The transposed matrix to convert.
///
/// Returns the original `Matrix[T]` that was transposed to create this
/// `Transpose[T]`.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::make(2, 3, (i, j) => i + j)
/// let t = m.to_transpose()
/// let original = t.transpose()
/// inspect(original == m, content="true")
/// ```
///
pub fn[T] Transpose::transpose(self : Transpose[T]) -> Matrix[T] {
  self.0
}

///|
/// Converts a transpose view into a regular matrix by creating a new matrix
/// with the transposed data layout.
///
/// Parameters:
///
/// * `self` : The transpose view to materialize.
///
/// Returns a new `Matrix[T]` containing the same data as the transpose view but
/// with the elements physically rearranged in the transposed layout.
///
/// Example:
///
/// ```moonbit
/// let original = Matrix::make(2, 3, (i, j) => i * 3 + j)
/// inspect(original, content=
///   #||0, 1, 2|
///   #||3, 4, 5|
/// )
/// let transposed = original.to_transpose()
/// let materialized = transposed.materialize()
/// // materialized is now a 3x2 matrix with transposed layout
/// inspect(materialized, content=
///   #||0, 3|
///   #||1, 4|
///   #||2, 5|
/// )
/// ```
pub fn[T] Transpose::materialize(self : Transpose[T]) -> Matrix[T] {
  let r = self.row()
  let c = self.col()
  if r == 0 || c == 0 {
    return Matrix::from_array(r, c, [])
  }
  // Materialize the transposed view into a new physical Matrix.
  // Using direct nested loops to avoid the overhead of Lens abstractions and
  // division/modulo operations that would occur in a generic Matrix::make call.
  let m = self.0
  let data = Array::make(r * c, m.data[0])
  for i = 0; i < r; i = i + 1 {
    let row_offset = i * c // result[i][...]
    for j = 0; j < c; j = j + 1 {
      // Equivalent to result[i][j] = underlying[j][i]
      data[row_offset + j] = m.data[j * m.col + i]
    }
  }
  Matrix::from_array(r, c, data)
}
