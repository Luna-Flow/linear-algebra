///|
/// A one-dimensional array-like container for mathematical vector operations.
///
/// Example:
///
/// ```moonbit
/// let v1 = @mutable.Vector::make(3, 0.0)
/// let v2 = @mutable.Vector::makei(3, fn(i) { i.to_double() })
/// let v3 = @mutable.Vector::from_array([1.0, 2.0, 3.0])
///
/// // Access elements
/// inspect(v2[0], content="0")
/// inspect(v2[1], content="1")
///
/// // Vector operations
/// let sum = v2 + v3
/// let scaled = v2.left_scale(2.0)
/// ```
///
type Vector[A] Array[A]

///|
/// Implements the `Arbitrary` trait for `Vector[T]`, enabling the generation of
/// random vectors for property-based testing.
///
/// Parameters:
///
/// * `size` : The length of the vector to generate.
/// * `rng` : The random number generator to use for creating random elements.
///
/// Returns a randomly generated vector of the specified size, where each
/// element is generated using the `Arbitrary` instance of type `T`.
impl[T : Arbitrary] Arbitrary for Vector[T] with arbitrary(size, rng) {
  Vector::makei(size, i => T::arbitrary(i, rng))
}

///|
/// Checks if two vectors are equal by comparing their underlying arrays
/// element-wise.
///
/// Parameters:
///
/// * `self` : The first vector to compare.
/// * `other` : The second vector to compare.
///
/// Returns `true` if both vectors have the same length and all corresponding
/// elements are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2, 3])
/// let v2 = Vector::from_array([1, 2, 3])
/// let v3 = Vector::from_array([1, 2, 4])
/// inspect(v1, content=v2.to_string())
/// assert_eq(v1.to_string() != v3.to_string(), true)
/// ```
///
impl[T : Eq] Eq for Vector[T] with op_equal(self, other) {
  self.inner() == other.inner()
}

///|
/// Converts a vector to its string representation with elements separated by
/// commas and enclosed in vertical bars.
///
/// Parameters:
///
/// * `self` : The vector to convert to a string.
///
/// Returns a string representation of the vector in the format `|element1,
/// element2, ..., elementN|`.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3])
/// inspect(v.to_string(), content="|1, 2, 3|")
/// ```
///
pub impl[T : Show] Show for Vector[T] with to_string(self) {
  let sep = ", "
  "|\{self.inner().map(T::to_string).join(sep)}|"
}

///|
/// Outputs the vector to a logger for debugging and display purposes.
///
/// Parameters:
///
/// * `self` : The vector to be output.
/// * `logger` : The logger object that receives the string representation.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3])
/// inspect(v, content="|1, 2, 3|")
/// ```
///
pub impl[T : Show] Show for Vector[T] with output(self, l) {
  l.write_string(self.to_string())
}

///|
/// Combines corresponding elements of two arrays using a specified function to
/// produce a new array.
///
/// Parameters:
///
/// * `first_array` : Array\[A] - The first input array.
/// * `second_array` : Array\[B] - The second input array.
/// * `combine_function` : (A, B) -> C - The function to apply to each pair of
///   corresponding elements.
///
/// Returns an Array\[C] containing the results of applying the function to each
/// pair of corresponding elements.
///
/// Panics if the two input arrays have different lengths.
fn[A, B, C] array_zip_with(
  a1 : Array[A],
  a2 : Array[B],
  f : (A, B) -> C,
) -> Array[C] {
  let n = a1.length()
  guard n == a2.length()
  let result = Array::makei(n, i => f(a1[i], a2[i]))
  result
}

///|
/// Combines two vectors element-wise using a provided function to produce a new
/// vector.
///
/// Parameters:
///
/// * `self` : The first input vector of type `A`.
/// * `other` : The second input vector of type `U`.
/// * `f` : A function that takes an element from the first vector and an
///   element from the second vector, and returns a new element of type `V`.
///
/// Returns a new vector where each element is the result of applying the
/// function `f` to the corresponding elements from both input vectors.
///
/// Panics if the two input vectors have different lengths.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2, 3])
/// let v2 = Vector::from_array([4, 5, 6])
/// let result = v1.zip_with(v2, fn(a, b) { a + b })
/// inspect(result, content="|5, 7, 9|")
/// ```
///
pub fn[A, U, V] Vector::zip_with(
  self : Vector[A],
  other : Vector[U],
  f : (A, U) -> V,
) -> Vector[V] {
  array_zip_with(self.inner(), other.inner(), f)
}

