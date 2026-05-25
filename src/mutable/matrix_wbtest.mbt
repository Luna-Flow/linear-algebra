using @lg { trait Integral }

struct AdjointReal(Int)

impl Conjugate for AdjointReal with conjugate(self) { self }

impl Show for AdjointReal with to_string(self) { self.0.to_string() }

impl Show for AdjointReal with output(self, logger) { logger.write_object(self.0) }

fn float_matrix_2x2(a00 : Int, a01 : Int, a10 : Int, a11 : Int) -> Matrix[Double] {
  let matrix : Matrix[Int] = Matrix::from_2d_array([[a00, a01], [a10, a11]])
  matrix.map(fn(n) { Integral::to_double(n) })
}

fn float_matrix_3x2(
  a00 : Int,
  a01 : Int,
  a10 : Int,
  a11 : Int,
  a20 : Int,
  a21 : Int,
) -> Matrix[Double] {
  let matrix : Matrix[Int] = Matrix::from_2d_array([
    [a00, a01],
    [a10, a11],
    [a20, a21],
  ])
  matrix.map(fn(n) { Integral::to_double(n) })
}

fn matrices_close(a : Matrix[Double], b : Matrix[Double], tol : Double) -> Bool {
  if a.row() != b.row() || a.col() != b.col() {
    return false
  }
  for i in 0..<a.row() {
    for j in 0..<a.col() {
      if (a.get(i, j) - b.get(i, j)).abs() > tol {
        return false
      }
    }
  }
  true
}

fn nonzero_double(n : Int) -> Double {
  Double::from_int(if n >= 0 { n + 1 } else { n - 1 })
}

///|
/// Tests the functionality of row and column mapping operations on matrices.
///
/// This test verifies that `map_row` and `map_col` methods correctly apply
/// transformation functions to specific rows and columns of a matrix while
/// leaving other elements unchanged.
///
/// The test creates a 2x3 matrix with values `[[1, 2, 3], [4, 5, 6]]` and
/// performs two operations:
///
/// 1. **Row mapping test**: Applies a doubling function to row 0, transforming
/// `[1, 2, 3]` to `[2, 4, 6]` while keeping row 1 unchanged as `[4, 5, 6]`.
///
/// 2. **Column mapping test**: Applies a doubling function to column 0,
/// transforming the first column from `[1, 4]` to `[2, 8]` while keeping other
/// columns unchanged.
///
/// The test validates that:
///
/// * `map_row` only affects the specified row
/// * `map_col` only affects the specified column
/// * Matrix copying works correctly to preserve the original matrix
/// * The transformation functions are applied element-wise correctly
/// * String representation of matrices displays the expected format
///
/// Example output:
///
/// * After row 0 mapping: `"|2, 4, 6|\n|4, 5, 6|"`
/// * After column 0 mapping: `"|2, 2, 3|\n|8, 5, 6|"`
///
test "map_function" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let m1 = {
    let m_ = m.copy()
    m_.map_row_inplace(0, fn(x) { x * 2 })
    m_
  }
  let m2 = {
    let m_ = m.copy()
    m_.map_col_inplace(0, fn(x) { x * 2 })
    m_
  }
  inspect(m1.to_string(), content="|2, 4, 6|\n|4, 5, 6|")
  inspect(m2.to_string(), content="|2, 2, 3|\n|8, 5, 6|")
}

///|
test "mapi" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = m.mapi(fn(i, j, x) { x + i + j })
  inspect(m2.to_string(), content="|1, 3|\n|4, 6|")
}

///|
/// Tests the matrix element assignment functionality through the `op_set`
/// operation.
///
/// This test verifies that matrix elements can be both read and modified using
/// the bracket notation syntax. It creates a 2x3 matrix, reads an element to
/// confirm its initial value, modifies that element, and then reads it again to
/// verify the change took effect.
///
/// Example:
///
/// ```moonbit
/// test {
///   let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
///   inspect(m[0][1], content="3") // Read element at row 0, column 1
///   m[0][1] = 4 // Modify element at row 0, column 1
///   inspect(m[0][1], content="4") // Verify the modification
/// }
/// ```
///
test "op_set" {
  let m = Matrix::from_2d_array([[2, 3, 4], [1, 2, 3]])
  inspect(m[0][1], content="3")
  m[0][1] = 4
  inspect(m[0][1], content="4")
}

///|
/// Tests the row and column swapping functionality of matrices.
///
/// This test verifies that the `swap_rows` and `swap_cols` methods correctly
/// exchange rows and columns in a matrix respectively. It creates a 2x3 matrix
/// and demonstrates:
///
/// 1. **Row swapping**: Exchanges rows 0 and 1, resulting in the first row
/// becoming the second row and vice versa.
/// 2. **Column swapping**: Exchanges columns 0 and 1, resulting in the first
/// column becoming the second column and vice versa.
///
/// The test uses `Matrix::from_2d_array` to create the initial matrix from a 2D
/// array, `copy()` to create independent copies for each operation, and
/// verifies the results using `inspect()` with the expected string
/// representations.
///
/// Example matrix transformations:
///
/// * Original: `|1, 2, 3|\n|4, 5, 6|`
/// * After row swap (0,1): `|4, 5, 6|\n|1, 2, 3|`
/// * After column swap (0,1): `|2, 1, 3|\n|5, 4, 6|`
///
test "swap" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let m1 = {
    let m_ = m.copy()
    m_.swap_rows(0, 1)
    m_
  }
  let m2 = {
    let m_ = m.copy()
    m_.swap_cols(0, 1)
    m_
  }
  inspect(m1.to_string(), content="|4, 5, 6|\n|1, 2, 3|")
  inspect(m2.to_string(), content="|2, 1, 3|\n|5, 4, 6|")
}

