# `linear-algebra/backends/openblas`

このページは、現在の `0.4.7` リポジトリにおける
`Luna-Flow/linear-algebra/backends/openblas` の公開 API 基準をまとめたものです。

## 役割

`backends/openblas` は、行列とベクトルの自前ラッパー型を提供する、リポジトリ所有
の `native` 専用バックエンドです。行列乗算は OpenBLAS GEMM に、ベクトルおよび
行列-ベクトル補助操作は対応する BLAS カーネルに委譲します。

このパッケージは `@immut.Matrix` とは別物です。`immut` には runtime backend
selector はありません。バックエンド選択は、利用する具体的な行列型と、
ビルド対象のプラットフォームで表されます。

## プラットフォーム制約

- 対応ターゲット: `native`
- 非対応ターゲット: `js`、`wasm`、`wasm-gc`
- 現在のリポジトリのリンク設定は、macOS の Homebrew 用
  `/opt/homebrew/opt/openblas/include` と
  `/opt/homebrew/opt/openblas/lib` に加えて、Ubuntu の標準的な
  OpenBLAS パッケージ配置である
  `/usr/include/x86_64-linux-gnu/openblas-pthread`、
  `/usr/include/openblas`、
  `/usr/lib/x86_64-linux-gnu/openblas-pthread`、
  `/usr/lib/x86_64-linux-gnu`
  も探索します

## `BLASInnerType`

`BLASInnerType` はバックエンド局所の trait で、現在は `Float` と `Double`
にだけ実装されています。

このバックエンドで必要なスカラー差分を担当します。

- `tolerance()`
  テストと結果検証で使う許容誤差を返します。
- `dot(length, left, right)`
  `cblas_sdot` または `cblas_ddot` に振り分けます。
- `scal(length, alpha, data)`
  `cblas_sscal` または `cblas_dscal` に振り分けます。
- `axpy(length, alpha, x, y)`
  `cblas_saxpy` または `cblas_daxpy` に振り分けます。
- `gemm(m, n, k, left, right)`
  対応する OpenBLAS カーネルへ振り分けます。
  `Float` は `cblas_sgemm`、`Double` は `cblas_dgemm` を使います。
- `gemv(row, col, matrix, vector)`
  `cblas_sgemv` または `cblas_dgemv` に振り分けます。

`BlasMatrix[T]` と `BlasVector[T]` の公開コンストラクタと変換 API はすべて
`T : BLASInnerType` を要求します。そのため、「任意の `T` で作れるが一部の `T`
だけが演算できる」という半開きの型面を公開しません。

## `BlasVector[T]`

OpenBLAS バックエンド所有の native ベクトルラッパーです。

### コンストラクタ・相互変換・アクセサ

- `BlasVector::from_immut(inner : @immut.Vector[T]) -> BlasVector[T]`
- `BlasVector::from_default(inner : @default.ImmutableDenseVector[T]) -> BlasVector[T]`
- `BlasVector::from_array(data : Array[T]) -> BlasVector[T]`
- `BlasVector::make(length : Int, value : T) -> BlasVector[T]`
- `to_immut(self) -> @immut.Vector[T]`
- `to_default(self) -> @default.ImmutableDenseVector[T]`
- `to_array(self) -> Array[T]`
- `length(self) -> Int`
- `op_get(self, index : Int) -> T`

### trait 対応

`BlasVector[T]` は現在、次を実装します。

- `@algebra.VectorShape`
- `@algebra.AdditiveVector`
- `Add`、`Neg`、`Sub`
- `Show`

`@algebra.VecMulVector` は実装しません。BLAS 風の `scale`、`dot`、`axpy` は、
新しい構造 trait ではなくバックエンドメソッドとして公開します。

### バックエンドメソッド

- `BlasVector::scale(self, scalar : T) -> BlasVector[T]`
- `BlasVector::dot(self, other : BlasVector[T]) -> T`
- `BlasVector::axpy(self, alpha : T, other : BlasVector[T]) -> BlasVector[T]`

## `BlasMatrix[T]`

```moonbit check
///|
test "BlasMatrix stores shape and values" {
  let matrix = @openblas.BlasMatrix::from_2d_array([[1.0F, 2.0F], [3.0F, 4.0F]])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

`BlasMatrix[T]` はこのパッケージ所有の具体バックエンド行列型です。内部には次を
保持します。

- `row : Int`
- `col : Int`
- 連続配置の `FixedArray[T]` バッファ

公開される心的モデルは row-major のままです。OpenBLAS 呼び出しに必要なレイアウト
詳細はバックエンド内部に閉じ込めます。

### コンストラクタと相互変換

- `BlasMatrix::from_immut(inner : @immut.Matrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_default(inner : @default.ImmutableDenseMatrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_2d_array(data : Array[Array[T]]) -> BlasMatrix[T]`
- `BlasMatrix::new(row : Int, col : Int, value : T) -> BlasMatrix[T]`
- `to_immut(self) -> @immut.Matrix[T]`
- `to_default(self) -> @default.ImmutableDenseMatrix[T]`
- `to_2d_array(self) -> Array[Array[T]]`

### アクセサ

- `row(self) -> Int`
- `col(self) -> Int`
- `to_array(self) -> Array[T]`

### バックエンドメソッド

- `BlasMatrix::matvec(self, vector : BlasVector[T]) -> BlasVector[T]`
  GEMV を通して行列と OpenBLAS ベクトルの積を計算します。

## Trait 実装

`BlasMatrix[T]` は現在、次を実装しています。

- `@algebra.MatrixShape`
- `@algebra.TransposeMatrix`
- `@algebra.AdditiveMatrix`
- `@algebra.MatMulMatrix`
- `Add`、`Neg`、`Sub`、`Mul`
- `Show`

振る舞いは意図的に分担されています。

- `Mul`
  `BLASInnerType::gemm` を通して OpenBLAS GEMM を使います
- `matvec`
  `BLASInnerType::gemv` を通して OpenBLAS GEMV を使います
- `shape`、`transpose`、`+`、`-`、単項 `-`
  このバックエンドパッケージ内の MoonBit 実装です

## 境界

このパッケージが公開するのは、trait 互換のバックエンドラッパーです。次のものでは
ありません。

- runtime backend selector
- グローバルな backend enum
- 外部 OpenBLAS バインディング型へ直接 trait を実装するアダプタ
- 生の OpenBLAS ハンドル型を公開する API
