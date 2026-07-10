# 容器能力教程

## 在现有后端之间转换

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

如果还需要改变标量类型，请使用 `matrix_map`。
