# `linear-algebra/algebra`

このページは、現在の `0.4.5` リポジトリにおける
`Luna-Flow/linear-algebra/algebra` の公開 API 基準をまとめたものです。

## 役割

`algebra` は線形代数の構造を表す trait を提供します。各バックエンドパッケージは、自分が所有する具体データ型に対してこれらの trait を実装します。trait は必要最小限の能力ごとに分かれているため、汎用アルゴリズムが意図せずアダマール積、行列積、または厳密な浮動小数点体の法則に依存することを避けられます。

## プロジェクト設定

`algebra` は構造層だけを担当します。共有の上流スカラー抽象も直接使うなら、依存をまとめて追加してください。

```sh
moon add Luna-Flow/linear-algebra@0.4.5
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推奨する `moon.pkg` インポート:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

線形代数の構造 trait には `@algebra` を使い、共有の上流抽象が必要なときだけ `@lf_alg` と `@lf_arith` を直接参照します。

## 形状 trait

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

`MatrixShape` は二次元の形状を観測できる値、`VectorShape` は長さを観測できるベクトル状の値を表します。これらは代数演算の存在を主張しません。

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

加法的な線形構造を持つベクトル状の値を表します。要素ごとの乗算、内積、ノルム、大域的な零元は要求しません。

アルゴリズムがアダマール積を本当に必要とする場合だけ、この強い trait を使います。

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

形状と同じ型への転置を持つ行列状の値を表します。行列積は要求しません。動的な矩形行列の乗算は、実行時の形状が適合する場合にだけ定義される部分操作だからです。この trait は、密な保存形式、連続メモリ、直接インデックス、可変操作も要求しません。

追加の演算が本当に必要なアルゴリズムだけ、より強い trait を使います。

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

## 境界

スカラー値を返す積、`norm`、内積 trait はここに置きません。中核の `algebra` パッケージは、最小構造と同じ型に閉じた演算のためのパッケージです。
