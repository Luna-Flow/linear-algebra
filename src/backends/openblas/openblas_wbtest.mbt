///|
fn[T : BLASInnerType] matrix_close(
  left : BlasMatrix[T],
  right : BlasMatrix[T],
) -> Bool {
  guard left.row() == right.row() && left.col() == right.col() else {
    return false
  }
  let left_rows = left.to_2d_array()
  let right_rows = right.to_2d_array()
  for i in 0..<left.row() {
    for j in 0..<left.col() {
      let diff = left_rows[i][j] + -right_rows[i][j]
      let abs_diff = if diff < T::zero() { -diff } else { diff }
      if abs_diff > T::tolerance() {
        return false
      }
    }
  }
  true
}

///|
fn[T : BLASInnerType] vector_close(
  left : BlasVector[T],
  right : BlasVector[T],
) -> Bool {
  guard left.length() == right.length() else { return false }
  for i in 0..<left.length() {
    let diff = left[i] + -right[i]
    let abs_diff = if diff < T::zero() { -diff } else { diff }
    if abs_diff > T::tolerance() {
      return false
    }
  }
  true
}

///|
fn[M : @algebra.MatMulMatrix] generic_mul(left : M, right : M) -> M {
  left * right
}

///|
test "openblas backend constructs float vectors" {
  let vector = BlasVector::from_array([1.0F, 2.0F, 3.0F])
  inspect(vector.length(), content="3")
  debug_inspect(vector.to_array(), content="[1, 2, 3]")
}

///|
test "openblas backend constructs float matrices" {
  let matrix = BlasMatrix::from_2d_array([[1.0F, 2.0F], [3.0F, 4.0F]])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
  debug_inspect(matrix.to_2d_array(), content="[[1, 2], [3, 4]]")
}

///|
test "openblas backend constructs double matrices" {
  let matrix = BlasMatrix::new(2, 3, 1.5)
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="3")
  debug_inspect(
    matrix.to_2d_array(),
    content="[[1.5, 1.5, 1.5], [1.5, 1.5, 1.5]]",
  )
}

///|
test "openblas backend transpose uses row-major shape rules" {
  let matrix = BlasMatrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  let transposed = @algebra.TransposeMatrix::transpose(matrix)
  inspect(transposed.row(), content="3")
  inspect(transposed.col(), content="2")
  debug_inspect(transposed.to_2d_array(), content="[[1, 4], [2, 5], [3, 6]]")
}

///|
test "openblas backend additive operations stay value-semantic" {
  let left = BlasMatrix::from_2d_array([[1.0F, 2.0F], [3.0F, 4.0F]])
  let right = BlasMatrix::from_2d_array([[0.5F, 1.5F], [2.5F, 3.5F]])
  debug_inspect(
    (left + right).to_2d_array(),
    content="[[1.5, 3.5], [5.5, 7.5]]",
  )
  debug_inspect((-left).to_2d_array(), content="[[-1, -2], [-3, -4]]")
  debug_inspect(
    (left - right).to_2d_array(),
    content="[[0.5, 0.5], [0.5, 0.5]]",
  )
}

///|
test "openblas backend float matmul matches immut implementation" {
  let left = BlasMatrix::from_2d_array([[1.0F, 2.0F, 3.0F], [4.0F, 5.0F, 6.0F]])
  let right = BlasMatrix::from_2d_array([
    [7.0F, 8.0F],
    [9.0F, 10.0F],
    [11.0F, 12.0F],
  ])
  let product = generic_mul(left, right)
  let expected = BlasMatrix::from_immut(
    @immut.Matrix::from_2d_array([[1.0F, 2.0F, 3.0F], [4.0F, 5.0F, 6.0F]]) *
    @immut.Matrix::from_2d_array([[7.0F, 8.0F], [9.0F, 10.0F], [11.0F, 12.0F]]),
  )
  inspect(matrix_close(product, expected), content="true")
}

///|
test "openblas backend double matmul matches default immutable dense wrapper" {
  let left = BlasMatrix::from_2d_array([[1.0, 0.0], [2.0, 3.0], [4.0, 5.0]])
  let right = BlasMatrix::from_2d_array([[6.0, 7.0, 8.0], [9.0, 10.0, 11.0]])
  let product = left * right
  let expected = BlasMatrix::from_default(
    @default.ImmutableDenseMatrix::from_2d_array([
      [1.0, 0.0],
      [2.0, 3.0],
      [4.0, 5.0],
    ]) *
    @default.ImmutableDenseMatrix::from_2d_array([
      [6.0, 7.0, 8.0],
      [9.0, 10.0, 11.0],
    ]),
  )
  inspect(matrix_close(product, expected), content="true")
}