///|
/// Converts a vector to a column matrix representation.
///
/// Parameters:
///
/// * `self` : The vector to convert to a column matrix.
///
/// Returns a matrix with the same number of rows as the vector length and
/// exactly one column, where each element of the vector becomes a row in the
/// resulting matrix.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let col_matrix = v.to_col_matrix()
/// // Results in a 3x1 matrix:
/// // |1|
/// // |2|
/// // |3|
/// ```
///
pub fn[T] to_col_matrix(self : Vector[T]) -> Matrix[T] {
  Matrix::make(self.length(), 1, fn(i, _) { self[i] })
}

///|
/// Converts a vector to a row matrix with a single row.
///
/// Parameters:
///
/// * `self` : The vector to convert to a row matrix.
///
/// Returns a matrix with one row and columns equal to the length of the input
/// vector, where the single row contains all elements of the vector in order.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3, 4])
/// let row_matrix = v.to_row_matrix()
/// // Creates a 1x4 matrix: |1 2 3 4|
/// ```
///
pub fn[T] to_row_matrix(self : Vector[T]) -> Matrix[T] {
  { data: self.inner(), row: 1, col: self.length() }
}

///|
/// Returns the number of elements in the vector.
///
/// Parameters:
///
/// * `self` : The vector whose length is to be determined.
///
/// Returns the number of elements in the vector as an `Int`.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::make(5, 42)
/// inspect(v.length(), content="5")
/// ```
///
pub fn[A] Vector::length(self : Vector[A]) -> Int {
  self.inner().length()
}

///|
/// Creates a vector of length `n` by applying the given function to each index.
///
/// Parameters:
///
/// * `n` : The length of the vector to create.
/// * `f` : A function that takes an index and returns the element at that
///   position.
///
/// Returns a new vector where each element at index `i` is the result of
/// calling `f(i)`.
///
/// Examples:
///
/// ```moonbit
/// // Create a vector [0, 1, 4, 9, 16] (squares of indices)
/// let squares = @mutable.Vector::makei(5, fn(i) { i * i })
///
/// // Create a vector [2, 4, 6, 8] (even numbers starting from 2)
/// let evens = @mutable.Vector::makei(4, fn(i) { 2 * (i + 1) })
/// ```
///
pub fn[A] Vector::makei(n : Int, f : (Int) -> A) -> Vector[A] {
  Array::makei(n, f)
}

///|
/// Creates a new vector of the specified length with all elements initialized
/// to the same value.
///
/// Parameters:
///
/// * `n` : The length of the vector to create.
/// * `elem` : The value to initialize all elements with.
///
/// Returns a new vector of length `n` where each element is `elem`.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::make(3, 42)
/// inspect(v, content="|42, 42, 42|")
/// ```
///
pub fn[A] Vector::make(n : Int, elem : A) -> Vector[A] {
  Array::make(n, elem)
}

///|
/// Creates a deep copy of the vector.
///
/// Parameters:
///
/// * `self` : The vector to be copied.
///
/// Returns a new vector containing the same elements as the original vector.
///
/// Example:
///
/// ```moonbit
/// let original = @mutable.Vector::makei(3, fn(i) { i * 2 })
/// let copied = original.copy()
/// original[0] = 100
/// inspect(copied[0], content="0") // copied is independent of original
/// ```
///
pub fn[A] Vector::copy(self : Vector[A]) -> Vector[A] {
  self.inner().copy()
}

///|
/// Retrieves the element at the specified index from the vector.
///
/// Parameters:
///
/// * `self` : The vector to access.
/// * `index` : The zero-based index of the element to retrieve.
///
/// Returns the element at the specified index.
///
/// Panics if the index is out of bounds (less than 0 or greater than or equal
/// to the vector's length).
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3, 4, 5])
/// inspect(v[2], content="3")
/// ```
///
pub fn[A] Vector::op_get(self : Vector[A], index : Int) -> A {
  self.inner()[index]
}

///|
/// Sets the element at the specified index in the vector to the given value.
///
/// Parameters:
///
/// * `self` : The vector to modify.
/// * `index` : The zero-based index of the element to set.
/// * `value` : The new value to assign to the element at the specified index.
///
/// Panics if `index` is out of bounds (negative or greater than or equal to the
/// vector length).
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::make(3, 0)  // Creates [0, 0, 0]
/// v[1] = 42
/// // v is now [0, 42, 0]
/// ```
///
pub fn[A] Vector::op_set(self : Vector[A], index : Int, value : A) -> Unit {
  self.inner()[index] = value
}

