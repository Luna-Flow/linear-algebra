///|
type Vector[A] Array[A]

///|
impl[T : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Vector[T] with arbitrary(
  size,
  rng
) {
  Vector::makei(size, fn { i => T::arbitrary(i, rng) })
}

///|
impl[T : Eq] Eq for Vector[T] with op_equal(self, other) {
  self._ == other._
}

///|
pub impl[T : Show] Show for Vector[T] with to_string(self) {
  let sep = ", "
  "|\{self._.map(T::to_string).join(sep)}|"
}

///|
pub impl[T : Show] Show for Vector[T] with output(self, l) {
  l.write_string(self.to_string())
}

///|
fn array_zip_with[A, B, C](
  a1 : Array[A],
  a2 : Array[B],
  f : (A, B) -> C
) -> Array[C] {
  let n = a1.length()
  guard n == a2.length()
  let result = Array::makei(n, fn { i => f(a1[i], a2[i]) })
  result
}

///|
pub fn Vector::zip_with[A, U, V](
  self : Vector[A],
  other : Vector[U],
  f : (A, U) -> V
) -> Vector[V] {
  array_zip_with(self._, other._, f)
}

///|
pub fn to_col_matrix[T](self : Vector[T]) -> Matrix[T] {
  Matrix::make(self.length(), 1, fn(i, _) { self[i] })
}

///|
pub fn to_row_matrix[T](self : Vector[T]) -> Matrix[T] {
  { data: self._, row: 1, col: self.length() }
}

///|
pub fn Vector::length[A](self : Vector[A]) -> Int {
  self._.length()
}

///|
pub fn Vector::makei[A](n : Int, f : (Int) -> A) -> Vector[A] {
  Array::makei(n, f)
}

///|
pub fn Vector::make[A](n : Int, elem : A) -> Vector[A] {
  Array::make(n, elem)
}

///|
pub fn Vector::copy[A](self : Vector[A]) -> Vector[A] {
  self._.copy()
}

///|
pub fn Vector::op_get[A](self : Vector[A], index : Int) -> A {
  self._[index]
}

///|
pub fn Vector::op_set[A](self : Vector[A], index : Int, value : A) -> Unit {
  self._[index] = value
}

///|
pub fn Vector::map[A, B](self : Vector[A], f : (A) -> B) -> Vector[B] {
  self._.map(f)
}

///|
pub fn Vector::map_inplace[A](self : Vector[A], f : (A) -> A) -> Unit {
  self._.map_inplace(f)
}

///|
pub fn Vector::left_scale[A : @lg.Mul](
  self : Vector[A],
  scalar : A
) -> Vector[A] {
  self.map(fn { x => x * scalar })
}

///|
pub fn Vector::right_scale[A : @lg.Mul](
  scalar : A,
  self : Vector[A]
) -> Vector[A] {
  self.map(fn { x => scalar * x })
}

///|
pub fn Vector::left_scale_inplace[A : @lg.Mul](
  self : Vector[A],
  scalar : A
) -> Unit {
  self.map_inplace(fn { x => x * scalar })
}

///|
pub fn Vector::right_scale_inplace[A : @lg.Mul](
  scalar : A,
  self : Vector[A]
) -> Unit {
  self.map_inplace(fn { x => scalar * x })
}

///|
pub fn Vector::from_array[T](a : Array[T]) -> Vector[T] {
  a
}

///|
pub fn Vector::op_add[T : @lg.Add](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_add)
}

///|
test "a + a = 2 * a" {
  fn prop(v : Vector[Int]) {
    v + v == v.left_scale(2)
  }

  @qc.quick_check_fn!(prop)
}

///|
test "a + b = b + a" {
  fn prop(a : Vector[Int], b) {
    a + b == b + a
  }

  @qc.quick_check_fn!(fn {
    ((a : Vector[Int]), (b : Vector[Int])) => {
      guard a.length() == b.length() else { true }
      prop(a, b)
    }
  })
}

///|
pub fn Vector::op_mul[T : @lg.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_mul)
}

///|
test "a * b * c = a * (b * c)" {
  fn prop(a : Vector[Int], b, c) {
    a * b * c == a * (b * c)
  }

  @qc.quick_check_fn!(fn {
    ((a : Vector[Int]), (b : Vector[Int]), (c : Vector[Int])) => {
      guard a.length() == b.length() && b.length() == c.length() else { true }
      prop(a, b, c)
    }
  })
}

///|
pub fn Vector::op_neg[T : @lg.Neg](self : Vector[T]) -> Vector[T] {
  self.map(T::op_neg)
}

///|
pub fn lerp[T : @lg.One + @lg.Mul + @lg.Add + @lg.Neg](
  self : Vector[T],
  other : Vector[T],
  alpha : T
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
pub fn scaled_matrix[T : @lg.Mul + @lg.Zero](self : Vector[T]) -> Matrix[T] {
  let n = self.length()
  Matrix::make(n, n, fn(i, j) { if i == j { self[i] } else { T::zero() } })
}

///|
test "S_v * p = v * p" {
  fn prop(v : Vector[Int], p : Vector[Int]) {
    let m = v.scaled_matrix()
    m * p.to_col_matrix() == (v * p).to_col_matrix()
  }

  @qc.quick_check_fn!(fn {
    ((a : Vector[Int]), (b : Vector[Int])) => {
      guard a.length() == b.length() else { true }
      prop(a, b)
    }
  })
}

///|
pub fn tensor_product[T : @lg.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Matrix[T] {
  let n = self.length()
  let m = other.length()
  Matrix::make(n, m, fn(i, j) { self[i] * other[j] })
}

///|
pub fn Vector::add_constant[T : @lg.Add](
  self : Vector[T],
  cst : T
) -> Vector[T] {
  self.map(fn(x) { x + cst })
}

///|
pub fn lin_comb[T : @lg.Add + @lg.Mul](
  scalar_a : T,
  self : Vector[T],
  scalar_b : T,
  other : Vector[T]
) -> Vector[T] {
  self.left_scale(scalar_a) + other.left_scale(scalar_b)
}
