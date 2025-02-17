///|
pub trait Mul {
  op_mul(Self, Self) -> Self
}

///|
pub trait Add {
  op_add(Self, Self) -> Self
}

///|
pub trait Neg {
  op_neg(Self) -> Self
}

///|
pub trait One {
  one() -> Self
}

///|
pub trait Zero {
  zero() -> Self
}

///|
pub trait Conjugate {
  conjugate(Self) -> Self
}

///|
pub impl Mul for Int with op_mul(a, b) -> Int {
  a * b
}

///|
pub impl Add for Int with op_add(a, b) -> Int {
  a + b
}

///|
pub impl Neg for Int with op_neg(a) -> Int {
  -a
}

///|
pub impl One for Int with one() -> Int {
  1
}

///|
pub impl Zero for Int with zero() -> Int {
  0
}

///|
pub impl Mul for Double with op_mul(a, b) -> Double {
  a * b
}

///|
pub impl Add for Double with op_add(a, b) -> Double {
  a + b
}

///|
pub impl Neg for Double with op_neg(a) -> Double {
  -a
}

///|
pub impl One for Double with one() -> Double {
  1.0
}

///|
pub impl Zero for Double with zero() -> Double {
  0.0
}

///|
pub impl Mul for Complex with op_mul(a, b) -> Complex {
  a * b
}

///|
pub impl Add for Complex with op_add(a, b) -> Complex {
  a + b
}

///|
pub impl Neg for Complex with op_neg(a) -> Complex {
  -a
}

///|
pub impl One for Complex with one() -> Complex {
  Complex::new(1.0, 0.0)
}

///|
pub impl Zero for Complex with zero() -> Complex {
  Complex::new(0.0, 0.0)
}

///|
pub impl Conjugate for Complex with conjugate(a) -> Complex {
  a.conjugate()
}
