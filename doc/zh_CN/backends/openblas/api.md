# `linear-algebra/backends/openblas`

本页记录当前 `0.4.5` 仓库中 `Luna-Flow/linear-algebra/backends/openblas`
的公开 API 基线。

## 职责

`backends/openblas` 提供一个仓库自有、仅支持 `native` 的矩阵后端。它把矩阵乘法委托给
OpenBLAS GEMM，同时仍然在本地包装类型上实现公开的 `@algebra` 矩阵 traits。

这个包与 `@immut.Matrix` 分离。`immut` 现在没有 runtime backend selector；
后端选择体现在你显式使用的具体矩阵类型，以及你编译到的目标平台上。

## 平台约束

- 支持目标：`native`
- 不支持目标：`js`、`wasm`、`wasm-gc`
- 当前仓库的链接配置会同时搜索 macOS Homebrew 的
  `/opt/homebrew/opt/openblas/include`
  与 `/opt/homebrew/opt/openblas/lib`，以及 Ubuntu 默认 OpenBLAS 包布局的
  `/usr/include/x86_64-linux-gnu/openblas-pthread`、
  `/usr/include/openblas`、
  `/usr/lib/x86_64-linux-gnu/openblas-pthread`、
  `/usr/lib/x86_64-linux-gnu`

## `BLASInnerType`

`BLASInnerType` 是后端局部 trait，目前只为 `Float` 与 `Double` 提供实现。

它负责封装这个后端需要的标量差异：

- `tolerance()`
  返回测试与结果校验使用的容差。
- `gemm(m, n, k, left, right)`
  调度到对应的 OpenBLAS 内核：
  `Float` 走 `cblas_sgemm`，`Double` 走 `cblas_dgemm`。

`BlasMatrix[T]` 的公开构造与转换 API 都要求 `T : BLASInnerType`，因此不会暴露
“任意 `T` 都能构造，但只有一部分 `T` 能真正参与运算”的半开放类型表面。

## `BlasMatrix[T]`

```moonbit check
///|
test "BlasMatrix stores shape and values" {
  let matrix = @openblas.BlasMatrix::from_2d_array([[1.0F, 2.0F], [3.0F, 4.0F]])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

`BlasMatrix[T]` 是该包自有的具体后端矩阵类型。它在内部保存：

- `row : Int`
- `col : Int`
- 连续存储的 `FixedArray[T]` buffer

公开心智模型保持为 row-major。调用 OpenBLAS 所需的布局细节被封装在后端内部，
不会暴露给调用者。

### 构造与互转

- `BlasMatrix::from_immut(inner : @immut.Matrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_default(inner : @default.ImmutableDenseMatrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_2d_array(data : Array[Array[T]]) -> BlasMatrix[T]`
- `BlasMatrix::new(row : Int, col : Int, value : T) -> BlasMatrix[T]`
- `to_immut(self) -> @immut.Matrix[T]`
- `to_default(self) -> @default.ImmutableDenseMatrix[T]`
- `to_2d_array(self) -> Array[Array[T]]`

### 访问器

- `row(self) -> Int`
- `col(self) -> Int`
- `to_array(self) -> Array[T]`

## Trait 实现

`BlasMatrix[T]` 当前实现了：

- `@algebra.MatrixShape`
- `@algebra.TransposeMatrix`
- `@algebra.AdditiveMatrix`
- `@algebra.MatMulMatrix`
- `Add`、`Neg`、`Sub`、`Mul`
- `Show`

这些行为是有意分层的：

- `Mul` 通过 `BLASInnerType::gemm` 调用 OpenBLAS GEMM。
- `shape`、`transpose`、`+`、`-` 与一元 `-` 目前都在这个后端包里用 MoonBit 本地实现。

## 边界

这个包公开的是“兼容 trait 的后端包装层”。它不是：

- runtime backend selector
- 全局 backend enum
- 直接给第三方 OpenBLAS 绑定类型挂 trait 的适配层
- 对外公开 OpenBLAS 底层句柄的 API
