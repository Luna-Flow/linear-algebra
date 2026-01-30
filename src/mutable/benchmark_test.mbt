///|
/// A simple Linear Congruential Generator (LCG) for deterministic randomness.
/// This ensures our benchmarks run on the exact same data every time, allowing
/// for fair comparison across languages (MoonBit vs Node.js) and implementations.
///
/// Constants are taken from Knuth (MMIX).
struct PRNG {
  mut seed : Int64
}

///|
fn PRNG::new(seed : Int64) -> PRNG {
  { seed, }
}

///|
/// Generates the next random Double in range [0.0, 1.0).
fn PRNG::next(self : PRNG) -> Double {
  self.seed = self.seed * 6364136223846793005L + 1442695040888963407L
  // Convert top 53 bits to double for [0, 1) range
  let val = (self.seed >> 11).to_int().to_double() * (1.0 / 9007199254740992.0)
  if val < 0.0 {
    -val
  } else {
    val
  }
}

///|
/// Baseline A: Native Array Implementation
/// This implementation uses a flattened 1D array and the cache-friendly loop order (i-k-j).
/// It represents the "Physical Limit" (Speed of Light) for Matrix Multiplication in MoonBit
/// on the current backend, without the overhead of the Matrix struct or Lens abstractions.
fn benchmark_native_array_mul(
  n : Int,
  a : Array[Double],
  b : Array[Double],
) -> Array[Double] {
  // Fixed Native Implementation Strategy (Golden Standard):
  // Small Scale (N <= 64): i-j-k with Hoisting.
  if n <= 64 {
    let c = Array::make(n * n, 0.0)
    for i = 0; i < n; i = i + 1 {
      let row_offset = i * n // c[i][...] and a[i][...]
      for j = 0; j < n; j = j + 1 {
        let mut sum = 0.0
        for k = 0; k < n; k = k + 1 {
          // c[i][j] = sum(a[i][k] * b[k][j])
          sum = sum + a[row_offset + k] * b[k * n + j]
        }
        c[row_offset + j] = sum
      }
    }
    c
  } else {
    // Large Scale (N > 64): i-k-j for cache locality.
    let c = Array::make(n * n, 0.0)
    for i = 0; i < n; i = i + 1 {
      for k = 0; k < n; k = k + 1 {
        let r = a[i * n + k] // a[i][k]
        for j = 0; j < n; j = j + 1 {
          let idx_c = i * n + j // c[i][j]
          let idx_b = k * n + j // b[k][j]
          c[idx_c] = c[idx_c] + r * b[idx_b]
        }
      }
    }
    c
  }
}

///|
/// Baseline B: Native Vector Dot Product
fn benchmark_native_vector_dot(a : Array[Double], b : Array[Double]) -> Double {
  let len = a.length()
  let mut sum = 0.0
  for i = 0; i < len; i = i + 1 {
    // Pure array access without any abstraction overhead.
    sum = sum + a[i] * b[i]
  }
  sum
}

///|
/// Benchmarking 16x16 Matrices (Small Scale - Abstraction Overhead)
test "bench_granular_steps" {
  let steps = [8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 128]
  for n in steps {
    let bench = @bench.Bench::new()
    let rng = PRNG::new(42L)
    let size = n * n
    let arr_a = Array::makei(size, fn(_i) { rng.next() })
    let arr_b = Array::makei(size, fn(_i) { rng.next() })
    let mat_a = Matrix::from_array(n, n, arr_a)
    let mat_b = Matrix::from_array(n, n, arr_b)
    bench.bench(
      fn() { ignore(benchmark_native_array_mul(n, arr_a, arr_b)) },
      name="Native (\{n}x\{n})",
    )
    bench.bench(fn() { ignore(mat_a * mat_b) }, name="Library (\{n}x\{n})")
    println(bench.dump_summaries())
  }
}

///|
test "bench_vector_dot" {
  let n = 1000
  let rng = PRNG::new(42L)
  let arr1 = Array::makei(n, fn(_i) { rng.next() })
  let arr2 = Array::makei(n, fn(_i) { rng.next() })
  let v1 = Vector::from_array(arr1)
  let v2 = Vector::from_array(arr2)
  let bench = @bench.Bench::new()
  bench.bench(
    fn() { ignore(benchmark_native_vector_dot(arr1, arr2)) },
    name="Native Dot (1000)",
  )
  bench.bench(fn() { ignore(v1.dot(v2)) }, name="Library Dot (1000)")
  println(bench.dump_summaries())
}

///|
test "bench_transpose_mul" {
  let n = 64
  let rng = PRNG::new(42L)
  let arr1 = Array::makei(n * n, fn(_i) { rng.next() })
  let arr2 = Array::makei(n * n, fn(_i) { rng.next() })
  let m1 = Matrix::from_array(n, n, arr1)
  let m2 = Matrix::from_array(n, n, arr2)
  let t1 = m1.to_transpose()
  let t2 = m2.to_transpose()
  let bench = @bench.Bench::new()
  bench.bench(
    fn() { ignore(benchmark_native_array_mul(n, arr2, arr1)) },
    name="Native Transpose Mul (64x64)",
  )
  bench.bench(fn() { ignore(t1 * t2) }, name="Library Transpose Mul (64x64)")
  println(bench.dump_summaries())
}
