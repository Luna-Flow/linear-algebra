///|
fn[V : @algebra.AdditiveVector] vector_add(left : V, right : V) -> V {
  left + right
}

///|
fn[V : @algebra.VecMulVector] vector_mul(left : V, right : V) -> V {
  left * right
}

///|
test "default backend exposes mutable and immutable dense matrix shapes" {
  let mutable_matrix : DenseMatrix[Int] = DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  let immutable_matrix : ImmutableDenseMatrix[Int] = ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  let (mutable_rows, mutable_cols) = shape_of(mutable_matrix)
  inspect(mutable_rows, content="2")
  inspect(mutable_cols, content="2")
  let (immutable_rows, immutable_cols) = shape_of(immutable_matrix)
  inspect(immutable_rows, content="2")
  inspect(immutable_cols, content="2")
}

///|
test "default dense vector dispatches vector-like operations" {
  let left = DenseVector::from_array([1, 2, 3])
  let right = DenseVector::from_array([4, 5, 6])
  inspect(left.length(), content="3")
  inspect(vector_add(left, right).inner(), content="|5, 7, 9|")
  inspect(vector_mul(left, right).inner(), content="|4, 10, 18|")
}

///|
test "default immutable dense vector dispatches vector-like operations" {
  let left = ImmutableDenseVector::from_array([1, 2, 3])
  let right = ImmutableDenseVector::from_array([4, 5, 6])
  inspect(left.length(), content="3")
  inspect(vector_add(left, right).inner(), content="|5, 7, 9|")
  inspect(vector_mul(left, right).inner(), content="|4, 10, 18|")
}

///|
test "default backend matrix algorithms use matrix-like operations" {
  let a : DenseMatrix[Int] = DenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let b : DenseMatrix[Int] = DenseMatrix::from_2d_array([[0, 1], [1, 0]])
  let (product_rows, product_cols) = shape_of(matmul(a, b))
  inspect(product_rows, content="2")
  inspect(product_cols, content="2")
  let (transpose_rows, transpose_cols) = shape_of(transpose(a))
  inspect(transpose_rows, content="2")
  inspect(transpose_cols, content="2")
}

///|
test "default immutable backend checked matmul is constructible" {
  let a = ImmutableDenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let b = ImmutableDenseMatrix::from_2d_array([[0, 1], [1, 0]])
  let product = @immut.matmul_with(@immut.CheckedBackend, a.inner(), b.inner())
  inspect(product, content="|2, 1|\n|4, 3|")
}
