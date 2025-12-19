///|
/// Tests the basic functionality of matrix creation, display, and element
/// access.
///
/// This test verifies that:
///
/// 1. A matrix can be created from a 2D array using `Matrix::from_2d_array`
/// 2. The matrix displays correctly with the expected string format
/// 3. Individual elements can be accessed using the `[row][col]` indexing
/// syntax
///
/// The test creates a 2×3 matrix from a 2D array, checks its string
/// representation matches the expected format with elements separated by commas
/// and rows enclosed in vertical bars, and verifies that element access at
/// position \[0]\[1] returns the correct value.
///
/// Example:
///
/// ```moonbit
/// test "basic matrix operations" {
///   let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
///   inspect(
///     m,
///     content=(
///       #||2, 3, 4|
///       #||1, 2, 3|
///     ),
///   )
///   inspect(m[0][1], content="3")
/// }
/// ```
///
test {
  let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
  inspect(
    m,
    content=(
      #||2, 3, 4|
      #||1, 2, 3|
    ),
  )
  inspect(m[0][1], content="3")
}

///|
/// Tests the horizontal and vertical combination methods for matrices.
///
/// This test verifies that:
///
/// 1. `horizontal_combine` correctly concatenates two matrices side by side,
/// placing the second matrix's columns to the right of the first matrix's
/// columns
/// 2. `vertical_combine` correctly concatenates two matrices vertically,
/// placing the second matrix's rows below the first matrix's rows
///
/// The test creates two 2×2 matrices:
///
/// * `m1`: A matrix with values \[\[1, 2], \[3, 4]]
/// * `m2`: An identity matrix with values \[\[1, 0], \[0, 1]]
///
/// For horizontal combination, the result should be a 2×4 matrix where the
/// columns of `m2` are appended to the right of `m1's` columns.
///
/// For vertical combination, the result should be a 4×2 matrix where the rows
/// of `m2` are appended below `m1's` rows.
///
/// Example:
///
/// ```moonbit
/// test "matrix_combine" {
///   let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
///   let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
///   let m3 = m1.horizontal_combine(m2)
///   let m4 = m1.vertical_combine(m2)
///   inspect(
///     m3,
///     content=(
///       #||1, 2, 1, 0|
///       #||3, 4, 0, 1|
///     ),
///   )
///   inspect(
///     m4,
///     content=(
///       #||1, 2|
///       #||3, 4|
///       #||1, 0|
///       #||0, 1|
///     ),
///   )
/// }
/// ```
///
test "matrix_combine" {
  let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
  let m3 = m1.horizontal_combine(m2)
  let m4 = m1.vertical_combine(m2)
  inspect(
    m3,
    content=(
      #||1, 2, 1, 0|
      #||3, 4, 0, 1|
    ),
  )
  inspect(
    m4,
    content=(
      #||1, 2|
      #||3, 4|
      #||1, 0|
      #||0, 1|
    ),
  )
}

///|
/// Tests matrix row and column swapping operations.
///
/// This test verifies the correctness of the `swap_rows` and `swap_cols`
/// methods by creating test matrices and checking that the swapping operations
/// produce the expected results.
///
/// The test creates two 2×2 matrices:
///
/// * `m1`: A matrix with values \[\[1, 2], \[3, 4]]
/// * `m2`: An identity matrix \[\[1, 0], \[0, 1]]
///
/// It then performs the following operations:
///
/// * Swaps rows 0 and 1 of `m1`, expecting the result \[\[3, 4], \[1, 2]]
/// * Swaps columns 0 and 1 of `m2`, expecting the result \[\[0, 1], \[1, 0]]
///
/// The test uses `inspect` statements to verify that the actual results match
/// the expected matrix configurations.
///
test "swap_matrix" {
  let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
  let m3 = m1.swap_rows(0, 1)
  let m4 = m2.swap_cols(0, 1)
  inspect(
    m3,
    content=(
      #||3, 4|
      #||1, 2|
    ),
  )
  inspect(
    m4,
    content=(
      #||0, 1|
      #||1, 0|
    ),
  )
}

