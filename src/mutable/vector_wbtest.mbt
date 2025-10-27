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
/// let sum = v + v
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
