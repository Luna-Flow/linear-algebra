///|
test "scalar operation traits are available" {
  inspect(ApproxEq::approx_eq(1.0F, 1.0F + 1.0e-7F), content="true")
  inspect(ApproxEq::approx_eq(1.0, 1.0 + 1.0e-13), content="true")
  inspect(ApproxEq::approx_eq(1, 1), content="true")
  inspect(Abs::abs(-3), content="3")
}
