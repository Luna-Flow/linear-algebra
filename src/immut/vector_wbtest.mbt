///|
using @qc {quick_check_fn, trait Shrink}

///|
impl[T] Shrink for Vector[T] with shrink(_) -> Iter[Vector[T]] {
  Iter::empty()
}

///|
/// Tests the conversion of a vector to both column and row matrix
/// representations.
///
/// This test verifies that:
///
/// 1. `to_col_matrix()` converts a vector into a column matrix where each
/// element becomes a row in a single column
/// 2. `to_row_matrix()` converts a vector into a row matrix where all elements
/// are arranged in a single row
///
/// The test uses a 3-element vector `[1, 2, 3]` and checks:
///
/// * Column matrix conversion results in a 3×1 matrix with values stacked
///   vertically
/// * Row matrix conversion results in a 1×3 matrix with values arranged
///   horizontally
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
///
/// let col = v.to_col_matrix() // 3×1 matrix: [[1], [2], [3]]
///
/// let row = v.to_row_matrix() // 1×3 matrix: [[1, 2, 3]]
/// ```
///
test "to matrix" {
  let v = Vector::from_array([1, 2, 3])
  let vc = v.to_col_matrix()
  inspect(
    vc,
    content=(
      #||1|
      #||2|
      #||3|
    ),
  )
  let rc = v.to_row_matrix()
  inspect(
    rc,
    content=(
      #||1, 2, 3|
    ),
  )
}

///|
/// Tests the property that converting a vector to an array and back creates an
/// identical vector.
///
/// This test verifies that the round-trip conversion from `Vector[T]` to
/// `Array[T]` using `iter().to_array()` and back to `Vector[T]` using
/// `from_array()` preserves the original vector. This property ensures that the
/// vector's iterator implementation correctly exposes all elements in order,
/// and that `from_array()` correctly reconstructs the vector structure.
///
/// The test uses property-based testing with `quick_check_fn` to verify this
/// identity property holds for randomly generated vectors of integers.
///
test "from . to = identity" {
  fn prop(v : Vector[Int]) {
    v == Vector::from_array(v.iter().to_array())
  }

  quick_check_fn(prop)
}

///|
/// Tests the mathematical property that adding a vector to itself is equivalent
/// to scaling the vector by 2.
///
/// This is a property-based test that verifies the distributive property of
/// vector addition and scalar multiplication. It uses QuickCheck-style testing
/// to automatically generate test cases and validate that for any vector `v`,
/// the equation `v + v = 2 * v` holds true.
///
/// The test demonstrates that vector addition and left scalar multiplication
/// are consistent with basic mathematical expectations, which is fundamental
/// for ensuring the correctness of linear algebra operations.
///
/// Example:
///
/// ```moonbit
/// // This property should hold for any vector
/// let v = Vector::from_array([1, 2, 3])
///
/// let sum = v + v // |2, 4, 6|
///
/// let scaled = v.left_scale(2) // |2, 4, 6|
/// // sum == scaled should be true
/// ```
///
test "a + a = 2 * a" {
  fn prop(v : Vector[Int]) {
    v + v == v.left_scale(2)
  }

  quick_check_fn(prop)
}

