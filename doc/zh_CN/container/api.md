# 容器能力 API

`container` 包描述泛型代码如何观察、构造和编辑线性容器，不规定数学定律、
稠密布局或所有权模型。

## 实验状态

`container` 是实验性功能。它的 read/build 模型已经可以用于真实的互操作试验，
但操作记录字段、编辑能力、错误契约和泛型算法签名仍可能发生不兼容变更。应把它用于
带检查的数据交换和结构转换，而不是兼容性稳定的公开边界或高性能数值计算内核 API。

## 能力记录

- `VectorReadOps[V, T]`：长度和受检 `get`。
- `MatrixReadOps[M, T]`：形状和受检 `get`。
- `VectorBuildOps[V, T]`：受检 `tabulate` 构造。
- `MatrixBuildOps[M, T]`：按行列坐标执行的受检 `tabulate` 构造。
- `VectorPersistentEditOps` / `MatrixPersistentEditOps`：返回新值的替换。
- `VectorMutableEditOps` / `MatrixMutableEditOps`：原地替换。

每个记录都提供 `new` 构造函数。非法坐标返回 `IndexOutOfBounds`，负形状返回
`NegativeDimension`。

## 泛型算法

包中公开 `vector_map`、`matrix_map`、`vector_convert`、`matrix_convert` 和
`matrix_transpose`。源容器与目标容器可以不同；`map` 还可以改变标量类型。
`0xN` 与 `Nx0` 等退化形状会被完整保留。

## 仓库适配器

`container/adapters` 适配 immutable/mutable 向量与矩阵、四个默认稠密包装类型，
以及行视图、列视图和转置视图。视图不提供构造能力。OpenBLAS 仅在 native
目标提供自然的 read/build 适配器，不提供持久编辑。
