///|
test "immutable vector read adapter checks every boundary" {
  let read = immutable_vector_read_ops()
  let vector = @immut.Vector::from_array([4, 5, 6])
  inspect((read.get)(vector, 0).unwrap(), content="4")
  inspect((read.get)(vector, 2).unwrap(), content="6")
  match (read.get)(vector, -1) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("negative index must fail")
  }
  match (read.get)(vector, 3) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("index equal to length must fail")
  }
  let empty = @immut.Vector::from_array([])
  match (read.get)(empty, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("empty vector access must fail")
  }
}

///|
test "matrix read adapters check corners and degenerate shapes" {
  let read = mutable_matrix_read_ops()
  let matrix = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  inspect((read.get)(matrix, 0, 0).unwrap(), content="1")
  inspect((read.get)(matrix, 1, 2).unwrap(), content="6")
  for coordinate in [(-1, 0), (0, -1), (2, 0), (0, 3)] {
    let (row, col) = coordinate
    match (read.get)(matrix, row, col) {
      Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
      Ok(_) => fail("invalid coordinate must fail")
    }
  }
  let zero_rows = @mutable.Matrix::new(0, 3, 0)
  debug_inspect((read.shape)(zero_rows), content="(0, 3)")
  match (read.get)(zero_rows, 0, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("zero-row access must fail")
  }
  let zero_cols = @mutable.Matrix::new(2, 0, 0)
  debug_inspect((read.shape)(zero_cols), content="(2, 0)")
  match (read.get)(zero_cols, 0, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("zero-column access must fail")
  }
}

///|
test "build adapters preserve shapes and coordinate ordering" {
  let vector_calls = []
  let vector : @mutable.Vector[Int] = (mutable_vector_build_ops().tabulate)(4, fn(
    index,
  ) {
    vector_calls.push(index)
    index * 2
  }).unwrap()
  debug_inspect(vector_calls, content="[0, 1, 2, 3]")
  inspect(vector, content="|0, 2, 4, 6|")
  let matrix_calls = []
  let matrix : @immut.Matrix[Int] = (immutable_matrix_build_ops().tabulate)(
    2,
    3,
    fn(row, col) {
      matrix_calls.push((row, col))
      row * 10 + col
    },
  ).unwrap()
  debug_inspect(
    matrix_calls,
    content="[(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]",
  )
  inspect(matrix, content="|0, 1, 2|\n|10, 11, 12|")
  let empty_vector : @immut.Vector[Int] = (immutable_vector_build_ops().tabulate)(
    0,
    fn(_) { 0 },
  ).unwrap()
  inspect(empty_vector.length(), content="0")
  let zero_rows : @immut.Matrix[Int] = (immutable_matrix_build_ops().tabulate)(
    0,
    3,
    fn(_, _) { 0 },
  ).unwrap()
  debug_inspect((zero_rows.row(), zero_rows.col()), content="(0, 3)")
  let zero_cols : @mutable.Matrix[Int] = (mutable_matrix_build_ops().tabulate)(
    2,
    0,
    fn(_, _) { 0 },
  ).unwrap()
  debug_inspect((zero_cols.row(), zero_cols.col()), content="(2, 0)")
}

///|
test "build adapters reject negative dimensions before initialization" {
  let mut calls = 0
  match
    (mutable_vector_build_ops().tabulate)(-1, fn(_) {
      calls = calls + 1
      0
    }) {
    Err(error) => inspect(error.is_negative_dimension(), content="true")
    Ok(_) => fail("negative vector length must fail")
  }
  match
    (immutable_matrix_build_ops().tabulate)(-1, 2, fn(_, _) {
      calls = calls + 1
      0
    }) {
    Err(error) => inspect(error.is_negative_dimension(), content="true")
    Ok(_) => fail("negative matrix shape must fail")
  }
  inspect(calls, content="0")
}

///|
test "persistent edits preserve source vectors and matrices" {
  let vector = @immut.Vector::from_array([1, 2, 3])
  let updated_vector = (immutable_vector_persistent_edit_ops().set)(
    vector, 1, 9,
  ).unwrap()
  inspect(vector, content="|1, 2, 3|")
  inspect(updated_vector, content="|1, 9, 3|")
  match (immutable_vector_persistent_edit_ops().set)(vector, 3, 9) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("invalid persistent vector edit must fail")
  }
  let matrix = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let updated_matrix = (immutable_matrix_persistent_edit_ops().set)(
    matrix, 0, 1, 8,
  ).unwrap()
  inspect(matrix, content="|1, 2|\n|3, 4|")
  inspect(updated_matrix, content="|1, 8|\n|3, 4|")
  match (immutable_matrix_persistent_edit_ops().set)(matrix, 2, 0, 8) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("invalid persistent matrix edit must fail")
  }
}