///|
/// Tests the row elimination reduction algorithm on a 3×4 matrix to verify it
/// produces the correct reduced row echelon form.
///
/// This test verifies that the `reduce_row_elimination` method correctly
/// performs Gaussian elimination with partial pivoting on a matrix. The test
/// uses a specific 3×4 matrix with known values and checks that the algorithm
/// produces the expected reduced row echelon form, where each row has a leading
/// 1 in a unique column and all other entries in those columns are zero.
///
/// The input matrix represents a system of linear equations:
///
/// * Row 1: 1x + 2y + 3z = 7
/// * Row 2: 1x + 1y + 1z = 2
/// * Row 3: 2x + 3y + 3z = 5
///
/// The expected output is the reduced row echelon form:
///
/// * Row 1: 1x + 0y + 0z = 1
/// * Row 2: 0x + 1y + 0z = -3
/// * Row 3: 0x + 0y + 1z = 4
///
/// This indicates the solution x = 1, y = -3, z = 4.
///
/// Example:
///
/// ```moonbit
/// let m = Matrix::from_2d_array([
///   [1.0, 2.0, 3.0, 7.0],
///   [1.0, 1.0, 1.0, 2.0],
///   [2.0, 3.0, 3.0, 5.0],
/// ])
///
/// let result = m.reduce_row_elimination()
/// // result should be in reduced row echelon form:
/// // |1, 0, 0, 1|
/// // |0, 1, 0, -3|
/// // |0, 0, 1, 4|
/// ```
///
test "reduce_row_elimination" {
  let m = Matrix::from_2d_array([
    [1.0, 2.0, 3.0, 7.0],
    [1.0, 1.0, 1.0, 2.0],
    [2.0, 3.0, 3.0, 5.0],
  ])
  inspect(
    m.reduce_row_elimination(),
    content=(
      #||1, 0, 0, 1|
      #||0, 1, 0, -3|
      #||0, 0, 1, 4|
    ),
  )
}

///|
test "reduce_row_elimination/skips_zero_pivot_columns" {
  let m = Matrix::from_2d_array([
    [0.0, 2.0, 1.0],
    [0.0, 0.0, 3.0],
  ])
  inspect(
    m.reduce_row_elimination(),
    content=(
      #||0, 1, 0|
      #||0, 0, 1|
    ),
  )
}

///|
/// Tests the functionality of matrix combination operations.
///
/// This test verifies that both horizontal and vertical matrix combination
/// operations work correctly by:
///
/// 1. Creating two 2x2 matrices - one containing values `[[1, 2], [3, 4]]` and
/// another containing the identity matrix `[[1, 0], [0, 1]]`
/// 2. Testing horizontal combination, which should concatenate matrices side by
/// side, resulting in a 2x4 matrix
/// 3. Testing vertical combination, which should stack matrices vertically,
/// resulting in a 4x2 matrix
/// 4. Verifying that the resulting matrices have the expected structure and
/// values
///
/// The test demonstrates that:
///
/// * `horizontal_combine` preserves row count while adding column counts
/// * `vertical_combine` preserves column count while adding row counts
/// * Element positioning is maintained correctly during both operations
///
/// Example matrices used:
///
/// * `m1`: A 2x2 matrix with values `[[1, 2], [3, 4]]`
/// * `m2`: A 2x2 identity matrix `[[1, 0], [0, 1]]`
///
/// Expected results:
///
/// * Horizontal combination: `[[1, 2, 1, 0], [3, 4, 0, 1]]` (2x4 matrix)
/// * Vertical combination: `[[1, 2], [3, 4], [1, 0], [0, 1]]` (4x2 matrix)
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
  inspect(m1, content="|1, 2|\n|3, 4|")
}

///|
test "matrix_combine/empty_shapes" {
  let empty = Matrix::new(0, 0, 0)
  let joined_empty = empty.horizontal_combine(empty)
  inspect(joined_empty.row(), content="0")
  inspect(joined_empty.col(), content="0")
  debug_inspect(joined_empty.to_2d_array(), content="[]")

  let left_zero_col = Matrix::from_2d_array([[], []])
  let right = Matrix::from_2d_array([[1, 2], [3, 4]])
  inspect(
    left_zero_col.horizontal_combine(right),
    content=(
      #||1, 2|
      #||3, 4|
    ),
  )

  let left = Matrix::from_2d_array([[1, 2], [3, 4]])
  let right_zero_col = Matrix::from_2d_array([[], []])
  inspect(
    left.horizontal_combine(right_zero_col),
    content=(
      #||1, 2|
      #||3, 4|
    ),
  )
}

test "from_2d_array/zero_col" {
  let m : Matrix[Int] = Matrix::from_2d_array([[], []])
  inspect(m.row(), content="2")
  inspect(m.col(), content="0")
  debug_inspect(m.to_array(), content="[]")
  debug_inspect(m.to_2d_array(), content="[[], []]")
  inspect(m.transpose().row(), content="0")
  inspect(m.transpose().col(), content="2")
  debug_inspect(m.transpose().to_2d_array(), content="[]")
}

