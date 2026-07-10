# Container Capability Tutorial

## Convert Between Existing Backends

This example copies a default mutable dense matrix into the default immutable
dense representation. Later mutation of the source cannot affect the target.

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

Use `matrix_map` instead when conversion also changes the scalar type.
