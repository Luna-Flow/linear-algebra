///|
using @qc {quick_check_fn, trait Shrink}

///|
impl[T] Shrink for Vector[T] with shrink(_) -> Iter[Vector[T]] {
  Iter::empty()
}

///|
/// Tests the property that adding a vector to itself is equivalent to scaling
/// it by 2.
///
/// This is a property-based test that verifies the mathematical identity: for
/// any vector `v`, `v + v = 2 * v`. The test uses QuickCheck to generate random
/// vectors and validate that vector addition is consistent with scalar
/// multiplication by 2.
///
/// Example:
///
/// ```moonbit
/// // The property being tested:
/// let v = Vector::from_array([1, 2, 3])
///
/// let sum = v + v
///
/// let scaled = v.left_scale(2)
/// // sum should equal scaled: [2, 4, 6]
/// ```
///
test "a + a = 2 * a" {
  fn prop(v : Vector[Int]) {
    v + v == v.left_scale(2)
  }

  quick_check_fn(prop)
}

///|
/// Tests the commutative property of vector addition using property-based
/// testing.
///
/// This test verifies that vector addition is commutative by checking that `a +
/// b` equals `b + a` for randomly generated pairs of vectors of the same
/// length. The test uses QuickCheck-style property-based testing to
/// automatically generate test cases and validate the mathematical property
/// across a range of inputs.
///
/// The test includes a guard condition to ensure that only vectors of equal
/// length are compared, as vector addition is only defined for vectors of the
/// same dimension. When vectors have different lengths, the property is
/// considered trivially true and the test passes.
///
/// Example:
///
/// ```moonbit
/// // This property should hold for any two vectors of the same length
/// let v1 = Vector::from_array([1, 2, 3])
///
/// let v2 = Vector::from_array([4, 5, 6])
/// // v1 + v2 should equal v2 + v1: [5, 7, 9]
/// ```
///
test "a + b = b + a" {
  fn prop(a : Vector[Int], b) {
    a + b == b + a
  }

  fn check(x : (Vector[Int], Vector[Int])) {
    let (a, b) = x
    guard a.length() == b.length() else { true }
    prop(a, b)
  }

  quick_check_fn(check)
}

///|
/// Tests the associativity property of element-wise vector multiplication.
///
/// This test verifies that for vectors `a`, `b`, and `c` of equal length, the
/// element-wise multiplication operation satisfies the associative property:
/// `(a * b) * c = a * (b * c)`.
///
/// The test uses property-based testing with randomly generated vectors of
/// integers. It ensures that all three vectors have the same length before
/// applying the associativity check, as element-wise operations require vectors
/// of matching dimensions.
///
/// Example:
///
/// ```moonbit
/// // For vectors [1, 2] * [3, 4] * [5, 6]
/// // Left association: ([1*3, 2*4]) * [5, 6] = [3, 8] * [5, 6] = [15, 48]  
/// // Right association: [1, 2] * ([3*4, 4*6]) = [1, 2] * [15, 24] = [15, 48]
/// // Both results are equal, confirming associativity
/// ```
///
test "a * b * c = a * (b * c)" {
  fn prop(a : Vector[Int], b, c) {
    a * b * c == a * (b * c)
  }

  fn check(x : (Vector[Int], Vector[Int], Vector[Int])) {
    let (a, b, c) = x
    guard a.length() == b.length() && b.length() == c.length() else { true }
    prop(a, b, c)
  }

  quick_check_fn(check)
}

///|
/// Tests the mathematical property that multiplying a scaled diagonal matrix by
/// a vector is equivalent to element-wise multiplication of the original vector
/// with the input vector.
///
/// This test verifies that for any vector `v` and vector `p` of the same
/// length, the equation `S_v * p = v * p` holds, where `S_v` is the scaled
/// diagonal matrix constructed from vector `v`. The scaled diagonal matrix has
/// the elements of `v` on its diagonal and zeros elsewhere. When this matrix is
/// multiplied by column vector `p`, it should produce the same result as
/// element-wise multiplication of vectors `v` and `p`.
///
/// The test uses property-based testing to verify this mathematical
/// relationship across randomly generated vectors of integers. It ensures that
/// vectors have the same length before testing the property, as matrix-vector
/// multiplication and element-wise vector multiplication are only defined for
/// vectors of equal dimensions.
///
/// This property is fundamental in linear algebra and demonstrates the
/// relationship between diagonal matrices and element-wise operations on
/// vectors.
///
test "S_v * p = v * p" {
  fn prop(v : Vector[Int], p : Vector[Int]) {
    let m = v.scaled_matrix()
    m * p.to_col_matrix() == (v * p).to_col_matrix()
  }

  fn check(x : (Vector[Int], Vector[Int])) {
    let (v, p) = x
    guard v.length() == p.length() else { true }
    prop(v, p)
  }

  quick_check_fn(check)
}

///|
test "iter" {
  let v = Vector::from_array([1, 2, 3])
  let arr = v.iter().to_array()
  inspect(arr, content="[1, 2, 3]")
}