test "panic from_2d_array/ragged_rows" {
  ignore(Matrix::from_2d_array([[1, 2], [3]]))
}

test "panic from_2d_array/ragged_zero_col" {
  ignore(Matrix::from_2d_array([[], [1]]))
}

///|
/// Tests the rank calculation of a matrix.
test "rank of matrix" {
  let m1 = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let m2 = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let m3 = Matrix::from_2d_array([[0.0, 0.0], [0.0, 0.0]])
  let m4 = Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
    [7.0, 8.0, 9.0],
  ])
  let r1 = m1.rank()
  let r2 = m2.rank()
  let r3 = m3.rank()
  let r4 = m4.rank()
  inspect(r1, content="2")
  inspect(r2, content="1")
  inspect(r3, content="0")
  inspect(r4, content="2")
}

///|
test "rank of matrix 2" {
  let m1 : Matrix[Float] = Matrix::from_2d_array([[1, 2], [3, 4]]).map(fn(n) {
    Integral::to_float(n)
  })
  let m2 : Matrix[Double] = Matrix::from_2d_array([[1, 2], [2, 4]]).map(fn(n) {
    Integral::to_double(n)
  })
  let m3 : Matrix[Float] = Matrix::from_2d_array([[0, 0], [0, 0]]).map(fn(n) {
    Integral::to_float(n)
  })
  let m4 : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ]).map(fn(n) { Integral::to_double(n) })
  let r1 = m1.rank()
  let r2 = m2.rank()
  let r3 = m3.rank()
  let r4 = m4.rank()
  inspect(r1, content="2")
  inspect(r2, content="1")
  inspect(r3, content="0")
  inspect(r4, content="2")
}

///|
/// Tests the trace calculation of matrices.
test "trace of matrix" {
  // Test 2x2 matrix
  let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
  let trace1 = m1.trace()
  inspect(trace1, content="5") // 1 + 4 = 5

  // Test 3x3 matrix
  let m2 = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
  let trace2 = m2.trace()
  inspect(trace2, content="15") // 1 + 5 + 9 = 15

  // Test identity matrix
  let id : Matrix[Int] = identity(3)
  let trace_id = id.trace()
  inspect(trace_id, content="3") // 1 + 1 + 1 = 3

  // Test zero matrix
  let zero = Matrix::new(2, 2, 0)
  let trace_zero = zero.trace()
  inspect(trace_zero, content="0") // 0 + 0 = 0

  // Test with floating point numbers
  let m3 = Matrix::from_2d_array([[1.5, 2.0], [3.0, 4.5]])
  let trace3 = m3.trace()
  inspect(trace3, content="6") // 1.5 + 4.5 = 6.0
}

///|
/// Tests trace calculation with different numeric types.
test "trace with different types" {
  // Test with Float type
  let m_float : Matrix[Float] = Matrix::from_2d_array([[1, 2], [3, 4]]).map(fn(n) {
    Integral::to_float(n)
  })
  let trace_float = m_float.trace()
  inspect(trace_float, content="5")

  // Test with Double type  
  let m_double : Matrix[Double] = Matrix::from_2d_array([[2, 1], [1, 3]]).map(fn(n) {
    Integral::to_double(n)
  })
  let trace_double = m_double.trace()
  inspect(trace_double, content="5")
}

///|
/// Tests the row and column iterator functionality.
test "row and column iterators" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])

  // Test row iterator
  let row1_elements = m.iter_row(1).collect()
  debug_inspect(row1_elements, content="[4, 5, 6]")

  // Test column iterator
  let col1_elements = m.iter_col(1).collect()
  debug_inspect(col1_elements, content="[2, 5]")
}

///|
/// Tests iterator functionality with functional operations.
test "iterator operations" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])

  // Sum elements in row 1
  let row1_sum = m.iter_row(1).fold(init=0, (acc, x) => acc + x)
  inspect(row1_sum, content="15") // 4 + 5 + 6 = 15

  // Find max element in column 0
  let col0_max = m
    .iter_col(0)
    .fold(init=0, (acc, x) => if x > acc { x } else { acc })
  inspect(col0_max, content="4") // max(1, 4) = 4

  // Double all elements in row 0
  let row0_doubled = m.iter_row(0).map(fn(x) { x * 2 }).collect()
  debug_inspect(row0_doubled, content="[2, 4, 6]")

  // Filter even elements in column 1
  let col1_evens = m.iter_col(1).filter(fn(x) { x % 2 == 0 }).collect()
  debug_inspect(col1_evens, content="[2]")
}

///|
test "adjoint matches transpose for real matrices" {
  let m = Matrix::from_2d_array([
    [AdjointReal(1), AdjointReal(2), AdjointReal(3)],
    [AdjointReal(4), AdjointReal(5), AdjointReal(6)],
  ])
  inspect(m.adjoint(), content="|1, 4|\n|2, 5|\n|3, 6|")
}

