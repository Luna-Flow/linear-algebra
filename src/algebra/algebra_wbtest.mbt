///|
struct ScalarMatrix {
  value : Int
}

///|
impl MatrixShape for ScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl TransposeMatrix for ScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for ScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for ScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for ScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for ScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl AdditiveMatrix for ScalarMatrix

///|
impl MatMulMatrix for ScalarMatrix

///|
fn[T : MatMulMatrix] gram_step(matrix : T) -> T {
  matrix.transpose() * matrix
}

///|
test "algebra traits stay focused on linear-algebra structure" {
  let matrix : ScalarMatrix = { value: 3 }
  inspect(gram_step(matrix).value, content="9")
}