///|
test "vector_creation_and_access" {
  let v1 = Vector::make(3, 10)
  inspect(v1.length(), content="3")
  inspect(v1[0], content="10")
  inspect(v1[2], content="10")
  let v2 = Vector::makei(3, fn(i) { i * 2 })
  inspect(v2[0], content="0")
  inspect(v2[1], content="2")
  inspect(v2[2], content="4")
  v2[1] = 99
  inspect(v2[1], content="99")
  let v3 = v2.copy()
  v3[0] = 100
  inspect(v2[0], content="0") // Original unchanged
  inspect(v3[0], content="100") // Copy changed
}

///|
test "vector_formatting" {
  let v = Vector::from_array([1, 2, 3])
  inspect(v.to_string(), content="|1, 2, 3|")
}

///|
test "vector_mapping" {
  let v = Vector::from_array([1, 2, 3])
  let v2 = v.map(fn(x) { x * 2 })
  inspect(v2, content="|2, 4, 6|")
  let v3 = Vector::from_array([1, 2, 3])
  v3.map_inplace(fn(x) { x + 1 })
  inspect(v3, content="|2, 3, 4|")
}

///|
test "vector_scaling" {
  let v = Vector::from_array([1, 2, 3])
  inspect(v.left_scale(2), content="|2, 4, 6|")
  inspect(v.right_scale(2), content="|2, 4, 6|")
  let v2 = Vector::from_array([1, 2, 3])
  v2.left_scale_inplace(2)
  inspect(v2, content="|2, 4, 6|")
  let v3 = Vector::from_array([1, 2, 3])
  v3.right_scale_inplace(2)
  inspect(v3, content="|2, 4, 6|")
}

///|
test "vector_matrix_conversion" {
  let v = Vector::from_array([1, 2, 3])
  let row_m = v.to_row_matrix()
  inspect(row_m.row(), content="1")
  inspect(row_m.col(), content="3")
  inspect(row_m[0][0], content="1")
  let col_m = v.to_col_matrix()
  inspect(col_m.row(), content="3")
  inspect(col_m.col(), content="1")
  inspect(col_m[0][0], content="1")
}

///|
test "vector_advanced_math" {
  // lerp
  let v1 = Vector::from_array([0.0, 0.0])
  let v2 = Vector::from_array([10.0, 20.0])
  inspect(v1.lerp(v2, 0.5), content="|5, 10|")

  // tensor_product
  let t1 = Vector::from_array([1, 2])
  let t2 = Vector::from_array([3, 4, 5])
  let tp = t1.tensor_product(t2)
  inspect(
    tp,
    content=(
      #||3, 4, 5|
      #||6, 8, 10|
    ),
  )

  // add_constant
  let ac = Vector::from_array([1, 2, 3])
  inspect(ac.add_constant(10), content="|11, 12, 13|")

  // lin_comb
  let lc1 = Vector::from_array([1, 2])
  let lc2 = Vector::from_array([3, 4])
  // 2 * [1, 2] + 3 * [3, 4] = [2, 4] + [9, 12] = [11, 16]
  inspect(lin_comb(2, lc1, 3, lc2), content="|11, 16|")
}

///|
test "vector_negation" {
  let v = Vector::from_array([1, -2, 3])
  inspect(-v, content="|-1, 2, -3|")
}

///|
test "vector_empty_edge_cases" {
  let v = Vector::make(0, 0.0)
  inspect(v.length(), content="0")
  inspect(v.to_string(), content="||")
  inspect(v.copy().length(), content="0")
  inspect(v.map(fn(x) { x + 1.0 }).length(), content="0")
}

///|
test "vector_single_element" {
  let v = Vector::from_array([34.0])
  inspect(v.length(), content="1")
  inspect(v[0], content="34")
  inspect(v.left_scale(2.0)[0], content="68")
}

///|
test "vector_scaling_direction" {
  // Use a string-like operation or just check math.
  // Since Int/Double are commutative, we just check they work.
  let v = Vector::from_array([1, 2, 3])
  inspect(v.left_scale(10), content="|10, 20, 30|")
  inspect(v.right_scale(10), content="|10, 20, 30|")
  let v_inplace = Vector::from_array([1, 2, 3])
  v_inplace.left_scale_inplace(10)
  inspect(v_inplace, content="|10, 20, 30|")
  v_inplace.right_scale_inplace(2)
  inspect(v_inplace, content="|20, 40, 60|")
}

///|
test "vector_zip_with_regression" {
  let v1 = Vector::from_array([1, 2, 3])
  let v2 = Vector::from_array([10, 20, 30])
  let result = v1.zip_with(v2, fn(a, b) { a + b })
  inspect(result, content="|11, 22, 33|")
}

///|
test "vector_dot_product" {
  let v1 = Vector::from_array([1, 2, 3])
  let v2 = Vector::from_array([4, 5, 6])
  // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
  inspect(v1.dot(v2), content="32")
  let v_zero_len : Vector[Int] = Vector::make(0, 0)
  inspect(v_zero_len.dot(v_zero_len), content="0")
}