///|
/// Transforms each element in the vector using the provided mapping function.
///
/// Parameters:
///
/// * `self` : The vector to transform.
/// * `f` : The mapping function to apply to each element.
///
/// Returns a new vector containing the transformed elements.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3, 4])
/// let doubled = v.map(fn(x) { x * 2 })
/// inspect(doubled.to_string(), content="|2, 4, 6, 8|")
/// ```
///
pub fn[A, B] Vector::map(self : Vector[A], f : (A) -> B) -> Vector[B] {
  self.inner().map(f)
}

///|
/// Applies a function to each element of the vector in place, modifying the
/// original vector.
///
/// Parameters:
///
/// * `self` : The vector to be modified.
/// * `f` : The function to apply to each element. Takes an element of type `A`
///   and returns a new element of type `A`.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3, 4])
/// v.map_inplace(fn(x) { x * 2 })
/// inspect(v, content="|2, 4, 6, 8|")
/// ```
///
pub fn[A] Vector::map_inplace(self : Vector[A], f : (A) -> A) -> Unit {
  self.inner().map_inplace(f)
}

///|
/// Scales the vector by multiplying each component by the given scalar from the
/// right.
///
/// Parameters:
///
/// * `self` : The vector to be scaled.
/// * `scalar` : The scalar value to multiply each component of the vector.
///
/// Returns a new vector where each component is multiplied by the scalar.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let scaled = v.left_scale(2)
/// // scaled is now equivalent to Vector::from_array([2, 4, 6])
/// ```
///
pub fn[A : Mul] Vector::left_scale(self : Vector[A], scalar : A) -> Vector[A] {
  self.map(x => x * scalar)
}

///|
/// Multiplies each element of a vector by a scalar value.
///
/// Parameters:
///
/// * `scalar` : The scalar value to multiply each vector element by.
/// * `self` : The vector to be scaled.
///
/// Returns a new vector where each element is the result of multiplying the
/// corresponding element in the input vector by the scalar.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let scaled = Vector::right_scale(2, v)
/// inspect(scaled, content="|2, 4, 6|")
/// ```
///
pub fn[A : Mul] Vector::right_scale(scalar : A, self : Vector[A]) -> Vector[A] {
  self.map(x => scalar * x)
}

///|
/// Scales the vector in-place by multiplying each element with the given
/// scalar.
///
/// Parameters:
///
/// * `self` : The vector to be scaled in-place.
/// * `scalar` : The scalar value to multiply each element of the vector with.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3])
/// v.left_scale_inplace(2)
/// inspect(v, content="|2, 4, 6|")
/// ```
///
pub fn[A : Mul] Vector::left_scale_inplace(
  self : Vector[A],
  scalar : A,
) -> Unit {
  self.map_inplace(x => x * scalar)
}

///|
/// Multiplies each element of the vector by a scalar value in-place, modifying
/// the original vector.
///
/// Parameters:
///
/// * `scalar` : The scalar value to multiply each vector element by.
/// * `self` : The vector to be modified.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3])
/// @mutable.Vector::right_scale_inplace(2, v)
/// // v is now [2, 4, 6]
/// ```
///
pub fn[A : Mul] Vector::right_scale_inplace(
  scalar : A,
  self : Vector[A],
) -> Unit {
  self.map_inplace(x => scalar * x)
}

///|
/// Converts an array into a vector.
///
/// Parameters:
///
/// * `array` : The array to be converted into a vector.
///
/// Returns a new vector containing the elements from the input array.
///
/// Example:
///
/// ```moonbit
/// let arr = [1, 2, 3, 4, 5]
/// let vec = Vector::from_array(arr)
/// inspect(vec.to_string(), content="|1, 2, 3, 4, 5|")
/// ```
///
pub fn[T] Vector::from_array(a : Array[T]) -> Vector[T] {
  a
}

///|
/// Performs element-wise addition of two vectors.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector to add to the first vector.
///
/// Returns a new vector where each element is the sum of the corresponding
/// elements from the input vectors.
///
/// Example:
///
/// ```moonbit
/// let v1 = @mutable.Vector::from_array([1, 2, 3])
/// let v2 = @mutable.Vector::from_array([4, 5, 6])
/// let result = v1 + v2
/// inspect(result, content="|5, 7, 9|")
/// ```
///
pub impl[T : Add] Add for Vector[T] with op_add(
  self : Vector[T],
  other : Vector[T],
) -> Vector[T] {
  self.zip_with(other, T::op_add)
}

