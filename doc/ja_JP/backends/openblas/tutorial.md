# backends/openblas Tutorial

## はじめに

`backends/openblas` は `native` 専用です。現在のリポジトリ設定は、次の
OpenBLAS 配置を探索します。

- `/opt/homebrew/opt/openblas/include`
- `/opt/homebrew/opt/openblas/lib`
- `/usr/include/x86_64-linux-gnu/openblas-pthread`
- `/usr/include/openblas`
- `/usr/lib/x86_64-linux-gnu/openblas-pthread`
- `/usr/lib/x86_64-linux-gnu`

これは macOS の Homebrew 配置と Ubuntu の標準 OpenBLAS パッケージ配置を
カバーします。これらの場所に OpenBLAS がない場合、このパッケージの `native`
ビルドやテストはコンパイルまたはリンク時に失敗します。

## `BlasMatrix` を作る

```moonbit check
///|
test "construct BlasMatrix from a 2D array" {
  let matrix = @openblas.BlasMatrix::from_2d_array([
    [1.0F, 2.0F, 3.0F],
    [4.0F, 5.0F, 6.0F],
  ])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="3")
}
```

現在使えるスカラーは `Float` と `Double` だけです。これらだけが
`BLASInnerType` を実装しています。

## OpenBLAS で行列乗算する

```moonbit check
///|
test "BlasMatrix multiplication uses the backend matmul path" {
  let left = @openblas.BlasMatrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
  ])
  let right = @openblas.BlasMatrix::from_2d_array([
    [7.0, 8.0],
    [9.0, 10.0],
    [11.0, 12.0],
  ])
  let product = left * right
  debug_inspect(product.to_2d_array(), content="[[58, 64], [139, 154]]")
}
```

現時点で実際に OpenBLAS GEMM を使うのは `Mul` です。次元が合わない場合の意味論は、
このリポジトリの他の unchecked 行列乗算経路と同じで abort になります。

## 既定の不変密バックエンドと相互変換する

```moonbit check
///|
test "convert between OpenBLAS and default immutable dense backend" {
  let base = @default.ImmutableDenseMatrix::from_2d_array([
    [1.0F, 2.0F],
    [3.0F, 4.0F],
  ])
  let blas = @openblas.BlasMatrix::from_default(base)
  let round_trip = blas.to_default()
  debug_inspect(round_trip.inner().to_2d_array(), content="[[1, 2], [3, 4]]")
}
```

具体的な不変行列型との相互変換も同じく用意されています。

- `BlasMatrix::from_immut`
- `BlasMatrix::to_immut`

## 最小の `native` テストフロー

このバックエンドを使うときは `native` ターゲットで実行してください。

```sh
moon test src/backends/openblas --target native
moon test --target native
```

他の MoonBit パッケージから依存する場合も同じです。`BlasMatrix` を明示的に選び、
`native` でビルドします。
