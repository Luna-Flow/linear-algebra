///|
struct TestVector[T] {
  data : Array[T]
}

///|
struct TestMatrix[T] {
  rows : Int
  cols : Int
  data : Array[T]
}

///|
fn[T] test_vector_read_ops() -> VectorReadOps[TestVector[T], T] {
  VectorReadOps::new(fn(vector) { vector.data.length() }, fn(vector, index) {
    guard index >= 0 && index < vector.data.length() else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds(
          "Vector index out of bounds",
        ),
      )
    }
    Ok(vector.data[index])
  })
}

///|
fn[T] test_vector_build_ops() -> VectorBuildOps[TestVector[T], T] {
  VectorBuildOps::new(fn(length, initializer) {
    guard length >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension("Negative length"),
      )
    }
    Ok({ data: Array::makei(length, initializer) })
  })
}

///|
fn[T] test_matrix_read_ops() -> MatrixReadOps[TestMatrix[T], T] {
  MatrixReadOps::new(fn(matrix) { (matrix.rows, matrix.cols) }, fn(
    matrix,
    row,
    col,
  ) {
    guard row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds(
          "Matrix index out of bounds",
        ),
      )
    }
    Ok(matrix.data[row * matrix.cols + col])
  })
}

///|
fn[T] test_matrix_build_ops() -> MatrixBuildOps[TestMatrix[T], T] {
  MatrixBuildOps::new(fn(rows, cols, initializer) {
    guard rows >= 0 && cols >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension("Negative shape"),
      )
    }
    Ok({
      rows,
      cols,
      data: Array::makei(rows * cols, fn(index) {
        initializer(index / cols, index % cols)
      }),
    })
  })
}

///|
test "generic vector map converts scalar and container types" {
  let source : TestVector[Int] = { data: [1, 2, 3] }
  let output : TestVector[String] = vector_map(
    source,
    test_vector_read_ops(),
    test_vector_build_ops(),
    fn(value) { value.to_string() },
  ).unwrap()
  inspect(output.data.length(), content="3")
  inspect(output.data[0], content="1")
  inspect(output.data[1], content="2")
  inspect(output.data[2], content="3")
}

///|
test "generic matrix map and transpose preserve coordinate order" {
  let source : TestMatrix[Int] = {
    rows: 2,
    cols: 3,
    data: [0, 1, 2, 10, 11, 12],
  }
  let mapped : TestMatrix[Int] = matrix_map(
    source,
    test_matrix_read_ops(),
    test_matrix_build_ops(),
    fn(value) { value + 100 },
  ).unwrap()
  debug_inspect(mapped.data, content="[100, 101, 102, 110, 111, 112]")
  let transposed : TestMatrix[Int] = matrix_transpose(
    source,
    test_matrix_read_ops(),
    test_matrix_build_ops(),
  ).unwrap()
  debug_inspect((transposed.rows, transposed.cols), content="(3, 2)")
  debug_inspect(transposed.data, content="[0, 10, 1, 11, 2, 12]")
}

///|
test "generic algorithms reject malformed dimensions before building" {
  let bad_vector : VectorReadOps[TestVector[Int], Int] = VectorReadOps::new(
    fn(_) { -1 },
    fn(_, _) { Ok(0) },
  )
  match vector_convert({ data: [] }, bad_vector, test_vector_build_ops()) {
    Err(error) => inspect(error.is_negative_dimension(), content="true")
    Ok(_) => fail("expected negative vector length error")
  }
  let bad_matrix : MatrixReadOps[TestMatrix[Int], Int] = MatrixReadOps::new(
    fn(_) { (-1, 2) },
    fn(_, _, _) { Ok(0) },
  )
  match
    matrix_convert(
      { rows: -1, cols: 2, data: [] },
      bad_matrix,
      test_matrix_build_ops(),
    ) {
    Err(error) => inspect(error.is_negative_dimension(), content="true")
    Ok(_) => fail("expected negative matrix shape error")
  }
}

///|
test "generic algorithms propagate read errors without building" {
  let mut builds = 0
  let read : VectorReadOps[TestVector[Int], Int] = VectorReadOps::new(
    fn(_) { 2 },
    fn(_, index) {
      if index == 1 {
        Err(
          @la_error.LinearAlgebraError::index_out_of_bounds("Synthetic failure"),
        )
      } else {
        Ok(1)
      }
    },
  )
  let build : VectorBuildOps[TestVector[Int], Int] = VectorBuildOps::new(fn(
    length,
    initializer,
  ) {
    builds = builds + 1
    Ok({ data: Array::makei(length, initializer) })
  })
  match vector_convert({ data: [1, 2] }, read, build) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("expected synthetic read error")
  }
  inspect(builds, content="0")
}
