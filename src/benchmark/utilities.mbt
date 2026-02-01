///|
pub struct PRNG {
  mut seed : Int64
}

///|
/// Creates a new pseudo-random number generator with the specified seed.
///
/// Parameters:
///
/// * `seed` : The initial seed value used to initialize the random number
///   generator.
///
/// Returns a new `PRNG` instance initialized with the given seed.
pub fn PRNG::new(seed : Int64) -> PRNG {
  { seed, }
}

///|
pub fn PRNG::next(self : PRNG) -> Double {
  self.seed = self.seed * 6364136223846793005L + 1442695040888963407L
  let val = (self.seed >> 11).to_int().to_double() * (1.0 / 9007199254740992.0)
  if val < 0.0 {
    -val
  } else {
    val
  }
}
