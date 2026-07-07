# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.0 - 带检查的矩阵 API 与分层能力

本文档描述当前 **v0.4.0** 仓库状态。本版本把可能失败的矩阵操作改为返回
`Result[..., LinearAlgebraError]`，并加入面向泛型算法的分层能力包。

### 破坏性变更

mooncakes 上的最新发布版本已经是 `0.3.0`，因此这些不兼容的公开 API 变更归入
`0.4.0`。

- `immut.Matrix` 的 `matmul`、`trace`、`determinant`、`pow` 现在返回
  `Result[..., LinearAlgebraError]`。
- `mutable.Matrix` 的 `trace`、`determinant`、`inverse`、`is_invertible`、
  `mul_vec`、`pow`、`matrix_power`、`mean`、`variance`、`std_dev`、
  `max_element`、`min_element` 现在返回 `Result[..., LinearAlgebraError]`。
- 旧的 abort 行为以及 `inverse` 的旧 `Option` 返回语义保留在对应的
  `unchecked_*` 方法中。
- 迁移时，如果调用点已经保证前置条件，可以临时使用 `.unwrap()` 或切换到
  对应 `unchecked_*`；面向用户输入或外部数据的代码应显式处理 `Err`。

### 分层架构

- **`arithmetic`**：面向线性代数的操作能力层。它复用 `Luna-Flow/luna-generic` 和 `Luna-Flow/arithmetic` 中的标量操作 trait，并补充少量只表达“这个操作可用”的 trait。
- **`algebra`**：数学结构层。它重导出现有 Luna Flow 代数结构，并补充 `AdditiveVector`、`TransposeMatrix` 与 `FloatingScalarOps` 等线性代数结构 trait。
- **`backends/default`**：默认稠密后端。它提供本包拥有的 `DenseVector` / `DenseMatrix` 与 `ImmutableDenseVector` / `ImmutableDenseMatrix` 包装类型，底层分别使用 `mutable` 与 `immut`。
- **`error`**：带检查 API 共用的错误类型，覆盖形状不匹配、负指数、空矩阵、奇异矩阵和后端不支持等情况。
- **trait 驱动算法**：后端无关代码应依赖 `MatrixShape`、`AdditiveVector`、`VecMulVector`、`TransposeMatrix` 与 `MatMulMatrix` 这类最小能力，而不是依赖某个具体矩阵或向量类型。

把向量或矩阵映射成标量的能力，例如内积或范数，属于具体后端或专门算法的职责，不放进核心结构 trait 层。

默认稠密实现只是一个后端，不是生态中心。算法应依赖线性代数 trait，而不是具体的稠密矩阵/向量类型。

### 包定位

- **`immut`**：不可变、值语义导向的 `Matrix`、`Vector` 与 `MatrixFn` 类型，适合持久化数据和显式 copy-on-update 语义。
- **`mutable`**：执行导向的 `Matrix` 与 `Vector` 类型，支持原地更新、`Transpose` 视图、`RowView` / `ColView`，并保留 `js`、`wasm`、`wasm-gc`、`native` 的后端优化实现。
- **`arithmetic` / `algebra`**：线性代数上层能力表示层；不依赖默认稠密后端。
- **`backends/default`**：把 `immut` 与 `mutable` 纳入默认后端入口。
- **共享核心，不同执行模型**：构造器和核心代数操作在两个包之间保持对齐，但修改语义与访问语义是有意区分的。

### v0.4.0 的核心变化

- **带检查的矩阵契约**：形状、指数、空矩阵和奇异矩阵等运行时失败现在通过 `LinearAlgebraError` 表达。
- **旧行为显式化**：`unchecked_*` 方法保留旧的 abort 行为；`unchecked_inverse` 保留旧的 `Option` 返回语义。
- **公开错误包**：`linear-algebra/error` 提供 `LinearAlgebraError`、`LinearAlgebraErrorKind`、构造器和 `is_*` 判断方法。
- **共享平方根能力**：数值矩阵 API 现在使用 `Luna-Flow/arithmetic.Sqrt`，不再维护包内独立 trait；`mutable` 会公开重导出该共享 trait。
- **目标侧整数嵌入**：泛型整数转换使用 `IntegralHomomorphism::from_integral`，与新版 `Luna-Flow/luna-generic` 模型一致。
- **面向生态的约束**：自定义标量类型可以一次实现 Luna Flow 共享 traits，并用于所有兼容的生态包。
- **多后端一致性**：Native、JS、Wasm 与 Wasm GC 使用相同的算术能力标识和显式 trait 调用。
- **兼容边界**：`Tolerance` 在本版本仍属于 `mutable`，尚未迁移到 `arithmetic`。

