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
/// ```moonbit
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
