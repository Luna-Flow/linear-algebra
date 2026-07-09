# Luna-Flow/linear-algebra

这份 README 对应当前仓库的 **v0.4.3** 文档基线。

`mutable` 数值 API 现在使用共享的 `Luna-Flow/arithmetic.Sqrt` 能力；
整数嵌入遵循 `Luna-Flow/luna-generic.IntegralHomomorphism`。在当前版本中，
`Tolerance` 仍保留在 `mutable` 包内。凡是可能在运行时失败的矩阵操作，
现在都使用带检查的 `Result[..., LinearAlgebraError]` API；旧的 abort 行为
和 `Option` 返回语义则通过显式的 `unchecked_*` 方法保留。

`0.4.3` 这一基线延续了 `0.4.x` 的带检查 API 表面，也保留了 `0.4.2`
引入的打包矩阵乘法路径，同时刷新了多语言文档基线，并把 README 与
CHANGELOG 的分工明确下来。

更早的版本说明和仓库历史请参见 [CHANGELOG.md](../../CHANGELOG.md)。

## 分层架构

- **`arithmetic`**：面向线性代数的操作能力层。它复用
  `Luna-Flow/luna-generic` 和 `Luna-Flow/arithmetic` 中的标量操作 trait，
  并在需要时补充只表达“可进行某类操作”的 trait。
- **`algebra`**：数学结构能力层。它只定义线性代数自己拥有的结构 trait。
- **`backends/default`**：参考稠密后端层。它公开可变稠密包装类型
  `DenseVector` / `DenseMatrix`，以及不可变稠密包装类型
  `ImmutableDenseVector` / `ImmutableDenseMatrix`。
- **`error`**：带检查线性代数 API 共用的错误词汇层，覆盖形状、指数、空矩阵、
  奇异矩阵以及后端相关错误。
- **trait 驱动算法**：后端无关代码应依赖最小必要能力，例如
  `MatrixShape`、`AdditiveVector`、`VecMulVector`、`TransposeMatrix` 或
  `MatMulMatrix`。

把向量或矩阵映射为标量范畴的能力，例如内积或范数，属于具体后端或算法细节；
它们不属于核心结构 trait 层。

默认稠密实现只是一个后端，不是整个生态的中心。算法应依赖最小的线性代数 trait，
而不是依赖具体的稠密矩阵或向量类型。

这个仓库的定位，是给更上层的数学库、几何库和 solver 风格库提供线性代数基础层。
领域特定的求解、回归或优化工作流，应放在基于这些 trait、后端包装类型和具体
矩阵/向量类型构建的下游包中。

具体的 `immut` / `mutable` 矩阵与向量类型，就是 `backends/default` 包装层所使用的
底层实现。`DenseVector` 和 `DenseMatrix` 包装 `@mutable.Vector` 与
`@mutable.Matrix`；`ImmutableDenseVector` 和 `ImmutableDenseMatrix` 包装
`@immut.Vector` 与 `@immut.Matrix`。

## 导览指南

- **一般应用开发者**：
  从 [mutable](./mutable/matrix/api.md) 和 [immut](./immut/matrix/api.md)
  开始。它们是面向应用代码的具体 API，适合业务工具、实用程序、数值处理、
  小型游戏和可视化逻辑等场景。
- **数学库 / 通用算法开发者**：
  建议按这个顺序阅读：
  [arithmetic](./arithmetic/api.md) ->
  [algebra](./algebra/api.md) ->
  [backends/default](./backends/default/api.md) ->
  [immut / mutable](./immut/matrix/api.md)。
  先看操作能力，再看结构能力，再看默认后端包装层，最后落到具体实现。
  如果你准备在这个仓库之上构建更高层的应用库、几何包或 solver 风格包，
  这就是推荐的入口路径。

## 文档入口

- **`immut` 具体 API**：
  [immut/matrix API](./immut/matrix/api.md)、
  [immut/matrix 教程](./immut/matrix/tutorial.md)、
  [immut/vector API](./immut/vector/api.md)、
  [immut/vector 教程](./immut/vector/tutorial.md)
- **`mutable` 具体 API**：
  [mutable/matrix API](./mutable/matrix/api.md)、
  [mutable/matrix 教程](./mutable/matrix/tutorial.md)、
  [mutable/vector API](./mutable/vector/api.md)、
  [mutable/vector 教程](./mutable/vector/tutorial.md)
- **能力层与后端层**：
  [arithmetic API](./arithmetic/api.md)、
  [algebra API](./algebra/api.md)、
  [backends/default API](./backends/default/api.md)、
  [error API](./error/api.md)

## 下游使用示例

- **[`Luna-Flow/geometry3d`](https://github.com/Luna-Flow/geometry3d)**：
  一个建立在 `Luna-Flow/linear-algebra` 之上的 MoonBit 3D 几何基础库。
  它在此基础上继续提供核心几何、camera/view 数学、后端无关渲染，以及
  TUI / Canvas / GSAP 后端。
  它的
  [英文文档](https://github.com/Luna-Flow/geometry3d/blob/main/doc/en_US/README.md)
  可以作为一个具体的下游示例入口。

## 抽象层项目配置

如果你想使用抽象能力层来编写后端无关代码，请显式安装它所依赖的上游抽象包：

```sh
moon add Luna-Flow/linear-algebra@0.4.3
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推荐的 `moon.pkg` 导入写法：

```moonbit
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

使用 `@algebra` 表示线性代数结构 trait，`@la_arithmetic` 表示面向线性代数的
操作 trait，`@lf_alg` 表示共享的上游代数抽象，`@lf_arith` 表示共享的上游算术
类型。

## 仓库定位

同时提供可变与不可变执行模型的矩阵/向量基础设施。

## 文档布局

- `README.md` 用于说明仓库叙事和当前版本基线。
- `doc_standard.md` 用于记录文档契约。
- 各模块或子系统目录下包含 `api.md`、`tutorial.md` 和 `design.md`。

## 模块概览

- **`immut/matrix`**：实现位于 `src/immut`
- **`immut/vector`**：实现位于 `src/immut`
- **`mutable/matrix`**：实现位于 `src/mutable`
- **`mutable/vector`**：实现位于 `src/mutable`
- **`arithmetic`**：实现位于 `src/arithmetic`
- **`algebra`**：实现位于 `src/algebra`
- **`backends/default`**：实现位于 `src/backends/default`
- **`error`**：实现位于 `src/error`
