///|
/// The elimination strategy selected by a determinant scalar.
pub(all) enum DeterminantAlgorithm {
  Bareiss
  PivotedLU
}

///|
/// Selects an algorithm appropriate to the scalar's division semantics.
/// Bareiss requires a commutative integral domain and exact division of
/// divisible values, with no intermediate overflow. PivotedLU requires
/// field-like division and may round, overflow, or underflow.
pub(open) trait DeterminantScalar: Compare + Num + Div {
  fn determinant_algorithm() -> DeterminantAlgorithm
  fn determinant_product(Array[Self]) -> Self = _
}

///|
pub impl DeterminantScalar for Int with fn determinant_algorithm() {
  Bareiss
}

///|
pub impl DeterminantScalar for Int16 with fn determinant_algorithm() {
  Bareiss
}

///|
pub impl DeterminantScalar for Int64 with fn determinant_algorithm() {
  Bareiss
}

///|
pub impl DeterminantScalar for BigInt with fn determinant_algorithm() {
  Bareiss
}

///|
pub impl DeterminantScalar for Double with fn determinant_algorithm() {
  PivotedLU
}

///|
pub impl DeterminantScalar for Float with fn determinant_algorithm() {
  PivotedLU
}

///|
/// Default for custom scalars: multiply in their native arithmetic.
impl DeterminantScalar with fn determinant_product(pivots) {
  let mut product = One::one()
  for pivot in pivots {
    product = product * pivot
  }
  product
}

///|
pub impl DeterminantScalar for Double with fn determinant_product(pivots) {
  let (mantissa, exponent) = normalized_pivot_product(pivots)
  @math.scalbn(mantissa, exponent)
}

///|
pub impl DeterminantScalar for Float with fn determinant_product(pivots) {
  let (mantissa, exponent) = normalized_pivot_product(pivots)
  @math.scalbnf(mantissa, exponent)
}

///|
/// Finite nonzero pivots and the running product stay in [0.5, 1) in
/// magnitude. Powers of two are exact until the final scalbn rounding.
/// Zero and nonfinite values bypass normalization and use scalar arithmetic.
fn[T : Compare + Num + Div] normalized_pivot_product(
  pivots : Array[T],
) -> (T, Int) {
  let one = One::one()
  let two = one + one
  let half = one / two
  let zero = Zero::zero()
  let mut product = one
  let mut exponent = 0
  for pivot in pivots {
    if pivot == zero || pivot / pivot != pivot / pivot {
      product = product * pivot
      continue
    }
    let mut mantissa = pivot
    let mut magnitude = Num::abs(mantissa)
    while magnitude >= one {
      mantissa = mantissa / two
      magnitude = Num::abs(mantissa)
      exponent += 1
    }
    while magnitude < half {
      mantissa = mantissa * two
      magnitude = Num::abs(mantissa)
      exponent -= 1
    }
    product = product * mantissa
    if product != zero && product / product == product / product {
      if Num::abs(product) < half {
        product = product * two
        exponent -= 1
      }
    }
  }
  (product, exponent)
}

///|
/// Eliminates on a private copy. No tolerance is used: zero pivots indicate
/// singularity of the computed factorization, not a numerical-rank policy.
fn[T : DeterminantScalar] Matrix::determinant_lu(self : Matrix[T]) -> T {
  let n = self.row
  let work = self.to_array()
  // Scan before any zero-column shortcut so a NaN anywhere is propagated.
  for value in work {
    if value != value {
      return value
    }
  }
  let pivots : Array[T] = []
  let mut sign = One::one()
  for k in 0..<n {
    let mut pivot_row = k
    let mut pivot_abs = Num::abs(work[k * n + k])
    for i in (k + 1)..<n {
      let candidate = Num::abs(work[i * n + k])
      if candidate != candidate || candidate > pivot_abs {
        pivot_abs = candidate
        pivot_row = i
      }
    }
    if pivot_row != k {
      swap_dense_rows(work, n, pivot_row, k)
      sign = -sign
    }
    let pivot = work[k * n + k]
    pivots.push(pivot)
    if pivot == Zero::zero() {
      // Keep later pivots, including infinity: zero * infinity is NaN.
      continue
    }
    for i in (k + 1)..<n {
      let factor = work[i * n + k] / pivot
      work[i * n + k] = Zero::zero()
      for j in (k + 1)..<n {
        let index = i * n + j
        work[index] = work[index] - factor * work[k * n + j]
      }
    }
  }
  sign * T::determinant_product(pivots)
}
