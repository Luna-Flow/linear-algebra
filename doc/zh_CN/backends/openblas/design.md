# backends/openblas 设计

## 职责

- 提供一个能够接入公开 `@algebra` trait 生态的、仅支持 `native` 的具体矩阵后端。
- 把后端自有的公开类型固定为 `BlasMatrix[T]`。
- 对矩阵乘法使用 OpenBLAS GEMM，同时把首版其余矩阵表面留在 MoonBit 本地实现。
- 把 OpenBLAS 的布局与绑定细节藏在仓库自有 API 后面。

## 为什么它是包装后端

这个包是一个“兼容 trait 的后端包装层”。

它不是：

- runtime backend selector
- 全局 backend enum
- 直接在外部 OpenBLAS 绑定类型上实现 trait 的做法

之所以需要包装层，是因为包必须拥有具体矩阵类型，才能在不触发 MoonBit foreign
trait / foreign type 限制的前提下，为它挂上 `@algebra` traits。

## 类型与目标共同决定行为

现在的后端选择由两件事决定：

- 类型选择
  `@immut.Matrix[T]` 与 `@default.ImmutableDenseMatrix[T]` 继续使用仓库现有的
  稠密实现；`@openblas.BlasMatrix[T]` 则使用 OpenBLAS 支持的矩阵乘法路径
- 目标选择
  `backends/openblas` 只参与 `native` 构建

`@immut.Matrix` 不再提供运行时切换后端的 API。

## 标量策略

`BLASInnerType` 是有意保持在后端内部的局部抽象。它封装这个包装层真正需要的
标量差异：

- 分发到正确的 GEMM 内核
- 提供后端校验所用的容差值

当前仓库只为 `Float` 与 `Double` 实现该 trait。这与现有 OpenBLAS 后端矩阵表面一致，
也避免对外讲出一个误导性的“泛型无上限”故事。

## 操作分工

- `Mul`
  委托给 OpenBLAS GEMM
- `shape`、`transpose`、`+`、`-`、`neg`
  保持为本地 MoonBit 实现

这种分工保证了 trait 导向泛型代码已经可以使用完整的矩阵外形，同时不假装所有操作
都必须在首版就接入 BLAS 例程。
