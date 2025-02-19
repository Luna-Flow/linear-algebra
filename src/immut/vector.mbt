///|
struct Vector[T] {
  data : IArray[T]
}

///|
pub fn Vector::map[T, U](self : Vector[T], f : (T) -> U) -> Vector[U] {
  Vector::{ data: self.data.map(f) }
}

///|
pub fn Vector::zip_with[T, U, V](
  self : Vector[T],
  other : Vector[U],
  f : (T, U) -> V
) -> Vector[V] {
  Vector::{ data: array_zip_with(self.data, other.data, f) }
}

///|
pub fn Vector::makei[T](n : Int, f : (Int) -> T) -> Vector[T] {
  Vector::{ data: @immut/array.makei(n, f) }
}

///|
pub fn Vector::make[T](n : Int, elem : T) -> Vector[T] {
  Vector::{ data: @immut/array.make(n, elem) }
}

///|
pub fn Vector::length[T](self : Vector[T]) -> Int {
  self.data.length()
}

///|
pub fn Vector::op_get[T](self : Vector[T], i : Int) -> T {
  self.data[i]
}

///|
pub fn Vector::set[T](self : Vector[T], i : Int, x : T) -> Vector[T] {
  Vector::{ data: self.data.set(i, x) }
}

///|
pub fn left_scale[T : @luna_generic.Mul](
  self : Vector[T],
  scalar : T
) -> Vector[T] {
  self.map(fn { x => x * scalar })
}

///|
pub fn right_scale[T : @luna_generic.Mul](
  self : Vector[T],
  scalar : T
) -> Vector[T] {
  self.map(fn { x => scalar * x })
}

///|
pub fn Vector::from_array[T](arr : Array[T]) -> Vector[T] {
  Vector::{ data: @immut/array.from_array(arr) }
}

///|
pub fn Vector::op_add[T : @luna_generic.Add](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_add)
}

///|
pub fn Vector::op_mul[T : @luna_generic.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_mul)
}

///| Linearly interpolate between two vectors
pub fn lerp[T : @luna_generic.One + @luna_generic.Mul + @luna_generic.Add + @luna_generic.Neg](
  self : Vector[T],
  other : Vector[T],
  alpha : T
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
impl[T : Show] Show for Vector[T] with to_string(self) {
  let mut re = ""
  for i = 0; i < self.length(); i = i + 1 {
    re = re + self[i].to_string()
    if i < self.length() - 1 {
      re = re + ", "
    }
  }
  "|\{re}|"
}

///|
impl[T : Show] Show for Vector[T] with output(s, l) {
  l.write_string(s.to_string())
}

///| Produce a diagonal (scale) matrix from a vector
pub fn scaled_matrix[T : @luna_generic.Mul + @luna_generic.Zero](
  self : Vector[T]
) -> Matrix[T] {
  let n = self.length()
  Matrix::make(n, n, fn(i, j) { if i == j { self[i] } else { T::zero() } })
}

///| Tensor product of two vectors
pub fn tensor_product[T : @luna_generic.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Matrix[T] {
  let n = self.length()
  let m = other.length()
  Matrix::make(n, m, fn(i, j) { self[i] * other[j] })
}

///| utils

///|
fn array_zip_with[X, Y, Z](
  a1 : IArray[X],
  a2 : IArray[Y],
  f : (X, Y) -> Z
) -> IArray[Z] {
  let n = a1.length()
  guard n == a2.length()
  let result = @immut/array.makei(n, fn { i => f(a1[i], a2[i]) })
  result
}

///|
test {
  let v1 = Vector::from_array([1, 2, 3])
  let v2 = Vector::from_array([4, 5, 6])
  inspect!(v1 + v2, content="|5, 7, 9|")
  inspect!(v1 * v2, content="|4, 10, 18|")
  inspect!(v1.left_scale(10), content="|10, 20, 30|")
  inspect!(v2.right_scale(10), content="|40, 50, 60|")
  inspect!(
    v1.scaled_matrix(),
    content=
      #||1, 0, 0|
      #||0, 2, 0|
      #||0, 0, 3|
    ,
  )
  inspect!(
    tensor_product(v1, v2),
    content=
      #||4, 5, 6|
      #||8, 10, 12|
      #||12, 15, 18|
    ,
  )
  inspect!(v2.set(1, 10), content="|4, 10, 6|")
}
