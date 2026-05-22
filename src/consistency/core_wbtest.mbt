///|
/// Cross-package consistency checks for the shared algebraic API.
///
/// These tests intentionally compare only operations that should remain
/// semantically aligned between `immut` and `mutable`.

using @qc {quick_check_fn}

test "matrix core operations stay aligned" {
  let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let mutable_matrix = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])

  debug_inspect(mutable_matrix.to_array(), content=to_string(imm.to_array()))
  debug_inspect(
    (mutable_matrix + mutable_matrix).to_array(),
    content=to_string((imm + imm).to_array()),
  )
  debug_inspect(
    (mutable_matrix * mutable_matrix).to_array(),
    content=to_string((imm * imm).to_array()),
  )
  debug_inspect(
    mutable_matrix.transpose().to_array(),
    content=to_string(imm.transpose().to_array()),
  )
  inspect(mutable_matrix.trace(), content=imm.trace().to_string())
  inspect(mutable_matrix.is_square(), content=imm.is_square().to_string())
  inspect(mutable_matrix.null(), content=imm.null().to_string())
}

test "matrix constructors and conversions stay aligned" {
  let imm_make = @immut.Matrix::make(2, 3, fn(i, j) { i * 10 + j })
  let mutable_make = @mutable.Matrix::make(2, 3, fn(i, j) { i * 10 + j })
  debug_inspect(mutable_make.to_array(), content=to_string(imm_make.to_array()))

  let imm_new = @immut.Matrix::new(2, 2, 7)
  let mutable_new = @mutable.Matrix::new(2, 2, 7)
  debug_inspect(
    mutable_new.to_2d_array(),
    content=to_string(imm_new.to_2d_array()),
  )

  let imm_from_array = @immut.Matrix::from_array(
    2,
    2,
    @immut/array.from_array([1, 2, 3, 4]),
  )
  let mutable_from_array = @mutable.Matrix::from_array(2, 2, [1, 2, 3, 4])
  debug_inspect(
    mutable_from_array.to_array(),
    content=to_string(imm_from_array.to_array()),
  )
}

test "matrix and vector conversions stay aligned" {
  let imm_vec = @immut.Vector::from_array([2, 4, 6])
  let mutable_vec = @mutable.Vector::from_array([2, 4, 6])

  debug_inspect(
    mutable_vec.to_row_matrix().to_array(),
    content=to_string(imm_vec.to_row_matrix().to_array()),
  )
  debug_inspect(
    mutable_vec.to_col_matrix().to_array(),
    content=to_string(imm_vec.to_col_matrix().to_array()),
  )
  debug_inspect(
    mutable_vec.scaled_matrix().to_array(),
    content=to_string(imm_vec.scaled_matrix().to_array()),
  )
}

test "semantic differences stay explicit" {
  let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let imm2 = imm.set(0, 1, 9)
  inspect(imm.to_array(), content="[1, 2, 3, 4]")
  inspect(imm2.to_array(), content="[1, 9, 3, 4]")

  let mutable_matrix = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  mutable_matrix.set(0, 1, 9)
  debug_inspect(mutable_matrix.to_array(), content="[1, 9, 3, 4]")
}

test "identity and transpose laws stay aligned" {
  let imm_a = @immut.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let imm_b = @immut.Matrix::from_2d_array([[7, 8], [9, 10], [11, 12]])
  let mutable_a = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let mutable_b = @mutable.Matrix::from_2d_array([[7, 8], [9, 10], [11, 12]])

  let imm_i2 : @immut.Matrix[Int] = @immut.Matrix::identity(2)
  let imm_i3 : @immut.Matrix[Int] = @immut.Matrix::identity(3)
  let mutable_i2 : @mutable.Matrix[Int] = @mutable.identity(2)
  let mutable_i3 : @mutable.Matrix[Int] = @mutable.identity(3)

  debug_inspect((imm_a * imm_i3).to_array(), content=to_string(imm_a.to_array()))
  debug_inspect(
    (mutable_a * mutable_i3).to_array(),
    content=to_string(mutable_a.to_array()),
  )
  debug_inspect((imm_i2 * imm_a).to_array(), content=to_string(imm_a.to_array()))
  debug_inspect(
    (mutable_i2 * mutable_a).to_array(),
    content=to_string(mutable_a.to_array()),
  )

  debug_inspect(
    (imm_a * imm_b).transpose().to_array(),
    content=to_string((imm_b.transpose() * imm_a.transpose()).to_array()),
  )
  debug_inspect(
    (mutable_a * mutable_b).transpose().to_array(),
    content=to_string((mutable_b.transpose() * mutable_a.transpose()).to_array()),
  )
  debug_inspect(
    imm_a.transpose().transpose().to_array(),
    content=to_string(imm_a.to_array()),
  )
  debug_inspect(
    mutable_a.transpose().transpose().to_array(),
    content=to_string(mutable_a.to_array()),
  )
}