///|
/// Comprehensive test suite demonstrating basic matrix operations and
/// properties.
///
/// This test verifies the correctness of fundamental matrix operations
/// including multiplication, addition, negation, scaling, identity matrix
/// creation, constant addition, determinant calculation, and matrix
/// exponentiation. It covers both 2x2 matrices and larger identity matrices to
/// ensure the operations work correctly across different matrix sizes.
///
/// The test creates two 2x2 matrices: a general matrix `m1` with values \[\[1,
/// 2], \[3, 4]] and an identity matrix `m2` with values \[\[1, 0], \[0, 1]]. It
/// then performs various operations and verifies the results:
///
/// * Matrix multiplication: `m1 * m2` should equal `m1` since multiplying by
///   identity preserves the original matrix
/// * Matrix addition: `m1 + m2` adds corresponding elements
/// * Matrix negation: `-m1` negates all elements
/// * Matrix scaling: `m1.scale(10)` multiplies all elements by 10
/// * Identity matrix creation: Creates a 5x5 identity matrix
/// * Constant addition: `m4.add_constant(10)` adds 10 to all elements
/// * Determinant calculation: Tests determinant computation for various
///   matrices
/// * Matrix exponentiation: `Matrix::make(3, 3, fn(i, _) -> Int { i }).pow(10)`
///   creates a special matrix and raises it to the 10th power
///
/// Expected results are verified using `inspect` statements that compare the
/// actual output with the expected matrix representations.
///
test {
  let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = Matrix::from_2d_array([[1, 0], [0, 1]])
  let m3 = m1 * m2
  let m4 = m1 + m2
  inspect(
    m3,
    content=(
      #||1, 2|
      #||3, 4|
    ),
  )
  inspect(
    m4,
    content=(
      #||2, 2|
      #||3, 5|
    ),
  )
  inspect(
    -m1,
    content=(
      #||-1, -2|
      #||-3, -4|
    ),
  )
  inspect(
    m1.scale(10),
    content=(
      #||10, 20|
      #||30, 40|
    ),
  )
  let m5 : Matrix[Int] = Matrix::identity(5)
  inspect(
    m5,
    content=(
      #||1, 0, 0, 0, 0|
      #||0, 1, 0, 0, 0|
      #||0, 0, 1, 0, 0|
      #||0, 0, 0, 1, 0|
      #||0, 0, 0, 0, 1|
    ),
  )
  inspect(
    m4.add_constant(10),
    content=(
      #||12, 12|
      #||13, 15|
    ),
  )
  inspect(m4.determinant(), content="4")
  inspect(m1.determinant(), content="-2")
  inspect(m5.determinant(), content="1")
  let m = Matrix::make(3, 3, fn(i, _) -> Int { i }).pow(10)
  inspect(
    m,
    content=(
      #||0, 0, 0|
      #||19683, 19683, 19683|
      #||39366, 39366, 39366|
    ),
  )
}

///|
test "matrix_trace" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
  inspect(m.trace(), content="15")
  let m2 = Matrix::from_2d_array([[1, 2], [3, 4], [5, 6]])
  inspect(m2.trace(), content="5")
}

///|
test "matrix_mapi" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = m.mapi(fn(i, j, x) { x + i + j })
  inspect(
    m2,
    content=(
      #||1, 3|
      #||4, 6|
    ),
  )
}

///|
test "matrix_swap_cols_optimized" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let m1 = m.swap_cols(0, 2)
  inspect(
    m1,
    content=(
      #||3, 2, 1|
      #||6, 5, 4|
    ),
  )
}

///|
test "matrix_creation_methods" {
  // Test Matrix::new
  let m1 = Matrix::new(2, 2, 5)
  inspect(m1, content="|5, 5|\n|5, 5|")

  // Test Matrix::make
  let m2 = Matrix::make(2, 2, fn(i, j) { i + j })
  inspect(m2, content="|0, 1|\n|1, 2|")

  // Test Matrix::from_array
  let arr = @immut/array.from_array([1, 2, 3, 4])
  let m3 = Matrix::from_array(2, 2, arr)
  inspect(m3, content="|1, 2|\n|3, 4|")
}

///|
test "matrix_conversion" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])

  // Test to_array
  let arr = m.to_array()
  inspect(arr, content="[1, 2, 3, 4]")

  // Test to_2d_array
  let arr_2d = m.to_2d_array()
  inspect(arr_2d, content="[[1, 2], [3, 4]]")
}

///|
test "matrix_transpose" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let t = m.transpose()
  inspect(t, content="|1, 4|\n|2, 5|\n|3, 6|")

  // Transpose of transpose is original
  inspect(t.transpose() == m, content="true")
}

///|
test "matrix_properties" {
  let m_sq = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m_rect = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let m_null = Matrix::new(2, 2, 0)

  // Test is_square
  inspect(m_sq.is_square(), content="true")
  inspect(m_rect.is_square(), content="false")

  // Test null
  inspect(m_null.null(), content="true")
  inspect(m_sq.null(), content="false")
}

///|
test "matrix_iteration" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])

  // Test iter
  let all_elems = m.iter().collect()
  inspect(all_elems, content="[1, 2, 3, 4]")

  // Test iter_row
  let row1 = m.iter_row(1).collect()
  inspect(row1, content="[3, 4]")

  // Test iter_col
  let col1 = m.iter_col(1).collect()
  inspect(col1, content="[2, 4]")
}

///|
test "matrix_modification" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])

  // Test set (immutable update)
  let m2 = m.set(0, 1, 99)
  inspect(m2, content="|1, 99|\n|3, 4|")
  inspect(m, content="|1, 2|\n|3, 4|") // Original should be unchanged
}

///|
test "matrix_map" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = m.map(fn(x) { x * 10 })
  inspect(m2, content="|10, 20|\n|30, 40|")
}

///|
test "matrix_subtraction" {
  let m1 = Matrix::from_2d_array([[5, 5], [5, 5]])
  let m2 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m3 = m1 - m2
  inspect(m3, content="|4, 3|\n|2, 1|")
}
