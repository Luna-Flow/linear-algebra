# `linear-algebra/backends/default`

このページは、現在の `0.4.2` リポジトリにおける
`Luna-Flow/linear-algebra/backends/default` の公開 API 基準をまとめたものです。

## 役割

`backends/default` は、既存の `mutable` / `immut` の密行列・密ベクトル実装を包むラッパー型を提供します。これらのラッパー型はこのパッケージが所有するため、外側の `@algebra` trait を実装できます。

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

既定の可変密ベクトルバックエンドを包む自前のラッパーです。

公開メソッド:

- `from_backend(@mutable.Vector[T]) -> DenseVector[T]`
- `from_array(Array[T]) -> DenseVector[T]`
- `make(Int, T) -> DenseVector[T]`
- `inner(Self[T]) -> @mutable.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のとき `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のとき `@algebra.VecMulVector`

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

既定の可変密行列バックエンドを包む自前のラッパーです。

公開メソッド:

- `from_backend(@mutable.Matrix[T]) -> DenseMatrix[T]`
- `from_2d_array(Array[Array[T]]) -> DenseMatrix[T]`
- `new(Int, Int, T) -> DenseMatrix[T]`
- `inner(Self[T]) -> @mutable.Matrix[T]`
- `row(Self[T]) -> Int`
- `col(Self[T]) -> Int`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.MatrixShape` と `@algebra.TransposeMatrix`
- `T : Add + Neg` のとき `@algebra.AdditiveMatrix`
- `T : Add + Neg + AddMonoid + Mul` のとき `@algebra.MatMulMatrix`

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

既定の不変密ベクトルバックエンドを包む自前のラッパーです。

公開メソッド:

- `from_backend(@immut.Vector[T]) -> ImmutableDenseVector[T]`
- `from_array(Array[T]) -> ImmutableDenseVector[T]`
- `make(Int, T) -> ImmutableDenseVector[T]`
- `inner(Self[T]) -> @immut.Vector[T]`
- `length(Self[T]) -> Int`
- `op_get(Self[T], Int) -> T`

実装する trait:

- `Add`、`Neg`、`Sub`、`Mul`。制約は対応する要素レベルの演算に従います。
- 任意の `T` に対する `@algebra.VectorShape`
- `T : Add + Neg` のとき `@algebra.AdditiveVector`
- `T : Add + Neg + Mul` のとき `@algebra.VecMulVector`

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

既定の不変密行列バックエンドを包む自前のラッパーです。

公開メソッド:

- `from_backend(@immut.Matrix[T]) -> ImmutableDenseMatrix[T]`
- `from_2d_array(Array[Array[T]]) -> ImmutableDenseMatrix[T]`
- `new(Int, Int, T) -> ImmutableDenseMatrix[T]`
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