///|
/// Performs element-wise multiplication of two vectors.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector to multiply with.
///
/// Returns a new vector where each element is the product of the corresponding
/// elements from the input vectors.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2, 3])
/// let v2 = Vector::from_array([4, 5, 6])
/// let result = v1 * v2
/// inspect(result, content="|4, 10, 18|")
/// ```
///
pub impl[T : Mul] Mul for Vector[T] with op_mul(
  self : Vector[T],
  other : Vector[T],
) -> Vector[T] {
  self.zip_with(other, T::op_mul)
}

///|
/// Computes the negation of a vector by negating each element.
///
/// Parameters:
///
/// * `self` : The vector to negate.
///
/// Returns a new vector with each element negated.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, -3])
/// inspect(-v, content="|-1, -2, 3|")
/// ```
///
pub impl[T : Neg] Neg for Vector[T] with op_neg(self : Vector[T]) -> Vector[T] {
  self.map(T::op_neg)
}

///|
/// Performs linear interpolation between two vectors.
///
/// Parameters:
///
/// * `self` : The starting vector.
/// * `other` : The ending vector.
/// * `alpha` : The interpolation parameter, where 0 returns `self` and 1
///   returns `other`.
///
/// Returns a new vector that is the linear interpolation between `self` and
/// `other` based on the `alpha` parameter.
///
/// Example:
///
/// ```moonbit
/// let v1: Vector[Double] = Vector::from_array([1, 2, 3])
/// let v2: Vector[Double] = Vector::from_array([4, 5, 6])
/// let result = v1.lerp(v2, 0.5)
/// inspect(result, content="|2.5, 3.5, 4.5|")
/// ```
///
pub fn[T : One + Mul + Add + Neg] lerp(
  self : Vector[T],
  other : Vector[T],
  alpha : T,
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
/// Creates a diagonal matrix where each diagonal element is the corresponding
/// element from the vector.
///
/// Parameters:
///
/// * `self` : The vector whose elements will form the diagonal of the resulting
///   matrix.
///
/// Returns a square matrix of size n×n (where n is the length of the vector)
/// with the vector elements on the main diagonal and zeros elsewhere.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let m = v.scaled_matrix()
/// inspect(m, content=(
/// #||1, 0, 0|
/// #||0, 2, 0|
/// #||0, 0, 3|
/// ))
/// ```
///
pub fn[T : Zero] scaled_matrix(self : Vector[T]) -> Matrix[T] {
  let n = self.length()
  Matrix::make(n, n, fn(i, j) { if i == j { self[i] } else { T::zero() } })
}

///|
/// Computes the tensor product (outer product) of two vectors.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector.
///
/// Returns a matrix where element at position (i, j) is the product of the i-th
/// element of the first vector and the j-th element of the second vector.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2])
/// let v2 = Vector::from_array([3, 4, 5])
/// let result = v1.tensor_product(v2)
/// inspect(result.to_string(), content=(
/// #||3, 4, 5|
/// #||6, 8, 10|
/// ))
/// ```
///
pub fn[T : Mul] tensor_product(
  self : Vector[T],
  other : Vector[T],
) -> Matrix[T] {
  let n = self.length()
  let m = other.length()
  Matrix::make(n, m, fn(i, j) { self[i] * other[j] })
}

///|
/// Adds a constant value to each element of the vector.
///
/// Parameters:
///
/// * `self` : The vector to which the constant will be added.
/// * `cst` : The constant value to add to each element.
///
/// Returns a new vector with the constant added to each element of the original
/// vector.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let result = v.add_constant(5)
/// inspect(result.to_string(), content="|6, 7, 8|")
/// ```
///
pub fn[T : Add] Vector::add_constant(self : Vector[T], cst : T) -> Vector[T] {
  self.map(fn(x) { x + cst })
}

///|
/// Computes a linear combination of two vectors.
///
/// Parameters:
///
/// * `scalar_a` : The scalar coefficient for the first vector.
/// * `vector_a` : The first vector in the linear combination.
/// * `scalar_b` : The scalar coefficient for the second vector.
/// * `vector_b` : The second vector in the linear combination.
///
/// Returns a new vector that is the linear combination `scalar_a * vector_a +
/// scalar_b * vector_b`.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2, 3])
/// let v2 = Vector::from_array([4, 5, 6])
/// let result = lin_comb(2, v1, 3, v2)
/// inspect(result, content="|14, 19, 24|")
/// ```
///
pub fn[T : Add + Mul] lin_comb(
  scalar_a : T,
  self : Vector[T],
  scalar_b : T,
  other : Vector[T],
) -> Vector[T] {
  self.left_scale(scalar_a) + other.left_scale(scalar_b)
}
