///|
/// Immutable vector of elements of type `T`.
///
/// Example:
///
/// ```moonbit
/// let v = @immut.Vector::from_array([1, 2, 3])
/// inspect(v.length(), content="3")
/// inspect(v[0], content="1")
/// inspect(v[1], content="2")
/// inspect(v[2], content="3")
///
/// let v2 = v.map(fn(x) { x * 2 })
/// inspect(v2, content="|2, 4, 6|")
///
/// let v3 = v + v2
/// inspect(v3, content="|3, 6, 9|")
/// ```
///
struct Vector[T] {
  data : IArray[T]
} derive(Eq)

///|
/// Generates an arbitrary `Vector[T]` for property-based testing.
///
/// Parameters:
///
/// * `size` : The size of the vector to generate.
/// * `rng` : The random number generator to use for generating arbitrary
///   elements.
///
/// Returns an arbitrary `Vector[T]` where each element is generated using the
/// `Arbitrary` implementation of type `T`.
pub impl[T : Arbitrary] Arbitrary for Vector[T] with arbitrary(size, rng) {
  Vector::{ data: @immut/array.makei(size, i => T::arbitrary(i, rng)) }
}

///|
/// Maps a function over each element of the vector, creating a new vector with
/// the transformed elements.
///
/// Parameters:
///
/// * `self` : The vector to map over.
/// * `f` : The function to apply to each element, taking an element of type `T`
///   and returning a value of type `U`.
///
/// Returns a new vector where each element is the result of applying the
/// function `f` to the corresponding element in the input vector.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let doubled = v.map(fn(x) { x * 2 })
/// inspect(doubled, content="|2, 4, 6|")
/// ```
///
pub fn[T, U] Vector::map(self : Vector[T], f : (T) -> U) -> Vector[U] {
  Vector::{ data: self.data.map(f) }
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
/// inspect(result, content="|6, 7, 8|")
/// ```
///
pub fn[T : Add] Vector::add_constant(self : Vector[T], cst : T) -> Vector[T] {
  self.map(fn(x) { x + cst })
}

///|
/// Applies a function to corresponding elements from two vectors, producing a
/// new vector.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector to combine with the first.
/// * `f` : The function to apply to pairs of elements from both vectors.
///
/// Returns a new vector containing the results of applying the function to each
/// pair of corresponding elements.
///
/// Panics if the two vectors have different lengths.
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
pub fn[T, U, V] Vector::zip_with(
  self : Vector[T],
  other : Vector[U],
  f : (T, U) -> V,
) -> Vector[V] {
  Vector::{ data: array_zip_with(self.data, other.data, f) }
}

///|
/// Converts a vector to a column matrix representation.
///
/// Parameters:
///
/// * `self` : The vector to convert to a column matrix.
///
/// Returns a `Matrix[T]` with dimensions `n × 1`, where `n` is the length of
/// the vector, containing the vector elements as a single column.
///
/// Example:
///
/// ```moonbit
/// let v = @immut.Vector::from_array([1, 2, 3])
/// let col_matrix = v.to_col_matrix()
/// // Result is a 3×1 matrix:
/// // |1|
/// // |2|
/// // |3|
/// inspect(
///   col_matrix,
///   content=
///     #||1|
///     #||2|
///     #||3|
///   ,
/// )
/// ```
///
pub fn[T] Vector::to_col_matrix(self : Vector[T]) -> Matrix[T] {
  Matrix::make(self.length(), 1, fn(i, _) { self[i] })
}

///|
/// Converts a vector into a row matrix where the vector elements become the
/// columns of a single row.
///
/// Parameters:
///
/// * `self` : The vector to convert into a row matrix.
///
/// Returns a matrix with one row and columns equal to the length of the vector,
/// where each element of the vector becomes a column in the matrix.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let row_matrix = v.to_row_matrix()
/// // Results in a 1×3 matrix: |1, 2, 3|
/// inspect(
///   row_matrix,
///   content=
///     #||1, 2, 3|
///   ,
/// )
/// ```
///
pub fn[T] Vector::to_row_matrix(self : Vector[T]) -> Matrix[T] {
  { data: self.data, row: 1, col: self.length() }
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
pub fn[T] Vector::make(n : Int, elem : T) -> Vector[T] {
  Vector::{ data: @immut/array.make(n, elem) }
}

///|
/// Creates a new vector of size `n` where each element is generated by applying
/// the function `f` to its index.
///
/// Parameters:
///
/// * `n` : The size of the vector to create.
/// * `f` : A function that takes an index (from 0 to `n-1`) and returns the
///   value for that position.
///
/// Returns a new `Vector[T]` with elements generated by the function.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::makei(5, fn(i) { i * 2 })
/// // Creates a vector |0, 2, 4, 6, 8|
/// inspect(v, content="|0, 2, 4, 6, 8|")
/// ```
///
pub fn[T] Vector::makei(n : Int, f : (Int) -> T) -> Vector[T] {
  Vector::{ data: @immut/array.makei(n, f) }
}

///|
/// Returns the number of elements in the vector.
///
/// Parameters:
///
/// * `self` : The vector whose length is to be determined.
///
/// Returns the length of the vector as an integer.
///
/// Example:
///
/// ```moonbit
/// let v = @immut.Vector::from_array([1, 2, 3, 4, 5])
/// inspect(v.length(), content="5")
/// ```
///
pub fn[T] Vector::length(self : Vector[T]) -> Int {
  self.data.length()
}

///|
/// Gets the element at the specified index.
///
/// Parameters:
///
/// * `self` : The vector to get the element from.
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
/// let v = Vector::from_array([1, 2, 3])
/// inspect(v[1], content="2")
/// ```
///
pub fn[T] Vector::op_get(self : Vector[T], i : Int) -> T {
  self.data[i]
}

///|
/// Creates a new vector with the element at the specified index replaced by a
/// new value.
///
/// Parameters:
///
/// * `self` : The original vector.
/// * `index` : The zero-based index of the element to replace.
/// * `value` : The new value to set at the specified index.
///
/// Returns a new vector with the element at `index` replaced by `value`. The
/// original vector remains unchanged.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// let updated = v.set(1, 10)
/// inspect(updated, content="|1, 10, 3|")
/// ```
///
pub fn[T] Vector::set(self : Vector[T], i : Int, x : T) -> Vector[T] {
  Vector::{ data: self.data.set(i, x) }
}

///|
/// Multiplies each element of the vector by a scalar value from the left.
///
/// Parameters:
///
/// * `self` : The vector to be scaled.
/// * `scalar` : The scalar value to multiply each element by.
///
/// Returns a new vector where each element is the product of the scalar and the
/// corresponding element from the original vector.
///
/// Example:
///
/// ```moonbit
/// let v = @immut.Vector::from_array([1, 2, 3])
/// let scaled = v.left_scale(5)
/// inspect(scaled, content="|5, 10, 15|")
/// ```
///
pub fn[T : Mul] Vector::left_scale(self : Vector[T], scalar : T) -> Vector[T] {
  self.map(x => scalar * x)
}

///|
/// Multiplies each element of the vector by a scalar value from the right.
///
/// Parameters:
///
/// * `self` : The vector to be scaled.
/// * `scalar` : The scalar value to multiply each element by.
///
/// Returns a new vector where each element is the product of the corresponding
/// element in the original vector and the scalar.
///
/// Example:
///
/// ```moonbit
/// let v = Vector::from_array([1, 2, 3])
/// inspect(v.right_scale(5), content="|5, 10, 15|")
/// ```
///
pub fn[T : Mul] Vector::right_scale(self : Vector[T], scalar : T) -> Vector[T] {
  self.map(x => x * scalar)
}

///|
/// Creates a new vector from a mutable array by converting it to an immutable
/// representation.
///
/// Parameters:
///
/// * `arr` : `Array[T]` - The mutable array to convert into a vector.
///
/// Returns a new `Vector[T]` containing the same elements as the input array.
///
/// Example:
///
/// ```moonbit
/// let arr = [1, 2, 3, 4, 5]
/// let vec = Vector::from_array(arr)
/// inspect(vec, content="|1, 2, 3, 4, 5|")
/// ```
///
pub fn[T] Vector::from_array(arr : Array[T]) -> Vector[T] {
  Vector::{ data: @immut/array.from_array(arr) }
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
  self.data.iter()
}

///|
/// Adds two vectors element-wise.
///
/// Parameters:
///
/// * `self` : The first vector.
/// * `other` : The second vector to add to the first.
///
/// Returns a new vector where each element is the sum of the corresponding
/// elements from the input vectors.
///
/// Example:
///
/// ```moonbit
/// let v1 = @immut.Vector::from_array([1, 2, 3])
/// let v2 = @immut.Vector::from_array([4, 5, 6])
/// inspect(v1 + v2, content="|5, 7, 9|")
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
/// let v1 = @immut.Vector::from_array([1, 2, 3])
/// let v2 = @immut.Vector::from_array([4, 5, 6])
/// inspect(v1 * v2, content="|4, 10, 18|")
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
/// `other` at parameter `alpha`.
///
/// Example:
///
/// ```moonbit
/// let v1 : Vector[Double] = @immut.Vector::from_array([1, 2, 3])
/// let v2 : Vector[Double] = @immut.Vector::from_array([4, 5, 6])
/// let result = v1.lerp(v2, 0.5)
/// inspect(result, content="|2.5, 3.5, 4.5|")
/// ```
///
pub fn[T : One + Mul + Add + Neg] Vector::lerp(
  self : Vector[T],
  other : Vector[T],
  alpha : T,
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
/// Converts the vector to its string representation in a readable format.
///
/// Parameters:
///
/// * `self` : The vector to convert to string.
///
/// Returns a string representation of the vector with elements separated by
/// commas and enclosed in pipe characters (e.g., "|1, 2, 3|").
pub impl[T : Show] Show for Vector[T] with to_string(self) {
  // Immutable array has no join method
  // we need to convert to mutable array first
  // wait for core to support immutable array join
  let sep = ", "
  "|\{self.data.to_array().map(T::to_string).join(sep)}|"
}

///|
/// Outputs the vector to a string representation using the `Show` trait's
/// output method.
///
/// Parameters:
///
/// * `self` : The vector to be output.
/// * `output` : The output stream to write the string representation to.
pub impl[T : Show] Show for Vector[T] with output(s, l) {
  l.write_string(s.to_string())
}

///|
/// Creates a diagonal matrix where the diagonal elements are the vector
/// elements and all other elements are zero.
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
/// let diagonal_matrix = v.scaled_matrix()
/// // Creates:
/// // |1, 0, 0|
/// // |0, 2, 0|
/// // |0, 0, 3|
/// inspect(
///   diagonal_matrix,
///   content=
///     #||1, 0, 0|
///     #||0, 2, 0|
///     #||0, 0, 3|
///   ,
/// )
/// ```
///
pub fn[T : Zero] Vector::scaled_matrix(self : Vector[T]) -> Matrix[T] {
  let n = self.length()
  Matrix::make(n, n, fn(i, j) { if i == j { self[i] } else { T::zero() } })
}

///|
/// Computes the tensor product (outer product) of two vectors, resulting in a
/// matrix where each element is the product of corresponding elements from the
/// input vectors.
///
/// Parameters:
///
/// * `self` : The first vector, which determines the number of rows in the
///   resulting matrix.
/// * `other` : The second vector, which determines the number of columns in the
///   resulting matrix.
///
/// Returns a matrix where the element at position (i, j) is the product of
/// `self[i]` and `other[j]`.
///
/// Example:
///
/// ```moonbit
/// let v1 = Vector::from_array([1, 2])
/// let v2 = Vector::from_array([3, 4, 5])
/// let result = v1.tensor_product(v2)
/// inspect(result, content=(
///   #||3, 4, 5|
///   #||6, 8, 10|
/// ))
/// // Result is a 2x3 matrix:
/// // |3, 4, 5|
/// // |6, 8, 10|
/// ```
///
pub fn[T : Mul] Vector::tensor_product(
  self : Vector[T],
  other : Vector[T],
) -> Matrix[T] {
  let n = self.length()
  let m = other.length()
  Matrix::make(n, m, fn(i, j) { self[i] * other[j] })
}

///|
/// Combines two immutable arrays element-wise using a provided function.
///
/// Parameters:
///
/// * `a1` : The first immutable array.
/// * `a2` : The second immutable array.
/// * `f` : The function to apply to each pair of corresponding elements.
///
/// Returns a new immutable array where each element is the result of applying
/// `f` to the corresponding elements from `a1` and `a2`.
///
/// Panics if the two input arrays have different lengths.
fn[X, Y, Z] array_zip_with(
  a1 : IArray[X],
  a2 : IArray[Y],
  f : (X, Y) -> Z,
) -> IArray[Z] {
  let n = a1.length()
  guard n == a2.length()
  @immut/array.makei(n, i => f(a1[i], a2[i]))
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
