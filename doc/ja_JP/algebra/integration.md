# Algebra エコシステムへの接続

`algebra` はベクトル・行列オブジェクト全体の数学能力を表します。外部ライブラリは、
演算の意味、閉性、所有権の振る舞いが実際の型に合う trait だけを実装します。

## Algebra レベルを選ぶ

| 系統 | Trait | 前提 | 数学的な約束 |
|---|---|---|---|
| Shape | `VectorShape` | なし | ベクトル長を返す |
| Vector 1 | `AdditiveVector` | `VectorShape + Add + Neg + Sub` | 同じ型で加算・符号反転・減算 |
| Vector 2 | `VecMulVector` | `AdditiveVector + Mul` | `Mul` は要素積/Hadamard 積 |
| Shape | `MatrixShape` | なし | 行列形状を返す |
| Matrix 1 | `TransposeMatrix` | `MatrixShape` | 転置が同じ行列型を返す |
| Matrix 2 | `AdditiveMatrix` | `TransposeMatrix + Add + Neg + Sub` | 同じ型で行列加算・符号反転・減算 |
| Matrix 3 | `MatMulMatrix` | `AdditiveMatrix + Mul` | `Mul` は行列積 |

下流アルゴリズムに必要な最小レベルで止めます。Shape は要素アクセスを意味せず、
`TransposeMatrix` は行列積を意味しません。`AdditiveVector` は内積、norm、
スカラー作用、要素積を意味しません。

## 演算子境界

強い trait は MoonBit の演算子を再利用し、`Result` ではなく `Self` を返します。
実装前に次を確認します。

- 演算子の既存の意味が trait と一致する。特に `MatMulMatrix` の `Mul` は行列積です。
- 結果が同じ具象型に閉じている。
- runtime の形状前提と失敗動作が文書化されている。
- 演算中にバックエンドや所有権モデルを暗黙に切り替えない。

動的な長方形行列では、形状によって積が不正になる場合があります。
`MatMulMatrix` 自体は検査付きエラーチャネルを定義しません。checked method が必要な
バックエンドはそれを保持し、演算子契約が適切な場合だけ trait を実装します。

## Algebra と Container は独立

| 必要なこと | 使用する層 |
|---|---|
| 要素観測・ストレージ変換 | `container` の read/build 辞書 |
| 同じ型に閉じた数学演算 | `algebra` trait |
| 両方 | 対応する trait と辞書を別々に提供 |

`MatrixShape` は意味上の形状能力であり、検査付き要素アクセスではありません。
algebra の転置は同じ型を返し、container の転置は別の型を構築できます。

container 接続のためだけに広いスカラー trait を実装しないでください。実際に支える
法則と演算に限り `Luna-Flow/luna-generic` と `Luna-Flow/arithmetic` を使います。

## 実装を置く場所

公開演算子と algebra 実装は、通常は具象型を所有するパッケージに置きます。別の相互運用
パッケージが必要なら、そのパッケージが所有する wrapper 型を作り、wrapper に trait を
実装します。所有していない外部型の演算子の意味を bridge が変更する前提にしません。

## 同じ型に閉じた例

これはスカラーを任意の動的行列に見せかけた例ではなく、意図的に `1x1` 行列型です。
`1x1` 行列では転置は恒等、要素加算は行列加算、唯一の要素同士の積は標準行列積と
完全に一致します。固定形状により全演算が同じ型に閉じ、runtime 形状失敗もありません。

```moonbit check
///|
struct EcosystemScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for EcosystemScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for EcosystemScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for EcosystemScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for EcosystemScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for EcosystemScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for EcosystemScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveMatrix for EcosystemScalarMatrix

///|
impl @algebra.MatMulMatrix for EcosystemScalarMatrix

///|
fn[M : @algebra.MatMulMatrix] ecosystem_gram(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "external algebra type participates by capability" {
  let matrix : EcosystemScalarMatrix = { value: 3 }
  let other : EcosystemScalarMatrix = { value: 4 }
  inspect((matrix + other).value, content="7")
  inspect(matrix.transpose().value, content="3")
  inspect(ecosystem_gram(matrix).value, content="9")
}
```

外部ライブラリは `MatrixShape`、`TransposeMatrix`、`AdditiveMatrix` のどこで
止めても構いません。動的行列バックエンドは、この固定形状の前提をコピーせず、互換性の
ない形状に対する演算子の動作を別途定義する必要があります。

## 接続チェックリスト

- 型とアルゴリズムに合う最小 trait を選ぶ。
- `Add` / `Neg` / `Sub` / `Mul` の意味が trait と一致することを確認する。
- 閉性、形状、転置後の形状、型が支える代表的な法則をテストする。
- runtime 形状前提がある演算子は不正形状の動作もテストする。
- allocation、共有ストレージ、隠れた mutation を文書化する。
- 内積、norm、スカラー作用、分解、solver を現在の trait に混ぜない。
- 要素単位の相互運用が必要なら container 辞書を別に追加する。
