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
///   inspect(m[0][1], content="3")  // Read element at row 0, column 1
///   m[0][1] = 4                    // Modify element at row 0, column 1
///   inspect(m[0][1], content="4")  // Verify the modification
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
test "rank of matrix" {
  let m1 : Matrix[Float] = Matrix::from_2d_array([[1, 2], [3, 4]]).from_nat_matrix()
  let m2 : Matrix[Double] = Matrix::from_2d_array([[1, 2], [2, 4]]).from_nat_matrix()
  let m3 : Matrix[Float] = Matrix::from_2d_array([[0, 0], [0, 0]]).from_nat_matrix()
  let m4 : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ]).from_nat_matrix()
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
  let m_float : Matrix[Float] = Matrix::from_2d_array([[1, 2], [3, 4]]).from_nat_matrix()
  let trace_float = m_float.trace()
  inspect(trace_float, content="5")

  // Test with Double type  
  let m_double : Matrix[Double] = Matrix::from_2d_array([[2, 1], [1, 3]]).from_nat_matrix()
  let trace_double = m_double.trace()
  inspect(trace_double, content="5")
}

///|
/// Tests the row and column iterator functionality.
test "row and column iterators" {
  let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])

  // Test row iterator
  let row1_elements = m.iter_row(1).collect()
  inspect(row1_elements, content="[4, 5, 6]")

  // Test column iterator
  let col1_elements = m.iter_col(1).collect()
  inspect(col1_elements, content="[2, 5]")
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
  inspect(row0_doubled, content="[2, 4, 6]")

  // Filter even elements in column 1
  let col1_evens = m.iter_col(1).filter(fn(x) { x % 2 == 0 }).collect()
  inspect(col1_evens, content="[2]")
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
  let (dom_val, _) = m1.power_method(100)
  inspect((dom_val - 10.0).abs() < Tolerance::tolerance(), content="true")

  // Test 2x2 analytical solution
  let vals_2x2 = m1.eigen_2x2()
  let v3_ok = (vals_2x2[0] - 5.0).abs() < Tolerance::tolerance() &&
    (vals_2x2[1] - 10.0).abs() < Tolerance::tolerance()
  let v4_ok = (vals_2x2[0] - 10.0).abs() < Tolerance::tolerance() &&
    (vals_2x2[1] - 5.0).abs() < Tolerance::tolerance()
  inspect(v3_ok || v4_ok, content="true")
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
  let m_v1 = matrix_vector_multiply(m, v1)
  let lambda1_v1 = v1.map(x => x * lambda1)
  inspect(
    vectors_are_close(m_v1, lambda1_v1, Tolerance::tolerance()),
    content="true",
    // "First eigenvector check (A*v1 == λ1*v1)"
  )

  // Verify for the second eigenvector
  let v2 = eigenvecs.col_to_vector(1)
  let lambda2 = eigenvals[1]
  let m_v2 = matrix_vector_multiply(m, v2)
  let lambda2_v2 = v2.map(x => x * lambda2)
  inspect(
    vectors_are_close(m_v2, lambda2_v2, Tolerance::tolerance()),
    content="true",
    // "Second eigenvector check (A*v2 == λ2*v2)"
  )
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
  inspect(inv1.is_empty(), content="false")

  // Test 3x3 identity matrix (should return itself)
  let identity = Matrix::from_2d_array([
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [0.0, 0.0, 1.0],
  ])
  let inv_identity = identity.inverse()
  inspect(inv_identity.is_empty(), content="false")

  // Test singular (non-invertible) matrix
  let singular = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let inv_singular = singular.inverse()
  inspect(inv_singular.is_empty(), content="true")
}
///|
test "Matrix::inverse/edge_cases" {
  // Test 0x0 matrix
  let empty_matrix = Matrix::new(0, 0, 0.0)
  let inv_empty = empty_matrix.inverse()
  inspect(inv_empty.is_empty(), content="false")

  // Test 1x1 invertible matrix
  let one_by_one = Matrix::from_2d_array([[5.0]])
  let inv_one = one_by_one.inverse()
  inspect(inv_one.is_empty(), content="false")

  // Test 1x1 singular matrix (zero)
  let zero_matrix = Matrix::from_2d_array([[0.0]])
  let inv_zero = zero_matrix.inverse()
  inspect(inv_zero.is_empty(), content="true")
}
///|
test "panic Matrix::inverse/non_square" {
  let non_square = Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  ignore(non_square.inverse())
}