///|
struct ExactScalar(Int) derive(Eq, Compare)

///|
pub extend ExactScalar with Eq::{equal, not_equal}

///|
pub extend ExactScalar with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
impl Add for ExactScalar with fn add(a, b) {
  ExactScalar(a.0 + b.0)
}

///|
impl Sub for ExactScalar with fn sub(a, b) {
  ExactScalar(a.0 - b.0)
}

///|
impl Neg for ExactScalar with fn neg(a) {
  ExactScalar(-a.0)
}

///|
impl Mul for ExactScalar with fn mul(a, b) {
  ExactScalar(a.0 * b.0)
}

///|
impl Div for ExactScalar with fn div(a, b) {
  ExactScalar(a.0 / b.0)
}

///|
impl @lf_alg.Zero for ExactScalar with fn zero() {
  ExactScalar(0)
}

///|
impl @lf_alg.One for ExactScalar with fn one() {
  ExactScalar(1)
}

///|
impl @lf_alg.AddMonoid for ExactScalar

///|
impl @lf_alg.MulMonoid for ExactScalar

///|
impl @lf_alg.Semiring for ExactScalar

///|
impl @lf_alg.Ring for ExactScalar

///|
impl @lf_alg.Num for ExactScalar with fn abs(a) {
  ExactScalar(a.0.abs())
}

///|
impl @lf_alg.Num for ExactScalar with fn signum(a) {
  ExactScalar(if a.0 > 0 { 1 } else if a.0 < 0 { -1 } else { 0 })
}

///|
impl @immut.DeterminantScalar for ExactScalar with fn determinant_algorithm() {
  @immut.Bareiss
}

///|
fn[T : @immut.DeterminantScalar] generic_determinant(
  matrix : @immut.Matrix[T],
) -> T {
  matrix.determinant().unwrap()
}

///|
test "custom scalar strategy is implementable outside immut" {
  let matrix = @immut.Matrix::make(5, 5, fn(i, j) {
    ExactScalar(if i == j { 2 } else if (i - j).abs() == 1 { -1 } else { 0 })
  })
  assert_eq(generic_determinant(matrix).0, 6)
}