///|
/// Tests eigenvalue computation for various matrices.
test "eigenvalue computation" {
  // Test 2x2 symmetric matrix
  let m1 = Matrix::from_2d_array([[6.0, -2.0], [-2.0, 9.0]])
  let (vals1, _) = m1.eigen()

  // Expected eigenvalues are 5.0 and 10.0. Order may vary.
  let v1_ok = (vals1[0] - 5.0).abs() < Tolerance::tolerance() &&
    (vals1[1] - 10.0).abs() < Tolerance::tolerance()
  let v2_ok = (vals1[0] - 10.0).abs() < Tolerance::tolerance() &&
    (vals1[1] - 5.0).abs() < Tolerance::tolerance()
  inspect(v1_ok || v2_ok, content="true")

  // Test power method for dominant eigenvalue
  let power_pair = m1.power_method(100)
  inspect(power_pair is Some(_), content="true")
  let (dom_val, _) = power_pair.unwrap()
  inspect((dom_val - 10.0).abs() < Tolerance::tolerance(), content="true")

  // Test 2x2 analytical solution
  let (vals_2x2, _) = m1.eigen_2x2()
  let v3_ok = (vals_2x2[0] - 5.0).abs() < Tolerance::tolerance() &&
    (vals_2x2[1] - 10.0).abs() < Tolerance::tolerance()
  let v4_ok = (vals_2x2[0] - 10.0).abs() < Tolerance::tolerance() &&
    (vals_2x2[1] - 5.0).abs() < Tolerance::tolerance()
  inspect(v3_ok || v4_ok, content="true")
}

///|
test "panic eigen/non_symmetric" {
  let m = Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
  ignore(m.eigen())
}

///|
test "panic eigen_2x2/complex_spectrum" {
  let m = Matrix::from_2d_array([[0.0, -1.0], [1.0, 0.0]])
  ignore(m.eigen_2x2())
}

///|
/// Tests if the generated eigenvectors are correct by verifying the
/// fundamental property A*v = λ*v.
test "eigenvector verification" {
  // A simple 2x2 symmetric matrix with known eigenvalues (3, 1)
  // and eigenvectors.
  let m = Matrix::from_2d_array([[2.0, -1.0], [-1.0, 2.0]])
  let (eigenvals, eigenvecs) = m.eigen()

  // Helper function to check if two vectors are close enough
  fn vectors_are_close(
    v1 : Vector[Double],
    v2 : Vector[Double],
    tol : Double,
  ) -> Bool {
    if v1.length() != v2.length() {
      return false
    }
    for i in 0..<v1.length() {
      if (v1[i] - v2[i]).abs() > tol {
        return false
      }
    }
    return true
  }

  // Verify for the first eigenvector
  let v1 = eigenvecs.col_to_vector(0)
  let lambda1 = eigenvals[0]
  let m_v1 = m.mul_vec(v1)
  let lambda1_v1 = v1.map(x => x * lambda1)
  inspect(
    vectors_are_close(m_v1, lambda1_v1, Tolerance::tolerance()),
    content="true",
    // "First eigenvector check (A*v1 == λ1*v1)"
  )

  // Verify for the second eigenvector
  let v2 = eigenvecs.col_to_vector(1)
  let lambda2 = eigenvals[1]
  let m_v2 = m.mul_vec(v2)
  let lambda2_v2 = v2.map(x => x * lambda2)
  inspect(
    vectors_are_close(m_v2, lambda2_v2, Tolerance::tolerance()),
    content="true",
    // "Second eigenvector check (A*v2 == λ2*v2)"
  )
}

///|
test "eigenvector verification/3x3_symmetric" {
  let m = Matrix::from_2d_array([
    [4.0, 1.0, 1.0],
    [1.0, 3.0, 0.0],
    [1.0, 0.0, 2.0],
  ])
  let (eigenvals, eigenvecs) = m.eigen()

  fn vectors_are_close(
    v1 : Vector[Double],
    v2 : Vector[Double],
    tol : Double,
  ) -> Bool {
    if v1.length() != v2.length() {
      return false
    }
    for i in 0..<v1.length() {
      if (v1[i] - v2[i]).abs() > tol {
        return false
      }
    }
    true
  }

  for i in 0..<3 {
    let v = eigenvecs.col_to_vector(i)
    let lhs = m.mul_vec(v)
    let rhs = v.map(x => x * eigenvals[i])
    inspect(vectors_are_close(lhs, rhs, 1.0e-6), content="true")
  }
}

///|
/// Tests the determinant calculation for various matrices.
test "determinant calculation" {
  // Test 2x2 matrix
  let m1 = Matrix::from_2d_array([[4.0, 3.0], [6.0, 3.0]])
  // Expected: 4*3 - 3*6 = 12 - 18 = -6
  inspect(
    (m1.determinant() - -6.0).abs() < Tolerance::tolerance(),
    content="true",
  )

  // Test 3x3 matrix
  let m2 = Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [0.0, 1.0, 4.0],
    [5.0, 6.0, 0.0],
  ])
  // Expected: 1*(1*0 - 4*6) - 2*(0*0 - 4*5) + 3*(0*6 - 1*5) = -24 + 40 - 15 = 1
  inspect(
    (m2.determinant() - 1.0).abs() < Tolerance::tolerance(),
    content="true",
  )

  // Test matrix that requires a row swap
  let m3 = Matrix::from_2d_array([
    [0.0, 1.0, 4.0],
    [1.0, 2.0, 3.0],
    [5.0, 6.0, 0.0],
  ])
  // Expected: After swapping rows, determinant should be -1
  // Determinant should be the negative of m2's determinant
  inspect(
    (m3.determinant() - -1.0).abs() < Tolerance::tolerance(),
    content="true",
  )

  // Test singular matrix (linearly dependent rows)
  let m4 = Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
    [7.0, 8.0, 9.0],
  ])
  // Expected: Determinant should be 0 since rows are linearly dependent
  inspect(m4.determinant().abs() < Tolerance::tolerance(), content="true")

  // Test identity matrix
  let id : Matrix[Double] = identity(4)
  inspect(
    (id.determinant() - 1.0).abs() < Tolerance::tolerance(),
    content="true",
  )
}

