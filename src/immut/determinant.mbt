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
/// Eliminates on a private copy. No tolerance is used: zero pivots indicate
/// singularity of the computed factorization, not a numerical-rank policy.
fn[T : Compare + Num + Div] Matrix::determinant_lu(self : Matrix[T]) -> T {
  let n = self.row
  let work = self.to_array()
  let mut has_nonfinite = false
  for value in work {
    let zero = Zero::zero()
    if value != value || (value != zero && value / value != value / value) {
      has_nonfinite = true
    }
  }
  if has_nonfinite {
    return determinant_lu_direct(work, n)
  }
  let one = One::one()
  let two = one + one
  let half = one / two
  let mut determinant = One::one()
  let mut exponent = 0
  for k in 0..<n {
    let mut pivot_row = k
    let mut pivot_abs = Num::abs(work[k * n + k])
    for i in (k + 1)..<n {
      let candidate = Num::abs(work[i * n + k])
      if candidate > pivot_abs {
        pivot_abs = candidate
        pivot_row = i
      }
    }
    if work[pivot_row * n + k] == Zero::zero() {
      return determinant * Zero::zero()
    }
    if pivot_row != k {
      swap_dense_rows(work, n, pivot_row, k)
      determinant = -determinant
    }
    let pivot = work[k * n + k]
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
    determinant = determinant * mantissa
    let mut determinant_magnitude = Num::abs(determinant)
    while determinant_magnitude >= one {
      determinant = determinant / two
      determinant_magnitude = Num::abs(determinant)
      exponent += 1
    }
    while determinant_magnitude < half {
      determinant = determinant * two
      determinant_magnitude = Num::abs(determinant)
      exponent -= 1
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
  if exponent >= 0 {
    for _ in 0..<exponent {
      determinant = determinant * two
    }
  } else {
    for _ in 0..<-exponent {
      determinant = determinant / two
    }
  }
  determinant
}

///|
/// Preserve the scalar's native NaN and infinity behavior.
fn[T : Compare + Num + Div] determinant_lu_direct(
  work : Array[T],
  n : Int,
) -> T {
  let mut determinant = One::one()
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
    let pivot = work[pivot_row * n + k]
    if pivot == Zero::zero() {
      return determinant * pivot
    }
    if pivot_row != k {
      swap_dense_rows(work, n, pivot_row, k)
      determinant = -determinant
    }
    let pivot = work[k * n + k]
    determinant = determinant * pivot
    for i in (k + 1)..<n {
      let factor = work[i * n + k] / pivot
      work[i * n + k] = Zero::zero()
      for j in (k + 1)..<n {
        let index = i * n + j
        work[index] = work[index] - factor * work[k * n + j]
      }
    }
  }
  determinant
}
