///|
type Vector[A] Array[A]

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
impl[T : Show] Show for Vector[T] with output(self, l) {
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
pub fn Vector::left_scale[A : @internal.Mul](
  self : Vector[A],
  scalar : A
) -> Vector[A] {
  self.map(fn { x => x * scalar })
}

///|
pub fn Vector::right_scale[A : @internal.Mul](
  scalar : A,
  self : Vector[A]
) -> Vector[A] {
  self.map(fn { x => scalar * x })
}

///|
pub fn Vector::left_scale_inplace[A : @internal.Mul](
  self : Vector[A],
  scalar : A
) -> Unit {
  self.map_inplace(fn { x => x * scalar })
}

///|
pub fn Vector::right_scale_inplace[A : @internal.Mul](
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
pub fn Vector::op_add[T : @internal.Add](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_add)
}

///|
pub fn Vector::op_mul[T : @internal.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Vector[T] {
  self.zip_with(other, T::op_mul)
}

///|
pub fn lerp[T : @internal.One + @internal.Mul + @internal.Add + @internal.Neg](
  self : Vector[T],
  other : Vector[T],
  alpha : T
) -> Vector[T] {
  self.left_scale(T::one() + -alpha) + other.left_scale(alpha)
}

///|
pub fn scaled_matrix[T : @internal.Mul + @internal.Zero](
  self : Vector[T]
) -> Matrix[T] {
  let n = self.length()
  Matrix::make(n, n, fn(i, j) { if i == j { self[i] } else { T::zero() } })
}

///|
pub fn tensor_product[T : @internal.Mul](
  self : Vector[T],
  other : Vector[T]
) -> Matrix[T] {
  let n = self.length()
  let m = other.length()
  Matrix::make(n, m, fn(i, j) { self[i] * other[j] })
}

// ///|
// pub fn Vector::add_constant(self : Vector, constant : Double) -> Unit {
//   self.map_inplace(fn(x) -> Double { x + constant })
// }

// ///|
// pub fn Vector::ax_plus_by(
//   self : Vector,
//   y : Vector,
//   a : Double,
//   b : Double
// ) -> Vector {
//   let n = self.size
//   guard n == y.size
//   let stride_self = self.stride
//   let stride_y = y.stride
//   let vector_ax_plus_by = Vector::new(n)
//   for i = 0; i < n; i = i + 1 {
//     vector_ax_plus_by.data.push(
//       a * self.data[i * stride_self] + b * y.data[i * stride_y],
//     )
//   }
//   vector_ax_plus_by
// }

// ///|
// pub fn Vector::ax_plus_by_inplace(
//   self : Vector,
//   y : Vector,
//   a : Double,
//   b : Double
// ) -> Unit {
//   let n = self.size
//   guard n == y.size
//   let stride_self = self.stride
//   let stride_y = y.stride
//   for i = 0; i < n; i = i + 1 {
//     self.data[i * stride_self] = a * self.data[i * stride_self] +
//       b * y.data[i * stride_y]
//   }
// }

// ///|
// pub fn Vector::sum(self : Vector) -> Double {
//   @luna_utils.arr_sum(self.data)
// }

// ///|
// pub fn Vector::add_inplace(self : Vector, other : Vector) -> Unit {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     self.data[i * stride_self] = self.data[i * stride_self] +
//       other.data[i * stride_other]
//   }
// }

// ///|
// pub fn Vector::sub_inplace(self : Vector, other : Vector) -> Unit {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     self.data[i * stride_self] = self.data[i * stride_self] -
//       other.data[i * stride_other]
//   }
// }

// ///|
// pub fn Vector::mul_inplace(self : Vector, other : Vector) -> Unit {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     self.data[i * stride_self] = self.data[i * stride_self] *
//       other.data[i * stride_other]
//   }
// }

// ///|
// pub fn Vector::div_inplace(self : Vector, other : Vector) -> Unit {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     self.data[i * stride_self] = self.data[i * stride_self] /
//       other.data[i * stride_other]
//   }
// }

// ///|
// pub fn op_add(self : Vector, other : Vector) -> Vector {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   let vector_add = Vector::new(n)
//   for i = 0; i < n; i = i + 1 {
//     vector_add.data.push(
//       self.data[i * stride_self] + other.data[i * stride_other],
//     )
//   }
//   vector_add
// }

// ///|
// pub fn op_sub(self : Vector, other : Vector) -> Vector {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   let vector_sub = Vector::new(n)
//   for i = 0; i < n; i = i + 1 {
//     vector_sub.data.push(
//       self.data[i * stride_self] - other.data[i * stride_other],
//     )
//   }
//   vector_sub
// }

// ///|
// pub fn op_mul(self : Vector, other : Vector) -> Vector {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   let vector_mul = Vector::new(n)
//   for i = 0; i < n; i = i + 1 {
//     vector_mul.data.push(
//       self.data[i * stride_self] * other.data[i * stride_other],
//     )
//   }
//   vector_mul
// }

// ///|
// pub fn op_div(self : Vector, other : Vector) -> Vector {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   let vector_div = Vector::new(n)
//   for i = 0; i < n; i = i + 1 {
//     vector_div.data.push(
//       self.data[i * stride_self] / other.data[i * stride_other],
//     )
//   }
//   vector_div
// }

// //init
// ///|
// pub fn Vector::new(size : Int, stride~ : Int = 1) -> Vector {
//   guard size > 0 && stride > 0
//   let data = []
//   { data, size, stride }
// }

// ///|
// pub fn Vector::at(self : Vector, index : Int) -> Double {
//   guard index < self.size && index >= 0
//   self.data[index * self.stride]
// }

// ///|
// pub fn Vector::filled_vector(size : Int, num : Double) -> Vector {
//   let data = (fn() -> Array[Double] {
//     let filled_vector = []
//     for i = 0; i < size; i = i + 1 {
//       filled_vector.push(num)
//     }
//     filled_vector
//   })()
//   { data, size, stride: 1 }
// }

// ///|
// pub fn Vector::zero_vector(size : Int) -> Vector {
//   Vector::filled_vector(size, 0.0)
// }

// ///|
// pub fn op_get(self : Vector, index : Int) -> Double {
//   self.data[index * self.stride]
// }

// ///|
// pub fn Vector::set_all(self : Vector, num : Double) -> Unit {
//   self.map_inplace(fn(_) -> Double { num })
// }

// ///|
// pub fn Vector::set_zero(self : Vector) -> Unit {
//   self.set_all(0.0)
// }

// ///|
// pub fn Vector::set_at(self : Vector, index : Int, num : Double) -> Unit {
//   guard index < self.size && index >= 0
//   self.data[index * self.stride] = num
// }

// ///|
// pub fn Vector::set_basis(self : Vector, index : Int) -> Unit {
//   self.set_zero()
//   self.set_at(index, 1.0)
// }

// ///|
// pub fn Vector::copy(self : Vector) -> Vector {
//   let data = self.data.copy()
//   { data, size: self.size, stride: self.stride }
// }

// //prop

// ///|
// pub impl Eq for Vector with op_equal(self, other) {
//   let n = self.size
//   guard n == other.size
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     if self.data[i * stride_self] != other.data[i * stride_other] {
//       return false
//     }
//   }
//   true
// }

// ///|
// pub fn Vector::is_null(self : Vector) -> Bool {
//   let n = self.size
//   let stride = self.stride
//   for i = 0; i < n; i = i + 1 {
//     if self.data[i * stride] != 0.0 {
//       return false
//     }
//   }
//   true
// }

// ///|
// pub fn Vector::is_pos(self : Vector) -> Bool {
//   let n = self.size
//   let stride = self.stride
//   for i = 0; i < n; i = i + 1 {
//     if self.data[i * stride] <= 0.0 {
//       return false
//     }
//   }
//   true
// }

// ///|
// pub fn Vector::is_neg(self : Vector) -> Bool {
//   let n = self.size
//   let stride = self.stride
//   for i = 0; i < n; i = i + 1 {
//     if self.data[i * stride] >= 0.0 {
//       return false
//     }
//   }
//   true
// }

// ///|
// pub fn Vector::is_non_neg(self : Vector) -> Bool {
//   let n = self.size
//   let stride = self.stride
//   for i = 0; i < n; i = i + 1 {
//     if self.data[i * stride] < 0.0 {
//       return false
//     }
//   }
//   true
// }

// ///|
// pub fn Vector::swap(self : Vector, other : Vector) -> Unit {
//   let n = self.size
//   let m = other.size
//   guard n == m
//   let stride_self = self.stride
//   let stride_other = other.stride
//   for i = 0; i < n; i = i + 1 {
//     let temp = self.data[i * stride_self]
//     self.data[i * stride_self] = other.data[i * stride_other]
//     other.data[i * stride_other] = temp
//   }
// }

// ///|
// pub fn Vector::swap_elements(self : Vector, i : Int, j : Int) -> Unit {
//   guard i < self.size && j < self.size
//   let stride = self.stride
//   let temp = self.data[i * stride]
//   self.data[i * stride] = self.data[j * stride]
//   self.data[j * stride] = temp
// }

// ///|
// pub fn Vector::reverse(self : Vector) -> Unit {
//   let n = self.size
//   let stride = self.stride
//   let mut left = 0
//   let mut right = n - stride
//   while left < right {
//     let temp = self.data[left]
//     self.data[left] = self.data[right]
//     self.data[right] = temp
//     left = left + stride
//     right = right - stride
//   }
// }