test "trace and multiplication associativity stay aligned" {
  let imm_a = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let imm_b = @immut.Matrix::from_2d_array([[0, 1], [1, 0]])
  let imm_c = @immut.Matrix::from_2d_array([[2, 1], [1, 2]])
  let mutable_a = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  let mutable_b = @mutable.Matrix::from_2d_array([[0, 1], [1, 0]])
  let mutable_c = @mutable.Matrix::from_2d_array([[2, 1], [1, 2]])

  debug_inspect(
    ((imm_a * imm_b) * imm_c).to_array(),
    content=to_string((imm_a * (imm_b * imm_c)).to_array()),
  )
  debug_inspect(
    ((mutable_a * mutable_b) * mutable_c).to_array(),
    content=to_string((mutable_a * (mutable_b * mutable_c)).to_array()),
  )
  inspect(imm_a.trace(), content=imm_a.transpose().trace().to_string())
  inspect(
    mutable_a.trace(),
    content=mutable_a.transpose().trace().to_string(),
  )
}

test "vector tensor and matrix conversion laws stay aligned" {
  let imm_v = @immut.Vector::from_array([1, 2])
  let imm_w = @immut.Vector::from_array([3, 4, 5])
  let imm_diag_rhs = @immut.Vector::from_array([3, 4])
  let mutable_v = @mutable.Vector::from_array([1, 2])
  let mutable_w = @mutable.Vector::from_array([3, 4, 5])
  let mutable_diag_rhs = @mutable.Vector::from_array([3, 4])

  inspect(
    imm_v.tensor_product(imm_w).to_array(),
    content="[3, 4, 5, 6, 8, 10]",
  )
  inspect(
    mutable_v.tensor_product(mutable_w).to_array(),
    content="[3, 4, 5, 6, 8, 10]",
  )
  inspect(
    imm_v.tensor_product(imm_w).row(),
    content=imm_v.length().to_string(),
  )
  inspect(
    mutable_v.tensor_product(mutable_w).row(),
    content=mutable_v.length().to_string(),
  )
  inspect(
    imm_v.tensor_product(imm_w).col(),
    content=imm_w.length().to_string(),
  )
  inspect(
    mutable_v.tensor_product(mutable_w).col(),
    content=mutable_w.length().to_string(),
  )
  debug_inspect(
    (imm_v.scaled_matrix() * imm_diag_rhs.to_col_matrix()).to_array(),
    content=to_string((imm_v * imm_diag_rhs).to_col_matrix().to_array()),
  )
  debug_inspect(
    (mutable_v.scaled_matrix() * mutable_diag_rhs.to_col_matrix()).to_array(),
    content=to_string((mutable_v * mutable_diag_rhs).to_col_matrix().to_array()),
  )
}

test "cross-package matrix semiring laws on small integers" {
  fn prop(input : ((Int, Int, Int, Int), (Int, Int, Int, Int), (Int, Int, Int, Int))) {
    let ((a00, a01, a10, a11), (b00, b01, b10, b11), (c00, c01, c10, c11)) = input
    let imm_a = @immut.Matrix::from_2d_array([[a00, a01], [a10, a11]])
    let imm_b = @immut.Matrix::from_2d_array([[b00, b01], [b10, b11]])
    let imm_c = @immut.Matrix::from_2d_array([[c00, c01], [c10, c11]])
    let mut_a = @mutable.Matrix::from_2d_array([[a00, a01], [a10, a11]])
    let mut_b = @mutable.Matrix::from_2d_array([[b00, b01], [b10, b11]])
    let mut_c = @mutable.Matrix::from_2d_array([[c00, c01], [c10, c11]])

    ((imm_a + imm_b) + imm_c).to_array() == (imm_a + (imm_b + imm_c)).to_array() &&
    ((mut_a + mut_b) + mut_c).to_array() == (mut_a + (mut_b + mut_c)).to_array() &&
    (imm_a * (imm_b + imm_c)).to_array() == ((imm_a * imm_b) + (imm_a * imm_c)).to_array() &&
    (mut_a * (mut_b + mut_c)).to_array() == ((mut_a * mut_b) + (mut_a * mut_c)).to_array() &&
    (imm_a * imm_b).to_array() == (mut_a * mut_b).to_array()
  }

  quick_check_fn(prop)
}
