///|
trait Mul {
  op_mul(Self, Self) -> Self
}

///|
trait Add {
  op_add(Self, Self) -> Self
}

///|
trait Neg {
  op_neg(Self) -> Self
}

///|
trait One {
  one() -> Self
}

///|
trait Zero {
  zero() -> Self
}

///|
trait Conjugate {
  conjugate(Self) -> Self
}