### API 指导与性能建议

- **核心代数 API**：`make`、`transpose`、`+`、`-`、`*`、`trace` 以及矩阵/向量转换等共享操作，目标是在 `immut` 与 `mutable` 之间保持语义对齐。
- **随机访问**：在 `mutable` 中，如需高性能随机访问，优先使用 `.get(i, j)` 和 `.set(i, j, val)`。
- **结构化视图**：在 `mutable` 中，如需反复处理某一行或某一列，优先使用 `row_view()` / `col_view()`，而不是依赖 `matrix[row]` 的便捷语法。
- **严格边界检查**：公开的矩阵、视图与转置视图访问器现在都会一致地拒绝越界索引，包括 `0xN` 和 `Nx0` 等边界形状。
- **MatrixFn 对齐**：`immut.MatrixFn` 现在与具象矩阵共享非负维度约束和空矩阵语义。
- **公开接口边界**：内部的分解辅助函数仍然属于实现细节，包使用者应依赖文档化的公开矩阵方法。

### 主要特性

- **同时支持可变与不可变**：完整的 `Matrix` 与 `Vector` 体系，分别面向值语义工作负载和执行导向工作负载。
- **高级操作**：包含行列式、逆矩阵、秩、Cholesky 分解、特征值相关例程、行消元、转置视图，以及矩阵/向量转换。
- **共享数据模型 + 后端调优内核**：`mutable` 仍保留 Native、Wasm、JS、Wasm GC 的后端优化执行路径，但核心矩阵存储模型已经统一。
- **基准测试基础设施**：`bench/`、`src/perf_support` 和 `src/perf_runner` 现在共同组成了完整的稳态基准测试子系统，用于后端对比与诊断复现。
- **正确性优先**：当前覆盖范围包括不可变语义检查、跨包一致性检查、行列式/秩/逆矩阵对齐，以及数值行为回归测试。
- **可审计的公开契约**：边界行为、交换语义、基准测试用例与文档一致性，现在都作为仓库正确性叙事的一部分被更明确地跟踪。

### 基准测试相关包

- **`perf`**：供 `moon bench` 使用的基准测试入口包。
- **`perf_support`**：公开测试用例元数据、用例注册表、运行时加载器，以及用于执行基准测试用例的辅助函数。
- **`perf_runner`**：用于单个用例诊断、采样与结果复现的运行器。

### 快速开始

```moonbit
let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let imm_updated = imm.set(0, 1, 9)

let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant().unwrap()
let inv = m.inverse().unwrap()
let row0 = m.row_view(0).to_array()
```

### 文档

完整 API 文档可见 [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra)。

我们提供多语言文档：

- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

多语言 README：

- 🇺🇸 [README.md](../../README.md)
- 🇨🇳 [README.md](./README.md)
- 🇯🇵 [README.md](../ja_JP/README.md)

新增包文档入口：

- [arithmetic API](./arithmetic/api.md)
- [algebra API](./algebra/api.md)
- [backends/default API](./backends/default/api.md)
- [error API](./error/api.md)

## 版本历史

| 版本 | 日期 | 状态 | 说明 |
| --- | --- | --- | --- |
| `0.4.0` | 2026-07-07 | 当前仓库版本 | 引入带检查的矩阵 API、结构化线性代数错误、分层能力包和默认后端包装类型 |
| `0.3.0` | 2026-06-14 | 已发布到 mooncakes | 接入共享 `arithmetic.Sqrt`、新版 `luna-generic` 同态和统一数值能力身份 |
| `0.2.12` | 2026-06-06 | 已发布到 mooncakes | 严格边界契约统一、语义正确性修正、基准测试诊断扩展，以及文档/审计刷新 |
| `0.2.11` | 2026-05-27 | 上一发布基线 | 可变矩阵内核性能优化、独立 wasm-gc 后端、基准测试/报告扩展与 API/文档对齐 |
| `0.2.10` | 2026-05-27 | 上一发布基线 | 统一扁平化可变存储、矩阵视图、一致性覆盖、基准测试扩展与发布流程对齐 |
| `0.2.9` | 2026-02-03 | 已发布到 mooncakes | 基于较早的 `3328195` 发布状态发布 |
| `0.2.8` | 2026-02-03 | 历史基线 | 后续工作的算法与稳定性对比基线 |