///|
test "Matrix::is_invertible" {
  // Test clearly invertible matrices
  let invertible_2x2 = Matrix::from_2d_array([[2.0, 1.0], [1.0, 1.0]])
  inspect(invertible_2x2.is_invertible(), content="true")
  let invertible_3x3 = Matrix::from_2d_array([
    [1.0, 0.0, 0.0],
    [0.0, 2.0, 0.0],
    [0.0, 0.0, 3.0],
  ])
  inspect(invertible_3x3.is_invertible(), content="true")

  // Test clearly non-invertible (singular) matrices
  let singular_2x2 = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  inspect(singular_2x2.is_invertible(), content="false")
  let zero_matrix = Matrix::from_2d_array([[0.0, 0.0], [0.0, 0.0]])
  inspect(zero_matrix.is_invertible(), content="false")
}

///|
test "Matrix::is_invertible/edge_cases" {
  // Test 1x1 matrices
  let invertible_1x1 = Matrix::from_2d_array([[5.0]])
  inspect(invertible_1x1.is_invertible(), content="true")
  let zero_1x1 = Matrix::from_2d_array([[0.0]])
  inspect(zero_1x1.is_invertible(), content="false")

  // Test matrix with determinant very close to zero (should be non-invertible)
  let nearly_singular = Matrix::from_2d_array([
    [1.0, 1.0],
    [1.0, 1.000000000001],
  ])
  inspect(nearly_singular.is_invertible(), content="false")
}

///|
test "panic Matrix::is_invertible/non_square" {
  let non_square = Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  ignore(non_square.is_invertible())
}

///|
test "Matrix::inverse" {
  // Test 2x2 invertible matrix
  let m1 = Matrix::from_2d_array([[2.0, 1.0], [1.0, 1.0]])
  let inv1 = m1.inverse()
  inspect(inv1 is None, content="false")
  let product1 = m1 * inv1.unwrap()
  inspect(product1.get(0, 0).abs() - 1.0 < Tolerance::tolerance(), content="true")
  inspect(product1.get(0, 1).abs() < Tolerance::tolerance(), content="true")
  inspect(product1.get(1, 0).abs() < Tolerance::tolerance(), content="true")
  inspect((product1.get(1, 1) - 1.0).abs() < Tolerance::tolerance(), content="true")

  let pivoted = Matrix::from_2d_array([[0.0, 1.0], [1.0, 0.0]])
  let inv_pivoted = pivoted.inverse()
  inspect(inv_pivoted is None, content="false")
  inspect(inv_pivoted.unwrap(), content="|0, 1|\n|1, 0|")
  let product_pivoted = pivoted * inv_pivoted.unwrap()
  inspect((product_pivoted.get(0, 0) - 1.0).abs() < Tolerance::tolerance(), content="true")
  inspect(product_pivoted.get(0, 1).abs() < Tolerance::tolerance(), content="true")
  inspect(product_pivoted.get(1, 0).abs() < Tolerance::tolerance(), content="true")
  inspect((product_pivoted.get(1, 1) - 1.0).abs() < Tolerance::tolerance(), content="true")

  // Test 3x3 identity matrix (should return itself)
  let identity = Matrix::from_2d_array([
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [0.0, 0.0, 1.0],
  ])
  let inv_identity = identity.inverse()
  inspect(inv_identity is None, content="false")

  // Test singular (non-invertible) matrix
  let singular = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let inv_singular = singular.inverse()
  inspect(inv_singular is None, content="true")
}

///|
test "Matrix::inverse/edge_cases" {
  // Test 0x0 matrix
  let empty_matrix = Matrix::new(0, 0, 0.0)
  let inv_empty = empty_matrix.inverse()
  inspect(inv_empty is None, content="false")
  inspect(inv_empty.unwrap().row(), content="0")
  inspect(inv_empty.unwrap().col(), content="0")

  // Test 1x1 invertible matrix
  let one_by_one = Matrix::from_2d_array([[5.0]])
  let inv_one = one_by_one.inverse()
  inspect(inv_one is None, content="false")

  // Test 1x1 singular matrix (zero)
  let zero_matrix = Matrix::from_2d_array([[0.0]])
  let inv_zero = zero_matrix.inverse()
  inspect(inv_zero is None, content="true")
}

///|
test "panic Matrix::inverse/non_square" {
  let non_square = Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  ignore(non_square.inverse())
}

///|
test "iter" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let arr = m.iter().to_array()
  debug_inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "iter_row" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let row0 = m.iter_row(0).to_array()
  debug_inspect(row0, content="[1, 2]")
  let row1 = m.iter_row(1).to_array()
  debug_inspect(row1, content="[3, 4]")
}

///|
test "iter_col" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let col0 = m.iter_col(0).to_array()
  debug_inspect(col0, content="[1, 3]")
  let col1 = m.iter_col(1).to_array()
  debug_inspect(col1, content="[2, 4]")
}

///|
test "row_view_and_col_view" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row = m.row_view(1)
  let col = m.col_view(2)

  inspect(row.length(), content="3")
  inspect(col.length(), content="2")
  inspect(row[0], content="4")
  inspect(row[2], content="6")
  inspect(col[0], content="3")
  inspect(col[1], content="6")
  debug_inspect(row.to_array(), content="[4, 5, 6]")
  debug_inspect(col.to_array(), content="[3, 6]")
  inspect(row.to_vector(), content="|4, 5, 6|")
  inspect(col.to_vector(), content="|3, 6|")
}

