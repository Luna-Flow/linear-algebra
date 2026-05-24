///|
using @lg {
  trait One,
  trait Zero,
  trait Conjugate,
  trait Semiring,
  trait Num,
}

///|
using @qc_core {trait Arbitrary}

///|
using @debug {trait Debug, type Repr}

///|
using @internal {
  trait HasShape,
  ensure_mul_compatible,
  ensure_square,
}
