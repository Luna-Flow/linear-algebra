# `linear-algebra/backends/default`

このページは、現在の `0.4.3` リポジトリにおける
`Luna-Flow/linear-algebra/backends/default` の公開 API 基準をまとめたものです。

## 役割

`backends/default` は、既存の密 `mutable` / `immut` 実装を包む、このパッケージ
所有のラッパー型を提供します。これらのラッパー型は既定バックエンドパッケージが
所有するため、MoonBit の foreign trait / foreign type ルールを破ることなく、
公開 `@algebra` trait を実装できます。

## `DenseVector[T]`

```moonbit check
///|
test "DenseVector wraps a mutable vector backend" {
  let vector : @default.DenseVector[Int] = @default.DenseVector::from_array([
    1, 2, 3,
  ])
  inspect(vector.length(), content="3")
  inspect(vector[1], content="2")
}
```

既定の可変密ベクトルバックエンドを包む所有ラッパーです。

### コンストラクタとアクセサ

- `DenseVector::from_backend(inner : @mutable.Vector[T]) -> DenseVector[T]`
  既存の可変ベクトルを包みます。
- `DenseVector::from_array(data : Array[T]) -> DenseVector[T]`
  配列から可変密ベクトルを構築します。
- `DenseVector::make(length : Int, value : T) -> DenseVector[T]`
  全要素が `value` のベクトルを構築します。
- `DenseVector::inner(self) -> @mutable.Vector[T]`
  内部の可変ベクトルを返します。
- `DenseVector::length(self) -> Int`
  ベクトル長を返します。
- `DenseVector::op_get(self, index : Int) -> T`
  読み取りインデックスアクセスを提供します。

### trait 実装

- `Add`、`Neg`、`Sub`、`Mul`。対応する要素演算の制約付きです。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のときの `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のときの `@algebra.VecMulVector`

## `DenseMatrix[T]`

```moonbit check
///|
test "DenseMatrix wraps a mutable matrix backend" {
  let matrix : @default.DenseMatrix[Int] = @default.DenseMatrix::from_2d_array([
    [1, 2],
    [3, 4],
  ])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

既定の可変密行列バックエンドを包む所有ラッパーです。

### コンストラクタとアクセサ

- `DenseMatrix::from_backend(inner : @mutable.Matrix[T]) -> DenseMatrix[T]`
  既存の可変行列を包みます。
- `DenseMatrix::from_2d_array(data : Array[Array[T]]) -> DenseMatrix[T]`
  行優先の二次元配列から行列を構築します。
- `DenseMatrix::new(row : Int, col : Int, value : T) -> DenseMatrix[T]`
  全要素が `value` の行列を構築します。
- `DenseMatrix::inner(self) -> @mutable.Matrix[T]`
  内部の可変行列を返します。
- `DenseMatrix::row(self) -> Int`
  行数を返します。
- `DenseMatrix::col(self) -> Int`
  列数を返します。

### trait 実装

- `Add`、`Neg`、`Sub`、`Mul`。対応する要素演算の制約付きです。
- 任意の `T` に対する `@algebra.MatrixShape` と `@algebra.TransposeMatrix`
- `T : Add + Neg` のときの `@algebra.AdditiveMatrix`
- `T : Add + Neg + AddMonoid + Mul` のときの `@algebra.MatMulMatrix`

## `ImmutableDenseVector[T]`

```moonbit check
///|
test "ImmutableDenseVector wraps an immutable vector backend" {
  let vector : @default.ImmutableDenseVector[Int] = @default.ImmutableDenseVector::from_array([
      1, 2, 3,
    ],
  )
  inspect(vector.length(), content="3")
  inspect(vector[2], content="3")
}
```

既定の不変密ベクトルバックエンドを包む所有ラッパーです。

### コンストラクタとアクセサ

- `ImmutableDenseVector::from_backend(inner : @immut.Vector[T])`
- `ImmutableDenseVector::from_array(data : Array[T])`
- `ImmutableDenseVector::make(length : Int, value : T)`
- `ImmutableDenseVector::inner(self) -> @immut.Vector[T]`
- `ImmutableDenseVector::length(self) -> Int`
- `ImmutableDenseVector::op_get(self, index : Int) -> T`

### trait 実装

- `Add`、`Neg`、`Sub`、`Mul`。対応する要素演算の制約付きです。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のときの `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のときの `@algebra.VecMulVector`

## `ImmutableDenseMatrix[T]`

```moonbit check
///|
test "ImmutableDenseMatrix wraps an immutable matrix backend" {
  let matrix : @default.ImmutableDenseMatrix[Int] = @default.ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

既定の不変密行列バックエンドを包む所有ラッパーです。

### コンストラクタとアクセサ

- `ImmutableDenseMatrix::from_backend(inner : @immut.Matrix[T])`
- `ImmutableDenseMatrix::from_2d_array(data : Array[Array[T]])`
- `ImmutableDenseMatrix::new(row : Int, col : Int, value : T)`
- `ImmutableDenseMatrix::inner(self) -> @immut.Matrix[T]`
- `ImmutableDenseMatrix::row(self) -> Int`
- `ImmutableDenseMatrix::col(self) -> Int`

### trait 実装

- `Add`、`Neg`、`Sub`、`Mul`。対応する要素演算の制約付きです。
- 任意の `T` に対する `@algebra.MatrixShape` と `@algebra.TransposeMatrix`
- `T : Add + Neg` のときの `@algebra.AdditiveMatrix`
- `T : Add + Neg + Zero + Mul` のときの `@algebra.MatMulMatrix`

## 汎用補助関数

- `shape_of[M : @algebra.MatrixShape](matrix : M) -> (Int, Int)`
  オブジェクトの形状を返します。
- `matmul[M : @algebra.MatMulMatrix](left : M, right : M) -> M`
  明示的な乗算能力を通して行列乗算を分配します。
- `transpose[M : @algebra.TransposeMatrix](matrix : M) -> M`
  algebra trait を通して閉じた転置を分配します。

## 境界

このパッケージは、既定バックエンドのラッパー型に外側の `algebra` trait を
実装します。新しい構造 trait は定義しません。スカラー値を返す積、ノルム、
求解、分解は、構造 trait または同型の閉じた演算として表現できる場合を除き、
バックエンドメソッドまたは将来の専用アルゴリズム層 API に置くべきです。