///|
test "row_view_and_col_view_inplace" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row = m.row_view(0)
  let col = m.col_view(1)

  row[2] = 30
  col[1] = 50
  inspect(m.to_string(), content="|1, 2, 30|\n|4, 50, 6|")

  row.map_inplace(fn(x) { x + 1 })
  col.map_inplace(fn(x) { x * 2 })
  inspect(m.to_string(), content="|2, 6, 31|\n|4, 100, 6|")
}

///|
test "row_view_and_col_view_iteration" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row = m.row_view(0)
  let col = m.col_view(1)
  let mut row_sum = 0
  let mut col_sum = 0
  let indexed = []

  row.each(fn(x) { row_sum = row_sum + x })
  col.each(fn(x) { col_sum = col_sum + x })
  row.eachi(fn(i, x) { indexed.push(i + x) })

  debug_inspect(row.iter().to_array(), content="[1, 2, 3]")
  debug_inspect(col.iter().to_array(), content="[2, 5]")
  inspect(row_sum, content="6")
  inspect(col_sum, content="7")
  debug_inspect(indexed, content="[1, 3, 5]")
}

///|
test "row_view_and_col_view_reactivity" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row = m.row_view(1)
  let col = m.col_view(0)

  m.set(1, 1, 50)
  inspect(row[1], content="50")

  m.set(0, 0, 10)
  inspect(col[0], content="10")

  row[2] = 99
  inspect(m[1][2], content="99")

  col[1] = 77
  inspect(m[1][0], content="77")
}

///|
test "to_array" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  debug_inspect(m.to_array(), content="[1, 2, 3, 4]")
}

///|
test "to_2d_array" {
  let m = Matrix::from_2d_array([[1, 2], [3, 4]])
  let arr = m.to_2d_array()
  debug_inspect(arr, content="[[1, 2], [3, 4]]")
}

///|
test "is_square" {
  let m1 = Matrix::new(2, 2, 0)
  inspect(m1.is_square(), content="true")
  let m2 = Matrix::new(2, 3, 0)
  inspect(m2.is_square(), content="false")
}

///|
test "mean_variance_std_dev" {
  let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  // Mean: (1+2+3+4)/4 = 2.5
  inspect(m.mean(), content="2.5")

  // Variance: ((1-2.5)^2 + (2-2.5)^2 + (3-2.5)^2 + (4-2.5)^2) / 4
  // = (2.25 + 0.25 + 0.25 + 2.25) / 4 = 5.0 / 4 = 1.25
  inspect(m.variance(), content="1.25")

  // Std Dev: sqrt(1.25) ≈ 1.1180339887
  let std = m.std_dev()
  let diff = (std - 1.1180339887).abs()
  assert_true(diff < 1.0e-6)
}

///|
test "is_symmetric" {
  let m1 = Matrix::from_2d_array([[1.0, 2.0], [2.0, 1.0]])
  inspect(m1.is_symmetric(), content="true")
  let m2 = Matrix::from_2d_array([[1.0, 2.0], [3.0, 1.0]])
  inspect(m2.is_symmetric(), content="false")
  let m3 = Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  inspect(m3.is_symmetric(), content="false")
}

///|
test "is_positive_definite" {
  // Symmetric and positive eigenvalues
  let m1 = Matrix::from_2d_array([[2.0, 0.0], [0.0, 2.0]])
  inspect(m1.is_positive_definite(), content="true")

  // Symmetric but negative eigenvalue
  let m2 = Matrix::from_2d_array([[-2.0, 0.0], [0.0, -2.0]])
  inspect(m2.is_positive_definite(), content="false")

  // Not symmetric
  let m3 = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  inspect(m3.is_positive_definite(), content="false")

  // Symmetric positive semidefinite but not positive definite
  let m4 = Matrix::from_2d_array([[1.0, 1.0], [1.0, 1.0]])
  inspect(m4.is_positive_definite(), content="false")
}

///|
test "matrix_power" {
  let m = Matrix::from_2d_array([[1, 1], [1, 0]]) // Fibonacci matrix
  let m2 = m.matrix_power(2)
  inspect(m2.to_string(), content="|2, 1|\n|1, 1|")
  let m3 = m.matrix_power(3)
  inspect(m3.to_string(), content="|3, 2|\n|2, 1|")
  let m5 = m.matrix_power(5)
  inspect(m5.to_string(), content="|8, 5|\n|5, 3|")
  let id = m.matrix_power(0)
  inspect(id.to_string(), content="|1, 0|\n|0, 1|")
}

///|
test "frobenius_norm" {
  let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  // sqrt(1^2 + 2^2 + 3^2 + 4^2) = sqrt(1 + 4 + 9 + 16) = sqrt(30) ≈ 5.477225575
  let norm = m.frobenius_norm()
  let diff = (norm - 5.477225575).abs()
  assert_true(diff < 1.0e-6)
}

///|
test "min_max_element" {
  let m = Matrix::from_2d_array([[1, 5, 3], [2, 8, 1]])
  inspect(m.max_element(), content="8")
  inspect(m.min_element(), content="1")
  let m2 = Matrix::from_2d_array([[-5, -2], [-8, -1]])
  inspect(m2.max_element(), content="-1")
  inspect(m2.min_element(), content="-8")
}

