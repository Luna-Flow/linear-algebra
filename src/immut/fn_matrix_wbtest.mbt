///|
/// Tests the horizontal and vertical combination operations of functional
/// matrices.
///
/// This test verifies that:
///
/// * `horizontal_combine` correctly concatenates two matrices side by side
/// * `vertical_combine` correctly stacks two matrices vertically
///
/// The test uses two 2×2 matrices:
///
/// * `m1`: A matrix with values \[\[1, 2], \[3, 4]]
/// * `m2`: An identity matrix \[\[1, 0], \[0, 1]]
///
/// Expected results:
///
/// * Horizontal combination produces a 2×4 matrix: \[\[1, 2, 1, 0], \[3, 4, 0,
///   1]]
/// * Vertical combination produces a 4×2 matrix: \[\[1, 2], \[3, 4], \[1, 0],
///   \[0, 1]]
///
/// Example:
///
/// ```moonbit nocheck
/// let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
///
/// let m2 = MatrixFn::from_2d_array([[1, 0], [0, 1]])
///
/// let horizontal = MatrixFn::horizontal_combine(m1, m2)
///
/// let vertical = MatrixFn::vertical_combine(m1, m2)
/// ```
///
test "matrix_combine" {
  let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m2 = MatrixFn::from_2d_array([[1, 0], [0, 1]])
  let m3 = MatrixFn::horizontal_combine(m1, m2)
  let m4 = MatrixFn::vertical_combine(m1, m2)
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
/// Validates comprehensive functionality of the MatrixFn type including basic
/// arithmetic operations, matrix multiplication, determinant calculation,
/// identity matrix creation, and matrix exponentiation.
///
/// This test verifies:
///
/// 1. **Matrix creation from 2D arrays**: Creates two matrices `m1` (\[\[1, 2],
/// \[3, 4]]) and `m2` (identity matrix \[\[1, 0], \[0, 1]])
/// 2. **Matrix multiplication**: Tests `m1 * m2` which should yield the
/// original matrix `m1` since multiplying by identity preserves the matrix
/// 3. **Matrix addition**: Tests `m1 + m2` which adds corresponding elements of
/// the two matrices
/// 4. **Matrix negation**: Tests the unary minus operator `-m1` which negates
/// all elements
/// 5. **Scalar multiplication**: Tests `m1.scale(10)` which multiplies all
/// elements by 10
/// 6. **Identity matrix creation**: Creates a 5×5 identity matrix using
/// `MatrixFn::identity`
/// 7. **Determinant calculation**: Computes determinants of various matrices:
///  * `m4` (result of addition) has determinant 4
///  * `m1` has determinant -2
///  * 5×5 identity matrix has determinant 1
/// 8. **Matrix exponentiation**: Creates a 3×3 matrix where each row has the
/// same value as its row index, then raises it to the 10th power
///
/// The test uses `inspect` statements to verify that each operation produces
/// the expected numerical results, ensuring the mathematical correctness of the
/// MatrixFn implementation.
///
test {
  let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m2 = MatrixFn::from_2d_array([[1, 0], [0, 1]])
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
  let m5 : MatrixFn[Int] = MatrixFn::identity(5)
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
test "matrix_access_and_equality" {
  let m = MatrixFn::from_2d_array([[1, 2], [3, 4]])

  // Test op_get (row access)
  inspect(m[0][1], content="2")
  inspect(m[1][0], content="3")

  // Test Eq
  let m2 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m3 = MatrixFn::from_2d_array([[1, 2], [3, 5]])
  inspect(m == m2, content="true")
  inspect(m == m3, content="false")
}

///|
test "matrix_fold" {
  let m = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let sum = m.fold(init=0, fn(acc, x) { acc + x })
  inspect(sum, content="10")
}

///|
test "matrix_creation" {
  // Test new (default)
  let m_def : MatrixFn[Int] = MatrixFn::new(2, 2)
  inspect(m_def, content="|0, 0|\n|0, 0|")

  // Test make (functional)
  let m_fun = MatrixFn::make(2, 2, fn(i, j) { i + j })
  inspect(m_fun, content="|0, 1|\n|1, 2|")
}

///|
test "matrix_empty_edge_cases" {
  let empty : MatrixFn[Int] = MatrixFn::from_2d_array([])
  inspect(empty, content="")
  let zero_col : MatrixFn[Int] = MatrixFn::from_2d_array([[], []])
  inspect(zero_col, content="||\n||")
  let product = MatrixFn::make(2, 0, fn(_, _) { 1 }) *
    MatrixFn::make(0, 3, fn(_, _) { 1 })
  inspect(product, content="|0, 0, 0|\n|0, 0, 0|")
}

///|
test "panic matrix_fn_from_2d_array/ragged_rows" {
  ignore(MatrixFn::from_2d_array([[1, 2], [3]]))
}

///|
test "panic matrix_fn_make/negative_dimensions" {
  let matrix : MatrixFn[Int] = MatrixFn::make(-1, 2, fn(i, j) { i + j })
  ignore(matrix)
}

///|
test "panic matrix_fn_new/negative_dimensions" {
  let matrix : MatrixFn[Int] = MatrixFn::new(2, -1)
  ignore(matrix)
}

///|
test "panic matrix_fn_identity/negative_size" {
  let matrix : MatrixFn[Int] = MatrixFn::identity(-1)
  ignore(matrix)
}

///|
test "panic matrix_fn_map_row/out_of_bounds" {
  let matrix = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  ignore(matrix.map_row(2, fn(x) { x }))
}

///|
test "panic matrix_fn_map_col/out_of_bounds" {
  let matrix = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  ignore(matrix.map_col(2, fn(x) { x }))
}

///|
test "matrix_mapping" {
  let m = MatrixFn::from_2d_array([[1, 2], [3, 4]])

  // Test map
  let m_map = m.map(fn(x) { x * 2 })
  inspect(m_map, content="|2, 4|\n|6, 8|")

  // Test map_row
  let m_row = m.map_row(0, fn(x) { x + 10 })
  inspect(m_row, content="|11, 12|\n|3, 4|")

  // Test map_col
  let m_col = m.map_col(1, fn(x) { x + 10 })
  inspect(m_col, content="|1, 12|\n|3, 14|")
}

///|
test "matrix_transpose_adjoint" {
  let m = MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let t = m.transpose()
  inspect(t, content="|1, 4|\n|2, 5|\n|3, 6|")
}

///|
test "matrix_adjoint_matches_transpose_for_real_matrices" {
  let m = MatrixFn::from_2d_array([
    [AdjointReal(1), AdjointReal(2), AdjointReal(3)],
    [AdjointReal(4), AdjointReal(5), AdjointReal(6)],
  ])
  inspect(m.adjoint(), content="|1, 4|\n|2, 5|\n|3, 6|")
}

///|
test "matrix_subtraction" {
  let m1 = MatrixFn::from_2d_array([[5, 6], [7, 8]])
  let m2 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let diff = m1 - m2
  inspect(diff, content="|4, 4|\n|4, 4|")
}

///|
test "matrix_swap" {
  let m = MatrixFn::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

  // Test swap_rows
  let m_sr = m.swap_rows(0, 2)
  inspect(m_sr, content="|7, 8, 9|\n|4, 5, 6|\n|1, 2, 3|")

  // Test swap_cols
  let m_sc = m.swap_cols(0, 2)
  inspect(m_sc, content="|3, 2, 1|\n|6, 5, 4|\n|9, 8, 7|")
}

///|
test "matrix_zip_with" {
  let m1 = MatrixFn::from_2d_array([[1, 2], [3, 4]])
  let m2 = MatrixFn::from_2d_array([[10, 20], [30, 40]])
  let zipped = m1.zip_with(m2, fn(a, b) { a * b })
  inspect(zipped, content="|10, 40|\n|90, 160|")
}