///|
/// Tests the commutative property of vector addition.
///
/// This test verifies that vector addition is commutative, meaning that for any
/// two vectors `a` and `b` of the same length, `a + b` equals `b + a`. The test
/// uses property-based testing to generate random vectors and verify this
/// mathematical property holds across many test cases.
///
/// The test implements a property function that checks the commutative law for
/// two vectors, and a wrapper function that ensures the vectors have equal
/// lengths before applying the property test. This is necessary because vector
/// addition is only defined for vectors of the same dimension.
///
/// Example:
///
/// ```moonbit
/// // The property being tested:
/// let v1 = Vector::from_array([1, 2, 3])
///
/// let v2 = Vector::from_array([4, 5, 6])
/// // v1 + v2 should equal v2 + v1
/// // |5, 7, 9| == |5, 7, 9| ✓
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
/// Tests the associativity property of vector element-wise multiplication.
///
/// This test verifies that for any three vectors of the same length, the
/// multiplication operation `*` is associative, meaning `(a * b) * c` equals `a
/// * (b * c)`. The test uses property-based testing to generate random vectors
/// and validate this mathematical property across many test cases.
///
/// The test implementation includes a guard condition to ensure all three
/// vectors have the same length, as element-wise multiplication is only defined
/// for vectors of equal dimensions. When vectors have different lengths, the
/// test case is considered trivial and passes automatically.
///
/// This property is fundamental for vector arithmetic and ensures that the
/// `Mul` implementation for `Vector[T]` behaves correctly according to
/// mathematical expectations.
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
/// Verifies that multiplying a scaled matrix by a vector produces the same
/// result as element-wise multiplication of the vectors.
///
/// This property-based test checks the mathematical equivalence: S\_v \* p = v
/// ⊙ p, where S\_v is a scaled (diagonal) matrix constructed from vector v, p
/// is another vector, and ⊙ represents element-wise multiplication.
///
/// The test uses property-based testing with `quick_check_fn` to verify this
/// relationship holds across many randomly generated vector pairs of equal
/// length. This validates the correctness of the `scaled_matrix` implementation
/// and ensures it behaves as expected when used in matrix-vector
/// multiplication.
///
/// The property being tested is fundamental in linear algebra, where a diagonal
/// matrix with elements from vector v, when multiplied by another vector p,
/// should produce the same result as element-wise multiplication of v and p.
///
test "S_v * p = v * p" {
  fn prop(v : Vector[Int], p : Vector[Int]) {
    let m = v.scaled_matrix()
    m * p.to_col_matrix() == (v * p).to_col_matrix()
  }

  fn check(x : (Vector[Int], Vector[Int])) {
    let (a, b) = x
    guard a.length() == b.length() else { true }
    prop(a, b)
  }

  quick_check_fn(check)
}

///|
/// Tests comprehensive vector operations including arithmetic, scaling, matrix
/// conversion, and tensor operations.
///
/// This test verifies the correctness of various vector operations by creating
/// two test vectors and checking their behavior under different operations:
///
/// 1. **Vector Addition**: Tests element-wise addition of vectors `[1,2,3] +
/// [4,5,6] = [5,7,9]`
/// 2. **Vector Multiplication**: Tests element-wise multiplication of vectors
/// `[1,2,3] * [4,5,6] = [4,10,18]`
/// 3. **Left Scaling**: Tests scalar multiplication from the left `10 * [1,2,3]
/// = [10,20,30]`
/// 4. **Right Scaling**: Tests scalar multiplication from the right `[4,5,6] *
/// 10 = [40,50,60]`
/// 5. **Scaled Matrix**: Tests conversion of vector `[1,2,3]` to diagonal
/// matrix with elements on diagonal
/// 6. **Tensor Product**: Tests outer product of vectors `[1,2,3] ⊗ [4,5,6]`
/// resulting in a 3×3 matrix
/// 7. **Element Setting**: Tests immutable vector element modification
/// `[4,5,6]` with index 1 set to 10
///
/// Each operation is verified using the `inspect` function to ensure the output
/// matches the expected mathematical results.
///
test {
  let v1 = Vector::from_array([1, 2, 3])
  let v2 = Vector::from_array([4, 5, 6])
  inspect(v1 + v2, content="|5, 7, 9|")
  inspect(v1 * v2, content="|4, 10, 18|")
  inspect(v1.left_scale(10), content="|10, 20, 30|")
  inspect(v2.right_scale(10), content="|40, 50, 60|")
  inspect(
    v1.scaled_matrix(),
    content=(
      #||1, 0, 0|
      #||0, 2, 0|
      #||0, 0, 3|
    ),
  )
  inspect(
    v1.tensor_product(v2),
    content=(
      #||4, 5, 6|
      #||8, 10, 12|
      #||12, 15, 18|
    ),
  )
  inspect(v2.set(1, 10), content="|4, 10, 6|")
}

///|
test "make" {
  let v = Vector::make(3, 42)
  inspect(v, content="|42, 42, 42|")
}

///|
test "neg" {
  let v = Vector::from_array([1, 2, -3])
  inspect(-v, content="|-1, -2, 3|")
}

///|
test "add_constant" {
  let v = Vector::from_array([1, 2, 3])
  inspect(v.add_constant(5), content="|6, 7, 8|")
}

///|
test "lin_comb" {
  let v1 = Vector::from_array([1, 2, 3])
  let v2 = Vector::from_array([4, 5, 6])
  let result = lin_comb(2, v1, 3, v2)
  inspect(result, content="|14, 19, 24|")
}
