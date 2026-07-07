# `linear-algebra/backends/default`

このページは現在の `0.4.0` リポジトリにおける
`Luna-Flow/linear-algebra/backends/default` の公開 API を説明します。

## 役割

`backends/default` は、既存の `mutable` / `immut` の密行列・密ベクトル実装を包むラッパー型を提供します。ラッパー型はこのパッケージが所有するため、外側の `@algebra` trait を実装できます。

## `DenseVector[T]`

```moonbit
pub struct DenseVector[T] {
  inner : @mutable.Vector[T]
}
```

既定の可変密ベクトルラッパーです。

公開メソッド:

- `from_backend(@mutable.Vector[T])`
- `from_array(Array[T])`
- `make(Int, T)`
- `inner(Self[T]) -> @mutable.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のとき `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のとき `@algebra.VecMulVector`

## `DenseMatrix[T]`

```moonbit
pub struct DenseMatrix[T] {
  inner : @mutable.Matrix[T]
}
```

既定の可変密行列ラッパーです。

公開メソッド:

- `from_backend(@mutable.Matrix[T])`
- `from_2d_array(Array[Array[T]])`
- `new(Int, Int, T)`
- `inner(Self[T]) -> @mutable.Matrix[T]`
- `row(Self[T]) -> Int`
- `col(Self[T]) -> Int`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.MatrixShape` と `@algebra.TransposeMatrix`
- `T : Add + Neg` のとき `@algebra.AdditiveMatrix`
- `T : Add + Neg + AddMonoid + Mul` のとき `@algebra.MatMulMatrix`

## `ImmutableDenseVector[T]`

```moonbit
pub struct ImmutableDenseVector[T] {
  inner : @immut.Vector[T]
}
```

既定の不変密ベクトルラッパーです。

公開メソッド:

- `from_backend(@immut.Vector[T])`
- `from_array(Array[T])`
- `make(Int, T)`
- `inner(Self[T]) -> @immut.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のとき `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のとき `@algebra.VecMulVector`

## `ImmutableDenseMatrix[T]`

```moonbit
pub struct ImmutableDenseMatrix[T] {
  inner : @immut.Matrix[T]
}
```

既定の不変密行列ラッパーです。

公開メソッド:

- `from_backend(@immut.Matrix[T])`
- `from_2d_array(Array[Array[T]])`
- `new(Int, Int, T)`
- `inner(Self[T]) -> @immut.Matrix[T]`
- `row(Self[T]) -> Int`
- `col(Self[T]) -> Int`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.MatrixShape` と `@algebra.TransposeMatrix`
- `T : Add + Neg` のとき `@algebra.AdditiveMatrix`
- `T : Add + Neg + Zero + Mul` のとき `@algebra.MatMulMatrix`

## 汎用補助関数

- `shape_of[M : @algebra.MatrixShape](M) -> (Int, Int)`
- `matmul[M : @algebra.MatMulMatrix](M, M) -> M`
- `transpose[M : @algebra.TransposeMatrix](M) -> M`

## 境界

このパッケージは既定バックエンドのラッパー型に外側の `algebra` trait を実装します。新しい構造 trait は定義しません。スカラー値を返す積、ノルム、求解、分解は、構造または閉じた演算として表せる場合を除き、バックエンドメソッドまたは将来の専用アルゴリズム層に置きます。
