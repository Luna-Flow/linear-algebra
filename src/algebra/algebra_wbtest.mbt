///|
fn[T : Semiring] require_semiring(value : T) -> T {
  value + T::zero()
}

///|
fn[T : FloatingScalarOps] require_floating_scalar_ops(value : T) -> T {
  value / T::one()
}

///|
test "algebra traits compose existing scalar capabilities" {
  inspect(require_semiring(3), content="3")
  inspect(require_floating_scalar_ops(2.0), content="2")
}
