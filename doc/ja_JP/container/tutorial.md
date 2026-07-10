# コンテナ能力チュートリアル

## 既存バックエンド間の変換

```moonbit check
///|
test "convert mutable dense storage to immutable dense storage" {
  let source = @default.DenseMatrix::from_2d_array([[1, 2], [3, 4]])
  let target : @default.ImmutableDenseMatrix[Int] = @container.matrix_convert(
    source,
    @container_adapters.dense_matrix_read_ops(),
    @container_adapters.immutable_dense_matrix_build_ops(),
  ).unwrap()
  source.inner().set(0, 0, 99)
  inspect(target.inner(), content="|1, 2|\n|3, 4|")
}
```

要素型も変更する場合は `matrix_map` を使います。