///|
test "mutable edits are in place and atomic on failure" {
  let vector = @mutable.Vector::from_array([1, 2, 3])
  (mutable_vector_mutable_edit_ops().set)(vector, 1, 9).unwrap()
  inspect(vector, content="|1, 9, 3|")
  match (mutable_vector_mutable_edit_ops().set)(vector, 3, 7) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("invalid mutable vector edit must fail")
  }
  inspect(vector, content="|1, 9, 3|")
  let matrix = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  (mutable_matrix_mutable_edit_ops().set)(matrix, 1, 0, 8).unwrap()
  inspect(matrix, content="|1, 2|\n|8, 4|")
  match (mutable_matrix_mutable_edit_ops().set)(matrix, 1, 2, 7) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("invalid mutable matrix edit must fail")
  }
  inspect(matrix, content="|1, 2|\n|8, 4|")
}

///|
test "generic maps cross dense implementations and scalar types" {
  let mutable_source = @mutable.Vector::from_array([1, 2, 3])
  let immutable_target : @immut.Vector[String] = @container.vector_map(
    mutable_source,
    mutable_vector_read_ops(),
    immutable_vector_build_ops(),
    fn(value) { (value * 10).to_string() },
  ).unwrap()
  inspect(immutable_target, content="|10, 20, 30|")
  let matrix_source = @immut.Matrix::make(2, 3, fn(row, col) { row * 10 + col })
  let matrix_target : @mutable.Matrix[Int] = @container.matrix_map(
    matrix_source,
    immutable_matrix_read_ops(),
    mutable_matrix_build_ops(),
    fn(value) { value + 1 },
  ).unwrap()
  inspect(matrix_target, content="|1, 2, 3|\n|11, 12, 13|")
}

///|
test "generic transpose supports cross implementation and degenerate shapes" {
  let rectangular = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let transposed : @immut.Matrix[Int] = @container.matrix_transpose(
    rectangular,
    mutable_matrix_read_ops(),
    immutable_matrix_build_ops(),
  ).unwrap()
  inspect(transposed, content="|1, 4|\n|2, 5|\n|3, 6|")
  let square = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let square_output : @mutable.Matrix[Int] = @container.matrix_transpose(
    square,
    immutable_matrix_read_ops(),
    mutable_matrix_build_ops(),
  ).unwrap()
  inspect(square_output, content="|1, 3|\n|2, 4|")
  let zero_rows = @immut.Matrix::make(0, 3, fn(_, _) { 0 })
  let zero_rows_output : @mutable.Matrix[Int] = @container.matrix_transpose(
    zero_rows,
    immutable_matrix_read_ops(),
    mutable_matrix_build_ops(),
  ).unwrap()
  debug_inspect(
    (zero_rows_output.row(), zero_rows_output.col()),
    content="(3, 0)",
  )
  let zero_cols = @mutable.Matrix::new(2, 0, 0)
  let zero_cols_output : @immut.Matrix[Int] = @container.matrix_transpose(
    zero_cols,
    mutable_matrix_read_ops(),
    immutable_matrix_build_ops(),
  ).unwrap()
  debug_inspect(
    (zero_cols_output.row(), zero_cols_output.col()),
    content="(0, 2)",
  )
}

///|
test "named conversion crosses default wrapper ownership models" {
  let source = @default.DenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let target : @default.ImmutableDenseMatrix[Int] = @container.matrix_convert(
    source,
    dense_matrix_read_ops(),
    immutable_dense_matrix_build_ops(),
  ).unwrap()
  inspect(target.inner(), content="|1, 2|\n|3, 4|")
  source.inner().set(0, 0, 99)
  inspect(target.inner(), content="|1, 2|\n|3, 4|")
}

///|
test "view adapters observe and mutate shared matrix storage" {
  let matrix = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row = matrix.row_view(1)
  inspect((mutable_row_view_read_ops().get)(row, 2).unwrap(), content="6")
  (mutable_row_view_mutable_edit_ops().set)(row, 0, 40).unwrap()
  inspect(matrix.get(1, 0), content="40")
  let col = matrix.col_view(1)
  (mutable_col_view_mutable_edit_ops().set)(col, 0, 20).unwrap()
  inspect(matrix.get(0, 1), content="20")
  let transpose = matrix.to_transpose()
  inspect(
    (mutable_transpose_read_ops().get)(transpose, 2, 1).unwrap(),
    content="6",
  )
  (mutable_transpose_mutable_edit_ops().set)(transpose, 2, 0, 30).unwrap()
  inspect(matrix.get(0, 2), content="30")
}
