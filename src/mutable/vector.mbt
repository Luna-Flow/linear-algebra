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
/// inspect(v1, content="|0, 0, 0|")
/// inspect(v2, content="|0, 1, 2|")
/// inspect(v3, content="|1, 2, 3|")
///
/// // Vector operations
/// let sum = v2 + v3
/// let scaled = v2.left_scale(2.0)
///
/// inspect(sum.to_string(), content="|1, 3, 5|")
/// inspect(scaled.to_string(), content="|0, 2, 4|")
/// ```
pub struct Vector[A](Array[A])

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
pub impl[T : Arbitrary] Arbitrary for Vector[T] with arbitrary(size, rng) {
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
pub impl[T : Eq] Eq for Vector[T] with equal(self, other) {
  self.0 == other.0
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
  "|\{self.0.map(T::to_string).join(sep)}|"
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
  array_zip_with(self.0, other.0, f)
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
/// inspect(col_matrix, content=(
///   #||1|
///   #||2|
///   #||3|
///   )
/// )
/// ```
///
pub fn[T] Vector::to_col_matrix(self : Vector[T]) -> Matrix[T] {
  Matrix::from_array(self.0.length(), 1, self.0.copy())
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
/// inspect(row_matrix, content=(
///   #||1, 2, 3, 4|
///   )
/// )
/// ```
///
pub fn[T] Vector::to_row_matrix(self : Vector[T]) -> Matrix[T] {
  { data: self.0, row: 1, col: self.length() }
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
  self.0.length()
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
/// inspect(squares, content="|0, 1, 4, 9, 16|")
/// // Create a vector [2, 4, 6, 8] (even numbers starting from 2)
/// let evens = @mutable.Vector::makei(4, fn(i) { 2 * (i + 1) })
/// inspect(evens, content="|2, 4, 6, 8|")
/// ```
///
pub fn[A] Vector::makei(n : Int, f : (Int) -> A) -> Vector[A] {
  Vector(Array::makei(n, f))
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
  Vector(Array::make(n, elem))
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
  Vector(self.0.copy())
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
  // Direct indexed access to the underlying 1D array.
  self.0[index]
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
  // Direct indexed update to the underlying 1D array.
  self.0[index] = value
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
  self.0.map(f)
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
/// v.map_in_place(fn(x) { x * 2 })
/// inspect(v, content="|2, 4, 6, 8|")
/// ```
///
#alias(map_inplace, deprecated)
pub fn[A] Vector::map_in_place(self : Vector[A], f : (A) -> A) -> Unit {
  self.0.map_in_place(f)
}

///|
/// Scales the vector by multiplying each component by the given scalar from the
/// left.
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
/// inspect(scaled, content="|2, 4, 6|")
/// // scaled is now equivalent to Vector::from_array([2, 4, 6])
/// ```
///
pub fn[A : Mul] Vector::left_scale(self : Vector[A], scalar : A) -> Vector[A] {
  self.map(x => scalar * x)
}

///|
/// Multiplies each element of a vector by a scalar value from the right.
///
/// Parameters:
///
/// * `self` : The vector to be scaled.
/// * `scalar` : The scalar value to multiply each vector element by.
///
/// Returns a new vector where each element is the result of multiplying the
/// corresponding element in the input vector by the scalar.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let scaled = v.right_scale(2)
/// inspect(scaled, content="|2, 4, 6|")
/// ```
///
pub fn[A : Mul] Vector::right_scale(self : Vector[A], scalar : A) -> Vector[A] {
  self.map(x => x * scalar)
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
/// v.left_scale_in_place(2)
/// inspect(v, content="|2, 4, 6|")
/// ```
///
#alias(left_scale_inplace, deprecated)
pub fn[A : Mul] Vector::left_scale_in_place(
  self : Vector[A],
  scalar : A,
) -> Unit {
  self.map_in_place(x => scalar * x)
}

///|
/// Multiplies each element of the vector by a scalar value in-place, modifying
/// the original vector.
///
/// Parameters:
///
/// * `self` : The vector to be modified.
/// * `scalar` : The scalar value to multiply each vector element by.
///
/// Example:
///
/// ```moonbit
/// let v = @mutable.Vector::from_array([1, 2, 3])
/// v.right_scale_in_place(2)
/// // v is now [2, 4, 6]
/// ```
///
#alias(right_scale_inplace, deprecated)
pub fn[A : Mul] Vector::right_scale_in_place(
  self : Vector[A],
  scalar : A,
) -> Unit {
  self.map_in_place(x => x * scalar)
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
pub fn[A] Vector::from_array(a : Array[A]) -> Vector[A] {
  Vector(a)
}

///|
/// Returns an iterator over the elements of the vector.
///
/// Parameters:
///
/// * `self` : The vector to iterate over.
///
/// Returns an `Iter[T]` that yields each element of the vector in order.
pub fn[T] Vector::iter(self : Vector[T]) -> Iter[T] {
  self.0.iter()
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
pub impl[T : Add] Add for Vector[T] with add(
  self : Vector[T],
  other : Vector[T],
) -> Vector[T] {
  self.zip_with(other, T::add)
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
pub impl[T : Mul] Mul for Vector[T] with mul(
  self : Vector[T],
  other : Vector[T],
) -> Vector[T] {
  self.zip_with(other, T::mul)
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
pub impl[T : Neg] Neg for Vector[T] with neg(self : Vector[T]) -> Vector[T] {
  self.map(T::neg)
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
pub fn[T : MulMonoid + Add + Neg] Vector::lerp(
  self : Vector[T],
  other : Vector[T],
  alpha : T,
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
/// Computes the dot product of two vectors.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector.
///
/// Returns the dot product of the two vectors.
/// 
/// Panics:
/// * If the two vectors have different lengths.
pub fn[T : AddMonoid + Mul] Vector::dot(
  self : Vector[T],
  other : Vector[T],
) -> T {
  let len = self.0.length()
  if len != other.0.length() {
    abort("Vector length mismatch for dot product")
  }
  let mut sum = T::zero()
  for i = 0; i < len; i = i + 1 {
    // Equivalent to sum += self[i] * other[i]
    sum = sum + self.0[i] * other.0[i]
  }
  sum
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
pub fn[T : Zero] Vector::scaled_matrix(self : Vector[T]) -> Matrix[T] {
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
pub fn[T : Mul] Vector::tensor_product(
  self : Vector[T],
  other : Vector[T],
) -> Matrix[T] {
  let n = self.0.length()
  let m = other.0.length()
  if n == 0 || m == 0 {
    return Matrix::from_array(n, m, [])
  }
  // Optimize by avoiding division and modulo operations in the innermost loop.
  // Uses manual offset tracking for contiguous memory access.
  let data = Array::make(n * m, self.0[0] * other.0[0])
  for i = 0; i < n; i = i + 1 {
    let row_offset = i * m // result[i][...]
    let val_i = self.0[i] // self[i]
    for j = 0; j < m; j = j + 1 {
      // Equivalent to result[i][j] = self[i] * other[j]
      data[row_offset + j] = val_i * other.0[j]
    }
  }
  Matrix::from_array(n, m, data)
}

///|
pub fn[T : Mul + Add + Zero] Vector::lin_comb(
  weights : Array[T],
  vectors : Array[Vector[T]],
) -> Vector[T] {
  guard weights.length() > 0 else { abort("weights is empty") }
  let len = vectors[0].0.length()
  // Single-pass linear combination to avoid multiple intermediate vector allocations.
  let res_data = Array::make(len, T::zero())
  for i = 0; i < weights.length(); i = i + 1 {
    let w = weights[i]
    let v_data = vectors[i].0
    for j = 0; j < len; j = j + 1 {
      // res[j] += weights[i] * vectors[i][j]
      res_data[j] = res_data[j] + w * v_data[j]
    }
  }
  Vector(res_data)
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
