///|
test "transpose_basic_and_arithmetic" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()

  // basic shape and formatting
  inspect(t.row(), content="3")
  inspect(t.col(), content="2")
  inspect(t.to_string(), content="|0, 3|\n|1, 4|\n|2, 5|")

  // equality and arithmetic (Add/Sub/Neg)
  inspect(t == t, content="true")
  inspect(
    t + t,
    content=(
      #||0, 6|
      #||2, 8|
      #||4, 10|
    ),
  )
  inspect(
    t - t,
    content=(
      #||0, 0|
      #||0, 0|
      #||0, 0|
    ),
  )
  inspect(
    -t,
    content=(
      #||0, -3|
      #||-1, -4|
      #||-2, -5|
    ),
  )
}

///|
test "transpose_multiplication" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()
  let mul_rhs = Matrix::from_2d_array([[1, 2], [3, 4], [5, 6]])
  let t_rhs = mul_rhs.to_transpose()

  // multiplication (uses underlying b * a order)
  inspect(
    t * t_rhs,
    content=(
      #||6, 12, 18|
      #||9, 19, 29|
      #||12, 26, 40|
    ),
  )
}

///|
test "transpose_iteration" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()

  // iteration helpers
  let mut sum = 0
  t.each(fn(x) { sum += x })
  inspect(sum, content="15")
  let idx_hits = Array::make(6, 0)
  t.eachi(fn(idx, v) { idx_hits[idx] = v })
  inspect(idx_hits, content="[0, 3, 1, 4, 2, 5]")
  let row0 = Array::make(2, 0)
  let mut ri = 0
  t.each_row(0, fn(x) {
    row0[ri] = x
    ri += 1
  })
  inspect(row0, content="[0, 3]")
  let row1 = Array::make(2, 0)
  t.eachi_row(1, fn(c, x) { row1[c] = x })
  inspect(row1, content="[1, 4]")
  let col1 = Array::make(3, 0)
  let mut ci = 0
  t.each_col(1, fn(x) {
    col1[ci] = x
    ci += 1
  })
  inspect(col1, content="[3, 4, 5]")
  let col0 = Array::make(3, 0)
  t.eachi_col(0, fn(r, x) { col0[r] = x })
  inspect(col0, content="[0, 1, 2]")
  let pairs = Array::make(6, 0)
  t.each_row_col(fn(r, c, v) { pairs[r * 2 + c] = v })
  inspect(pairs, content="[0, 3, 1, 4, 2, 5]")
}

///|
test "transpose_mapping_pure" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()

  // mapping (pure)
  inspect(
    t.map(fn(x) { x + 1 }),
    content=(
      #||1, 4|
      #||2, 5|
      #||3, 6|
    ),
  )

  // add_constant, scale
  inspect(
    t.add_constant(5),
    content=(
      #||5, 8|
      #||6, 9|
      #||7, 10|
    ),
  )
  inspect(
    t.scale(2),
    content=(
      #||0, 6|
      #||2, 8|
      #||4, 10|
    ),
  )
}

///|
test "transpose_mapping_inplace" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t_inplace = base.to_transpose()
  t_inplace.map_in_place(fn(x) { x * 2 })
  inspect(
    t_inplace,
    content=(
      #||0, 6|
      #||2, 8|
      #||4, 10|
    ),
  )
  t_inplace.map_col_in_place(1, fn(x) { x + 1 })
  inspect(
    t_inplace,
    content=(
      #||0, 7|
      #||2, 9|
      #||4, 11|
    ),
  )
  t_inplace.map_row_in_place(0, fn(x) { x - 1 })
  inspect(
    t_inplace,
    content=(
      #||-1, 6|
      #||2, 9|
      #||4, 11|
    ),
  )
}

///|
test "transpose_extraction" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()

  // row/col extraction
  inspect(t.row_to_array(2), content="[2, 5]")
  inspect(t.col_to_array(0), content="[0, 1, 2]")
  inspect(t.row_to_vector(1), content="|1, 4|")
  inspect(t.col_to_vector(1), content="|3, 4, 5|")
}

///|
test "transpose_structure" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()
  let other_same_shape = Matrix::from_2d_array([[10, 11, 12], [13, 14, 15]])
  let t_same = other_same_shape.to_transpose()

  // swap operations
  let t_swap = base.to_transpose()
  t_swap.swap_rows(0, 2)
  t_swap.swap_cols(0, 1)
  inspect(
    t_swap,
    content=(
      #||5, 2|
      #||4, 1|
      #||3, 0|
    ),
  )

  // combine operations
  inspect(
    t.horizontal_combine(t_same),
    content=(
      #||5, 2, 10, 13|
      #||4, 1, 11, 14|
      #||3, 0, 12, 15|
    ),
  )
  inspect(
    t.vertical_combine(t_same),
    content=(
      #||5, 2|
      #||4, 1|
      #||3, 0|
      #||10, 13|
      #||11, 14|
      #||12, 15|
    ),
  )
}

///|
test "transpose_conversion" {
  let base = Matrix::from_2d_array([[0, 1, 2], [3, 4, 5]])
  let t = base.to_transpose()

  // copy, transpose (unwrap), and materialize
  let t_copy = t.copy()
  inspect(t_copy, content="|0, 3|\n|1, 4|\n|2, 5|")
  inspect(
    t.transpose(),
    content=(
      #||0, 1, 2|
      #||3, 4, 5|
    ),
  )
  inspect(
    t.materialize(),
    content=(
      #||0, 3|
      #||1, 4|
      #||2, 5|
    ),
  )
}
