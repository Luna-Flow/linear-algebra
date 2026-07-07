///|
fn[T : Mul + Add + Zero] matmul_pure_impl(
  a : Matrix[T],
  b : Matrix[T],
) -> Matrix[T] {
  let row = a.row
  let col = b.col
  let inner = a.col
  ensure_mul_compatible(a, b)
  if row == 0 || col == 0 {
    return Matrix::make(row, col, fn(_, _) { abort("unreachable") })
  }
  if inner == 0 {
    return Matrix::new(row, col, T::zero())
  }
  let left_data = a.data
  let right_data = b.data
  let right_t = Vector::makei(col * inner, fn(idx) {
    let out_col = idx / inner
    let k = idx % inner
    right_data[k * col + out_col]
  })
  let data = Vector::makei(row * col, fn(i) {
    let r = i / col
    let c = i % col
    let left_offset = r * inner
    let right_offset = c * inner
    let mut sum = left_data[left_offset] * right_t[right_offset]
    for k in 1..<inner {
      sum = sum + left_data[left_offset + k] * right_t[right_offset + k]
    }
    sum
  })
  { row, col, data }
}