///|
test "matrix_empty_edge_cases" {
  let m = Matrix::new(0, 0, 0.0)
  inspect(m.row(), content="0")
  inspect(m.col(), content="0")
  inspect(m.to_string(), content="")
  inspect(m.transpose().row(), content="0")
  inspect(m.transpose().col(), content="0")
  inspect(m.copy().row(), content="0")
  inspect(m.determinant(), content="1")
  inspect(m.inverse() is Some(_), content="true")
}

///|
test "matrix_1x1_edge_cases" {
  let m = Matrix::from_2d_array([[2.0]])
  inspect(m.determinant(), content="2")
  let inv = m.inverse().unwrap()
  inspect(inv[0][0], content="0.5")
  inspect(m.transpose()[0][0], content="2")
}

///|
test "matrix_non_square_ops" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let t = m.transpose()
  inspect(t.row(), content="3")
  inspect(t.col(), content="2")
  inspect(
    t.to_string(),
    content=(
      #||1, 4|
      #||2, 5|
      #||3, 6|
    ),
  )
  let m_wide = Matrix::new(2, 4, 1)
  let m_tall = Matrix::new(4, 2, 1)
  let prod = m_wide * m_tall
  inspect(prod.row(), content="2")
  inspect(prod.col(), content="2")
}

test "determinant_transpose_and_triangular_laws" {
  let upper = Matrix::from_2d_array([
    [2.0, 3.0, 5.0],
    [0.0, -7.0, 11.0],
    [0.0, 0.0, 13.0],
  ])
  inspect((upper.determinant() - -182.0).abs() < 1.0e-6, content="true")
  inspect(
    (upper.determinant() - upper.transpose().determinant()).abs() < 1.0e-6,
    content="true",
  )
}

test "inverse_is_two_sided_identity_for_non_diagonal_matrix" {
  let m = Matrix::from_2d_array([
    [4.0, 7.0, 2.0],
    [3.0, 6.0, 1.0],
    [2.0, 5.0, 1.0],
  ])
  let inv = m.inverse().unwrap()
  let left = m * inv
  let right = inv * m
  for i in 0..<left.row() {
    for j in 0..<left.col() {
      let expected = if i == j { 1.0 } else { 0.0 }
      assert_true((left.get(i, j) - expected).abs() < 1.0e-6)
      assert_true((right.get(i, j) - expected).abs() < 1.0e-6)
    }
  }
}

test "lu_based_invariants_agree" {
  let permutation_matrix = Matrix::from_2d_array([
    [0.0, 0.0, 1.0],
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
  ])
  inspect(permutation_matrix.rank(), content="3")
  inspect(
    (permutation_matrix.determinant().abs() - 1.0).abs() < 1.0e-6,
    content="true",
  )
  inspect(permutation_matrix.inverse() is Some(_), content="true")
  let identity_like = permutation_matrix * permutation_matrix.inverse().unwrap()
  for i in 0..<identity_like.row() {
    for j in 0..<identity_like.col() {
      let expected = if i == j { 1.0 } else { 0.0 }
      assert_true((identity_like.get(i, j) - expected).abs() < 1.0e-6)
    }
  }
}

test "reduce_row_elimination_idempotent_on_rref" {
  let m = Matrix::from_2d_array([
    [1.0, 0.0, 0.0, 2.0],
    [0.0, 1.0, 0.0, -1.0],
    [0.0, 0.0, 1.0, 4.0],
  ])
  let reduced = m.reduce_row_elimination()
  for i in 0..<m.row() {
    for j in 0..<m.col() {
      assert_true((reduced.get(i, j) - m.get(i, j)).abs() < 1.0e-6)
    }
  }
}

test "power_method_and_eigen_agree_on_diagonal_matrix" {
  let m = Matrix::from_2d_array([
    [6.0, -2.0],
    [-2.0, 9.0],
  ])
  let power_pair = m.power_method(60)
  inspect(power_pair is Some(_), content="true")
  let (dominant, vec) = power_pair.unwrap()
  inspect((dominant - 10.0).abs() < 1.0e-4, content="true")
  let residual = m.mul_vec(vec).zip_with(vec.map(fn(x) { x * dominant }), fn(a, b) {
    a - b
  })
  let residual_norm = residual.dot(residual)
  assert_true(residual_norm < 1.0e-3)
}

test "power_method/zero_matrix_returns_none" {
  let zero = Matrix::from_2d_array([[0.0, 0.0], [0.0, 0.0]])
  inspect(zero.power_method(10) is None, content="true")
}

test "power_method/complex_rotation_returns_none" {
  let rotation = Matrix::from_2d_array([[0.0, -1.0], [1.0, 0.0]])
  inspect(rotation.power_method(10) is None, content="true")
}

test "panic power_method/non_square" {
  let non_square = Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  ignore(non_square.power_method(10))
}

test "panic trace/non_square" {
  let non_square = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  ignore(non_square.trace())
}

test "panic mean/empty_matrix" {
  let empty = Matrix::new(0, 0, 0.0)
  ignore(empty.mean())
}

test "panic variance/empty_matrix" {
  let empty = Matrix::new(0, 0, 0.0)
  ignore(empty.variance())
}

test "panic std_dev/empty_matrix" {
  let empty = Matrix::new(0, 0, 0.0)
  ignore(empty.std_dev())
}