## 当前仓库亮点

- **当前版本主叙事（0.4.0）**：
  - 可能因运行时条件失败的矩阵操作现在返回 `Result[..., LinearAlgebraError]`。
  - 旧矩阵行为保留在显式的 `unchecked_*` 方法中。
  - `linear-algebra/error` 记录带检查 API 共用的错误类型。
  - `arithmetic`、`algebra` 与 `backends/default` 提供新的 trait 分层，供泛型算法使用。

- **上一版本主叙事（0.3.0）**：
  - 依赖平方根的矩阵算法现在要求共享的 `arithmetic.Sqrt` 能力。
  - `mutable.Sqrt` 是 `arithmetic.Sqrt` 的公开重导出；旧的包内 trait 与标量实现已删除。
  - 整数测试数据和转换辅助函数现在使用目标侧 `IntegralHomomorphism::from_integral`。
  - 自定义数值类型应实现 `luna-generic` 与 `arithmetic` 中的共享能力，而不是 linear-algebra 专属 traits。

- **更早版本主叙事（0.2.12）**：
  - 公开矩阵、视图与转置访问器强制执行显式边界契约，包括零行和零列形状。
  - `immut.Matrix` 与 `mutable.Matrix` 在共享正确性语义上保持对齐，同时保留值语义与可变执行模型的差异。
  - 基准测试诊断与正确性审计对应 `0.2.12` 导出接口。

- **更早版本主叙事（0.2.11）**：
  - `mutable.Matrix` 在 `0.2.10` 统一扁平存储的基础上，继续获得了多后端核心路径优化和独立 `wasm-gc` 实现。
  - 公共数值 API 已围绕 `Field` / `Num` / `Tolerance` 对齐，不可变矩阵行列式的文档也已同步到简化后的约束集合。
  - 基准测试体系现在包含运行时测试用例加载、扩展用例元数据、更丰富的摘要输出、本地仪表盘、可选 Rust 对照，以及通过 `perf_runner` 进行诊断复现的路径。
  - 发布清单、基准测试文档、包概览与多语言 README 已统一到 `0.2.11` 的发布叙事。

- **算法与稳定性（0.2.8）**：
  - 引入了行列式、逆矩阵、秩和特征值相关能力所依赖的 LU / QR 分解支持。
  - 将行列式与秩的行为推进到更稳定的消元实现方向。

- **Native 优化（0.2.7）**：
  - 在 Native 后端引入基于转置 + dot-product 的矩阵乘法策略，相比朴素实现可获得超过 2 倍性能提升。
  - 优化了 `make`、`new`、`transpose`，去除了热点路径中的昂贵整数除法。

- **性能重构（0.2.4）**：
  - 优化了 `mapi`、`each_row_col` 等次级工具。
  - 改进了混合矩阵乘法与向量线性组合性能。

- **其他修正与重命名**：
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - 修正了 `0x0` 矩阵的行列式行为。
  - 修正了向量与矩阵转换时的拷贝行为。

## 开发

常用本地命令：

```bash
moon fmt
moon check
moon test --enable-coverage
./run_test.sh
```

`run_test.sh` 会在 `wasm-gc`、`js`、`native`、`wasm` 上跑 `mutable` 包测试。

## 发布清单

触发发布工作流前：

1. 先把 `moon.mod` bump 到目标发布版本。
2. 更新 `README.md`，确保发布说明与版本历史和包内容一致。
3. 运行 `moon check` 与 `./run_test.sh`。
4. 触发 `publish-package`；工作流会直接发布 `moon.mod` 里声明的版本。

如果工作流提示版本重复，说明包管理器中已经存在该版本，需要先 bump 新版本。

贡献说明见 [CONTRIBUTING.md](./CONTRIBUTING.md)。