///|
test "openblas backend conversions round-trip through immut and default wrappers" {
  let matrix = BlasMatrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let via_immut = BlasMatrix::from_immut(matrix.to_immut())
  let via_default = BlasMatrix::from_default(matrix.to_default())
  let vector = BlasVector::from_array([1.0, 2.0, 3.0])
  let via_immut_vector = BlasVector::from_immut(vector.to_immut())
  let via_default_vector = BlasVector::from_default(vector.to_default())
  inspect(matrix_close(matrix, via_immut), content="true")
  inspect(matrix_close(matrix, via_default), content="true")
  inspect(vector_close(vector, via_immut_vector), content="true")
  inspect(vector_close(vector, via_default_vector), content="true")
}

///|
test "openblas backend vector blas matches default immutable dense wrapper" {
  let left = BlasVector::from_array([1.0F, 2.0F, 3.0F])
  let right = BlasVector::from_array([4.0F, 5.0F, 6.0F])
  inspect(left.dot(right), content="32")
  let scaled = left.scale(2.0F)
  let axpy_out = left.axpy(2.0F, right)
  let expected_scaled = BlasVector::from_immut(
    @immut.Vector::from_array([1.0F, 2.0F, 3.0F]).right_scale(2.0F),
  )
  let expected_axpy = BlasVector::from_immut(
    @immut.Vector::from_array([1.0F, 2.0F, 3.0F]).right_scale(2.0F) +
    @immut.Vector::from_array([4.0F, 5.0F, 6.0F]),
  )
  inspect(vector_close(scaled, expected_scaled), content="true")
  inspect(vector_close(axpy_out, expected_axpy), content="true")
}

///|
test "openblas backend gemv matches immut implementation" {
  let matrix = BlasMatrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  let vector = BlasVector::from_array([7.0, 8.0, 9.0])
  let product = matrix.matvec(vector)
  let expected_rows = @immut.Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
  ])
  let expected_vector = @immut.Vector::from_array([7.0, 8.0, 9.0])
  let expected = BlasVector::from_immut(
    @immut.Vector::makei(expected_rows.row(), fn(i) {
      let mut sum = 0.0
      for j in 0..<expected_rows.col() {
        sum = sum + expected_rows[i][j] * expected_vector[j]
      }
      sum
    }),
  )
  inspect(vector_close(product, expected), content="true")
}

///|
test "openblas container adapters provide checked read and build" {
  let vector : BlasVector[Double] = (blas_vector_build_ops().tabulate)(3, fn(
    index,
  ) {
    index.to_double() + 0.5
  }).unwrap()
  inspect((blas_vector_read_ops().get)(vector, 0).unwrap(), content="0.5")
  inspect((blas_vector_read_ops().get)(vector, 2).unwrap(), content="2.5")
  match (blas_vector_read_ops().get)(vector, -1) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("negative OpenBLAS vector index must fail")
  }
  let matrix : BlasMatrix[Double] = (blas_matrix_build_ops().tabulate)(2, 3, fn(
    row,
    col,
  ) {
    (row * 10 + col).to_double()
  }).unwrap()
  debug_inspect(matrix.to_2d_array(), content="[[0, 1, 2], [10, 11, 12]]")
  match (blas_matrix_read_ops().get)(matrix, 2, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("invalid OpenBLAS matrix row must fail")
  }
}

///|
test "generic algorithms cross OpenBLAS and default storage" {
  let source = BlasMatrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  let mapped : @default.ImmutableDenseMatrix[Double] = @container.matrix_map(
    source,
    blas_matrix_read_ops(),
    @container_adapters.immutable_dense_matrix_build_ops(),
    fn(value) { value + 1.0 },
  ).unwrap()
  debug_inspect(mapped.inner().to_2d_array(), content="[[2, 3, 4], [5, 6, 7]]")
  let transposed : BlasMatrix[Double] = @container.matrix_transpose(
    mapped,
    @container_adapters.immutable_dense_matrix_read_ops(),
    blas_matrix_build_ops(),
  ).unwrap()
  debug_inspect(transposed.to_2d_array(), content="[[2, 5], [3, 6], [4, 7]]")
}

///|
test "panic openblas_matmul/dimension_mismatch" {
  let left = BlasMatrix::from_2d_array([[1.0F, 2.0F]])
  let right = BlasMatrix::from_2d_array([[3.0F, 4.0F]])
  ignore(left * right)
}

///|
test "panic openblas_dot/length_mismatch" {
  let left = BlasVector::from_array([1.0F, 2.0F])
  let right = BlasVector::from_array([3.0F])
  ignore(left.dot(right))
}

///|
test "panic openblas_gemv/dimension_mismatch" {
  let matrix = BlasMatrix::from_2d_array([[1.0F, 2.0F]])
  let vector = BlasVector::from_array([3.0F])
  ignore(matrix.matvec(vector))
}
