# `linear-algebra/algebra`

本页记录当前 `0.4.7` 仓库中 `Luna-Flow/linear-algebra/algebra` 的公开 API 基线。

## 实验状态

`algebra` 是实验性功能。它已经可以用于后端接入试验和收集反馈，但 trait 层级、
父 trait 要求、运算符承诺和函数签名在稳定前仍可能发生不兼容变更。下游库应只依赖
实际需要的最小能力，暂时不要把这个包重新导出为承诺兼容性稳定的公开边界。

## 职责

`algebra` 拥有线性代数结构 traits。后端包为自己的具体数据类型实现这些 traits。这里的 traits 按最小能力拆分，避免泛型算法无意依赖 Hadamard 乘法、矩阵乘法或精确浮点域公理。

外部类型作者应先阅读[生态接入指南](./integration.md)，选择最小有效 trait 层级并确认
相应的运算符承诺。

## 项目配置

`algebra` 只负责结构层。如果你的代码还要直接使用共享的上游标量抽象，把这些依赖一起加上：

```sh
moon add Luna-Flow/linear-algebra@0.4.7
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推荐的 `moon.pkg` 导入写法：

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

`@algebra` 用来引用线性代数结构 traits；如果代码还需要共享的上游抽象，再直接导入 `@lf_alg` 和 `@lf_arith`。

## Matrix Shape Traits

```moonbit check
///|
struct ToyMatrix {
  rows : Int
  cols : Int
}

///|
struct ToyVector {
  size : Int
}

///|
impl @algebra.MatrixShape for ToyMatrix with fn shape(self) {
  (self.rows, self.cols)
}

///|
impl @algebra.VectorShape for ToyVector with fn length(self) {
  self.size
}

///|
test "shape traits report dimensions" {
  let matrix : ToyMatrix = { rows: 2, cols: 3 }
  let vector : ToyVector = { size: 4 }
  let (rows, cols) = @algebra.MatrixShape::shape(matrix)
  inspect(rows, content="2")
  inspect(cols, content="3")
  inspect(@algebra.VectorShape::length(vector), content="4")
}
```

`MatrixShape` 表示可观测二维形状的对象；`VectorShape` 表示可观测长度的向量式对象。它们不声明任何代数运算。

## `AdditiveVector`

```moonbit check
///|
struct AddVec {
  value : Int
}

///|
impl @algebra.VectorShape for AddVec with fn length(_) {
  1
}

///|
impl Add for AddVec with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for AddVec with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for AddVec with fn sub(left, right) {
  left + -right
}

///|
impl @algebra.AdditiveVector for AddVec

///|
fn[T : @algebra.AdditiveVector] add_vectors(left : T, right : T) -> T {
  left + right
}

///|
test "AdditiveVector packages vector addition and subtraction" {
  let left : AddVec = { value: 7 }
  let right : AddVec = { value: 2 }
  inspect(add_vectors(left, right).value, content="9")
  inspect(add_vectors(left, -right).value, content="5")
}
```

表示具有加法线性结构的向量式对象。它不要求逐元素乘法、内积、范数或全局零元。

只有算法确实需要 Hadamard 乘法时，才引入这个更强的 trait：

```moonbit check
///|
struct MulVec {
  value : Int
}

///|
impl @algebra.VectorShape for MulVec with fn length(_) {
  1
}

///|
impl Add for MulVec with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for MulVec with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for MulVec with fn sub(left, right) {
  left + -right
}

///|
impl Mul for MulVec with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveVector for MulVec

///|
impl @algebra.VecMulVector for MulVec

///|
fn[T : @algebra.VecMulVector] hadamard_product(left : T, right : T) -> T {
  left * right
}

///|
test "VecMulVector adds element-wise multiplication" {
  let left : MulVec = { value: 3 }
  let right : MulVec = { value: 4 }
  inspect(hadamard_product(left, right).value, content="12")
}
```

## `TransposeMatrix`

```moonbit check
///|
struct Flip2x2 {
  a11 : Int
  a12 : Int
  a21 : Int
  a22 : Int
}

///|
impl @algebra.MatrixShape for Flip2x2 with fn shape(_) {
  (2, 2)
}

///|
impl @algebra.TransposeMatrix for Flip2x2 with fn transpose(self) {
  { a11: self.a11, a12: self.a21, a21: self.a12, a22: self.a22 }
}

///|
test "TransposeMatrix keeps shape and swaps off-diagonal entries" {
  let matrix : Flip2x2 = { a11: 1, a12: 2, a21: 3, a22: 4 }
  let transposed = @algebra.TransposeMatrix::transpose(matrix)
  let (rows, cols) = @algebra.MatrixShape::shape(transposed)
  inspect(rows, content="2")
  inspect(cols, content="2")
  inspect(transposed.a12, content="3")
  inspect(transposed.a21, content="2")
}
```

表示具有可观测形状和同类型转置操作的矩阵式对象。它不要求矩阵乘法，因为动态矩形矩阵乘法只在运行时形状兼容时才有定义。该 trait 也不要求稠密表示、连续存储、直接索引或可变操作。

只有算法确实需要额外运算时，才继续使用更强的 traits：

```moonbit check
///|
struct ScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for ScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for ScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for ScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for ScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for ScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for ScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveMatrix for ScalarMatrix

///|
impl @algebra.MatMulMatrix for ScalarMatrix

///|
fn[T : @algebra.MatMulMatrix] multiply_matrices(left : T, right : T) -> T {
  left * right
}

///|
test "matrix additive and multiplicative traits compose cleanly" {
  let left : ScalarMatrix = { value: 2 }
  let right : ScalarMatrix = { value: 5 }
  inspect((left + right).value, content="7")
  inspect(multiply_matrices(left, right).value, content="10")
}
```

## 边界

不要在这里加入返回标量值的乘积、`norm` 或内积 trait，除非显式建模其标量映射。核心 `algebra` 包只放最小结构和同类型闭合运算。