test "panic pow/non_square" {
  let non_square = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  ignore(non_square.pow(2))
}

test "panic pow/negative_exponent" {
  let square = Matrix::from_2d_array([[1, 2], [3, 4]])
  ignore(square.pow(-1))
}

test "row_rank_column_rank_examples" {
  let wide = Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [2.0, 4.0, 6.0],
  ])
  inspect(wide.rank(), content="1")

  let tall = Matrix::from_2d_array([
    [1.0, 2.0],
    [0.0, 1.0],
    [1.0, 3.0],
  ])
  inspect(tall.rank(), content="2")
}

test "matrix_multiplication_associativity/property" {
  fn as_matrix(input : (Int, Int, Int, Int)) -> Matrix[Int] {
    let (a00, a01, a10, a11) = input
    Matrix::from_2d_array([[a00, a01], [a10, a11]])
  }

  fn prop(input : ((Int, Int, Int, Int), (Int, Int, Int, Int), (Int, Int, Int, Int))) {
    let (a_in, b_in, c_in) = input
    let a = as_matrix(a_in)
    let b = as_matrix(b_in)
    let c = as_matrix(c_in)
    ((a * b) * c).to_array() == (a * (b * c)).to_array()
  }

  @qc.quick_check_fn(prop)
}

test "qr_decomposition_reconstructs_input/property" {
  fn prop(input : ((Int, Int), (Int, Int), (Int, Int))) {
    let ((a00, a01), (a10, a11), (a20, a21)) = input
    let matrix = float_matrix_3x2(a00, a01, a10, a11, a20, a21)
    let (q, r) = qr_decomposition(matrix.copy())
    let identity_2 : Matrix[Double] = identity(2)
    matrices_close(q * r, matrix, 1.0e-4) &&
    matrices_close(q.transpose() * q, identity_2, 1.0e-4)
  }

  @qc.quick_check_fn(prop)
}

test "eigenvalues_match_trace_and_determinant_for_diagonal_3x3/property" {
  fn prop(input : (Int, Int, Int)) {
    let (d0, d1, d2) = input
    let matrix = Matrix::from_2d_array([
      [Double::from_int(d0), 0.0, 0.0],
      [0.0, Double::from_int(d1), 0.0],
      [0.0, 0.0, Double::from_int(d2)],
    ])
    let (eigenvalues, _) = matrix.eigen()
    let sum = eigenvalues[0] + eigenvalues[1] + eigenvalues[2]
    let product = eigenvalues[0] * eigenvalues[1] * eigenvalues[2]
    (sum - matrix.trace()).abs() < 1.0e-4 &&
    (product - matrix.determinant()).abs() < 1.0e-4
  }

  @qc.quick_check_fn(prop)
}

test "eigenvalues_match_trace_and_determinant_for_symmetric_2x2/property" {
  fn prop(input : (Int, Int, Int)) {
    let (a00, a01, a11) = input
    let matrix = float_matrix_2x2(a00, a01, a01, a11)
    let (eigenvalues, eigenvectors) = matrix.eigen()
    let _ = eigenvectors
    ((eigenvalues[0] + eigenvalues[1]) - matrix.trace()).abs() < 1.0e-4 &&
    ((eigenvalues[0] * eigenvalues[1]) - matrix.determinant()).abs() < 1.0e-4
  }

  @qc.quick_check_fn(prop)
}

test "cholesky_reconstructs_spd_matrix/property" {
  fn prop(input : ((Int, Int), (Int, Int))) {
    let ((b00, b01), (b10, b11)) = input
    let basis = float_matrix_2x2(b00, b01, b10, b11)
    let identity_2 : Matrix[Double] = identity(2)
    let spd = basis.transpose() * basis + identity_2
    let chol = spd.cholesky_decomposition()
    guard chol is Some(_) else { false }
    let l = chol.unwrap()
    matrices_close(l * l.transpose(), spd, 1.0e-4) &&
    spd.is_positive_definite()
  }

  @qc.quick_check_fn(prop)
}

test "upper_triangular_inverse_det_rank_align/property" {
  fn prop(input : ((Int, Int, Int), (Int, Int, Int))) {
    let ((d0, d1, d2), (u01, u02, u12)) = input
    let matrix = Matrix::from_2d_array([
      [nonzero_double(d0), Double::from_int(u01), Double::from_int(u02)],
      [0.0, nonzero_double(d1), Double::from_int(u12)],
      [0.0, 0.0, nonzero_double(d2)],
    ])
    let inv = matrix.inverse()
    guard inv is Some(_) else { false }
    let identity_3 : Matrix[Double] = identity(3)
    let expected_det = matrix.get(0, 0) * matrix.get(1, 1) * matrix.get(2, 2)
    matrix.rank() == 3 &&
    (matrix.determinant() - expected_det).abs() < 1.0e-4 &&
    matrices_close(matrix * inv.unwrap(), identity_3, 1.0e-4)
  }

  @qc.quick_check_fn(prop)
}

test "row_swap_flips_determinant_preserves_rank/property" {
  fn prop(input : (Int, Int, Int, Int)) {
    let (a00, a01, a10, a11) = input
    let matrix = float_matrix_2x2(a00, a01, a10, a11)
    let swapped = matrix.copy()
    swapped.swap_rows(0, 1)
    (swapped.determinant() + matrix.determinant()).abs() < 1.0e-4 &&
    swapped.rank() == matrix.rank()
  }

  @qc.quick_check_fn(prop)
}
