///|
/// Operation-level approximate equality capability.
///
/// This trait states that an approximate comparison operation is available. It
/// does not claim exact equality laws.
pub(open) trait ApproxEq {
  fn approx_eq(Self, Self) -> Bool
}

///|
/// Operation-level absolute-value capability.
///
/// Built-in numeric types often expose this through `@luna-generic.Num`; this
/// trait keeps the operation available without implying broader algebraic laws.
pub(open) trait Abs {
  fn abs(Self) -> Self
}

///|
/// Checked division capability using a value-level operation name aligned with
/// the architecture documentation.
pub(open) trait CheckedDiv {
  fn checked_div(Self, Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}

///|
/// Checked square-root capability using a value-level operation name aligned
/// with the architecture documentation.
pub(open) trait CheckedSqrt {
  fn checked_sqrt(Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}

///|
/// Checked comparison capability using a value-level operation name aligned
/// with the architecture documentation.
pub(open) trait CheckedCompare {
  fn checked_compare(Self, Self) -> Result[Int, ArithmeticError]
}

///|
pub impl ApproxEq for Float with fn approx_eq(a, b) {
  (a - b).abs() <= 1.0e-6
}

///|
pub impl ApproxEq for Double with fn approx_eq(a, b) {
  (a - b).abs() <= 1.0e-12
}

///|
pub impl ApproxEq for Int with fn approx_eq(a, b) {
  a == b
}

///|
pub impl Abs for Float with fn abs(self) {
  @generic.Num::abs(self)
}

///|
pub impl Abs for Double with fn abs(self) {
  @generic.Num::abs(self)
}

///|
pub impl Abs for Int with fn abs(self) {
  @generic.Num::abs(self)
}

///|
pub impl CheckedDiv for Float with fn checked_div(a, b, context) {
  DivChecked::div_checked(a, b, context)
}

///|
pub impl CheckedDiv for Double with fn checked_div(a, b, context) {
  DivChecked::div_checked(a, b, context)
}

///|
pub impl CheckedSqrt for Float with fn checked_sqrt(a, context) {
  SqrtChecked::sqrt_checked(a, context)
}

///|
pub impl CheckedSqrt for Double with fn checked_sqrt(a, context) {
  SqrtChecked::sqrt_checked(a, context)
}

///|
pub impl CheckedCompare for Float with fn checked_compare(a, b) {
  CompareChecked::compare_checked(a, b)
}

///|
pub impl CheckedCompare for Double with fn checked_compare(a, b) {
  CompareChecked::compare_checked(a, b)
}
