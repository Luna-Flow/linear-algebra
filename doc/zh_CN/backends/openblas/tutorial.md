# backends/openblas 教程

## 开始前

`backends/openblas` 只支持 `native`。当前仓库配置会搜索以下 OpenBLAS 路径：

- `/opt/homebrew/opt/openblas/include`
- `/opt/homebrew/opt/openblas/lib`
- `/usr/include/x86_64-linux-gnu/openblas-pthread`
- `/usr/include/openblas`
- `/usr/lib/x86_64-linux-gnu/openblas-pthread`
- `/usr/lib/x86_64-linux-gnu`

这同时覆盖 macOS 的 Homebrew 安装布局，以及 Ubuntu 默认的 OpenBLAS 包布局。
如果系统里没有这些路径，这个包的 `native` 构建或测试会在编译或链接阶段失败。

## 构造 `BlasMatrix`

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

当前只支持 `Float` 与 `Double`，因为只有这两种标量实现了 `BLASInnerType`。

## 通过 OpenBLAS 进行矩阵乘法

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

`Mul` 是当前真正走 OpenBLAS GEMM 的操作。维度不兼容时，语义与仓库现有其他
unchecked 矩阵乘法路径一致：直接 abort。

## 在 `BlasMatrix` 与默认不可变稠密后端之间互转

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

与具体不可变矩阵类型也提供了等价互转接口：

- `BlasMatrix::from_immut`
- `BlasMatrix::to_immut`

## 最小 `native` 测试流程

这个后端必须使用 `native` 目标来运行：

```sh
moon test src/backends/openblas --target native
moon test --target native
```

如果你要在别的 MoonBit 包里使用它，也遵循同一条规则：显式选择 `BlasMatrix`，
并以 `native` 目标编译。
