///|
test "determinant representable floating result regression" {
  let matrix : Matrix[Double] = Matrix::make(60, 60, fn(i, j) {
    if i == j {
      1000.0
    } else if j == i + 1 {
      1.0
    } else {
      0.0
    }
  })
  let determinant = matrix.determinant().unwrap()
  assert_true((determinant / 1.0e180 - 1.0).abs() < 1.0e-12)
}

///|
/// A = L U, with unit lower-triangular L (all entries below its diagonal 1)
/// and U having diagonal 1000 and every entry above its diagonal 1.
/// Therefore det(A) = 1000^60; A is dense, not triangular.
test "determinant dense floating result and immutable input" {
  let matrix : Matrix[Double] = Matrix::make(60, 60, fn(i, j) {
    if j <= i {
      1000.0 + j.to_double()
    } else {
      (i + 1).to_double()
    }
  })
  let before = matrix.to_array()
  let result = matrix.determinant().unwrap()
  assert_true((result / 1.0e180 - 1.0).abs() < 1.0e-10)
  assert_eq(matrix.to_array(), before)
  let swapped = matrix.swap_rows(0, 59)
  assert_true((swapped.determinant().unwrap() / 1.0e180 + 1.0).abs() < 1.0e-10)
}

///|
test "determinant Float LU avoids Bareiss overflow" {
  let matrix : Matrix[Float] = Matrix::make(15, 15, fn(i, j) {
    if j <= i {
      Float::from_int(100 + j)
    } else {
      Float::from_int(i + 1)
    }
  })
  assert_true((matrix.determinant().unwrap() / 1.0e30 - 1.0).abs() < 1.0e-4)
}

///|
test "determinant floating boundaries" {
  let empty : Matrix[Double] = Matrix::new(0, 0, 0.0)
  inspect(empty.determinant().unwrap(), content="1")
  let tiny = Matrix::from_2d_array([[1.0e-12, 0.0], [0.0, 1.0e-12]])
  assert_true((tiny.determinant().unwrap() / 1.0e-24 - 1.0).abs() < 1.0e-14)
  let singular = Matrix::make(5, 5, fn(i, j) {
    if i == j && i != 4 {
      1.0
    } else {
      0.0
    }
  })
  inspect(singular.determinant().unwrap(), content="0")
  let rectangular = Matrix::new(2, 3, 0.0)
  match rectangular.determinant() {
    Err(err) => assert_true(err.is_non_square_matrix())
    Ok(_) => fail("rectangular matrix must return NonSquareMatrix")
  }
  let lazy_matrix : MatrixFn[Double] = MatrixFn::make(60, 60, fn(i, j) {
    if i == j {
      1000.0
    } else if j == i + 1 {
      1.0
    } else {
      0.0
    }
  })
  assert_true((lazy_matrix.determinant() / 1.0e180 - 1.0).abs() < 1.0e-12)
}

///|
test "determinant exact scalar strategies" {
  let entries = [
    [2, -1, 0, 0, 0],
    [-1, 2, -1, 0, 0],
    [0, -1, 2, -1, 0],
    [0, 0, -1, 2, -1],
    [0, 0, 0, -1, 2],
  ]
  let matrix = Matrix::from_2d_array(entries)
  inspect(matrix.determinant().unwrap(), content="6")
  inspect(
    matrix.map(fn(x) { Int16::from_int(x) }).determinant().unwrap(),
    content="6",
  )
  inspect(
    matrix.map(fn(x) { x.to_int64() }).determinant().unwrap(),
    content="6",
  )
  let scale = BigInt::from_int(1000000)
  let big = matrix.map(fn(x) { BigInt::from_int(x) * scale })
  let expected = BigInt::from_int(6) * scale * scale * scale * scale * scale
  assert_eq(big.determinant().unwrap(), expected)
  assert_eq(big.swap_rows(0, 4).determinant().unwrap(), -expected)
}
