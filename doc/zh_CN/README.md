# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.12 - Correctness、Diagnostics 与 Documentation Alignment

本文档描述已发布 **v0.2.12** 的内容，覆盖 `0.2.11` 之后落地的实现与文档更新。

### 包定位

- **`immut`**：不可变、值语义导向的 `Matrix`、`Vector` 与 `MatrixFn` 类型，适合持久化数据和显式 copy-on-update 语义。
- **`mutable`**：执行导向的 `Matrix` 与 `Vector` 类型，支持原地更新、`Transpose` 视图、`RowView` / `ColView`，并保留 `js`、`wasm`、`wasm-gc`、`native` 的后端优化实现。
- **共享核心，不同执行模型**：构造器和核心代数操作在两个包之间保持对齐，但修改语义与访问语义是有意区分的。

### v0.2.12 的核心变化

- **公开访问器的严格边界检查**：公开的矩阵、视图与转置视图访问器现在都会一致地拒绝越界索引，包括 `0xN` 和 `Nx0` 等边界形状。
- **不可变访问语义强化**：`immut.Matrix` 的索引访问与 copy-on-update setter 现在会验证真实的二维边界，而不再允许误落到扁平存储中的其他元素。
- **跨包语义对齐强化**：`immut` / `mutable` 共享操作在边界行为上更加明确地对齐，包括 same-index swap 的 no-op 语义。
- **Benchmark 诊断扩展**：benchmark 栈现在包含更丰富的 replay/testing support、单 case whitebox runner，以及本地报告链路中更好的 metadata/diagnostic handling。
- **文档刷新**：README 和 matrix API 参考文档已按当前真实导出接口重写，清除了陈旧或重复描述。
- **正确性审计台账**：仓库现在包含一个可跟踪的 correctness checklist，用于记录已验证行为、已修复问题与后续结构性风险。

### API 指导与性能建议

- **核心代数 API**：`make`、`transpose`、`+`、`-`、`*`、`trace` 以及矩阵/向量转换等共享操作，目标是在 `immut` 与 `mutable` 之间保持语义对齐。
- **随机访问**：在 `mutable` 中，如需高性能随机访问，优先使用 `.get(i, j)` 和 `.set(i, j, val)`。
- **结构化视图**：在 `mutable` 中，如需反复处理某一行或某一列，优先使用 `row_view()` / `col_view()`，而不是依赖 `matrix[row]` 的便捷语法。
- **严格边界检查**：公开的矩阵、视图与转置视图访问器现在都会一致地拒绝越界索引，包括 `0xN` 和 `Nx0` 等边界形状。
- **MatrixFn 对齐**：`immut.MatrixFn` 现在与具象矩阵共享非负维度约束和空矩阵语义。
- **公开接口边界**：内部的分解辅助函数仍然属于实现细节，包使用者应依赖文档化的公开矩阵方法。

### 主要特性

- **同时支持可变与不可变**：完整的 `Matrix` 与 `Vector` 体系，分别面向值语义工作负载和执行导向工作负载。
- **高级操作**：包含 determinant、inverse、rank、Cholesky decomposition、eigen 相关例程、row elimination、transpose view，以及矩阵/向量转换。
- **共享数据模型 + 后端调优内核**：`mutable` 仍保留 Native、Wasm、JS、Wasm GC 的后端优化执行路径，但核心矩阵存储模型已经统一。
- **Benchmark 基础设施**：`bench/`、`src/perf_support` 和 `src/perf_runner` 现在共同组成了完整的 steady-state benchmark 子系统，用于后端对比与诊断复现。
- **正确性优先**：当前覆盖范围包括不可变语义检查、跨包一致性检查、determinant/rank/inverse 对齐，以及数值行为回归测试。
- **可审计的公开契约**：边界行为、swap 语义、benchmark fixture 与文档一致性，现在都作为仓库正确性叙事的一部分被更明确地跟踪。

### Benchmark 相关包

- **`perf`**：供 `moon bench` 使用的 benchmark 入口包。
- **`perf_support`**：公开 fixture 元数据、case 注册表、运行时加载器，以及用于执行 benchmark case 的辅助函数。
- **`perf_runner`**：用于单 case 诊断、采样与结果复现的运行器。

### 快速开始

```moonbit
let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let imm_updated = imm.set(0, 1, 9)

let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant()
let maybe_inv = m.inverse()
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

## 版本历史

| 版本 | 日期 | 状态 | 说明 |
| --- | --- | --- | --- |
| `0.2.12` | 2026-06-06 | 已发布到 mooncakes | 严格边界契约统一、语义正确性修正、benchmark 诊断扩展，以及文档/审计刷新 |
| `0.2.11` | 2026-05-27 | 上一发布基线 | mutable 内核性能优化、独立 wasm-gc 后端、benchmark/报告扩展与 API/文档对齐 |
| `0.2.10` | 2026-05-27 | 上一发布基线 | 统一扁平化 mutable 存储、矩阵视图、一致性覆盖、benchmark 扩展与发布流程对齐 |
| `0.2.9` | 2026-02-03 | 已发布到 mooncakes | 基于较早的 `3328195` 发布状态发布 |
| `0.2.8` | 2026-02-03 | 历史基线 | 后续工作的算法与稳定性对比基线 |

## 当前仓库亮点

- **当前版本主叙事（0.2.12）**：
  - 公开的 matrix、view 与 transpose accessor 现在都会在全库范围内强制执行显式 bounds contract，包括零行和零列边界形状。
  - `immut.Matrix` 与 `mutable.Matrix` 在共享 correctness semantics 上进一步对齐，同时仍保留值语义与 mutation 语义的执行模型差异。
  - benchmark 栈现在在本地 benchmark workflow 中具备更强的 diagnostic replay/test coverage 与 metadata handling。
  - 仓库现在包含可跟踪的 correctness checklist，README 与 matrix API docs 也已经按真实 exported surface 更新。

- **上一版本主叙事（0.2.11）**：
  - `mutable.Matrix` 在 `0.2.10` 统一扁平存储的基础上，继续获得了多后端核心路径优化和独立 `wasm-gc` 实现。
  - 公共数值 API 已围绕 `Field` / `Num` / `Tolerance` 对齐，不可变 determinant 的文档也已同步到简化后的约束集合。
  - benchmark 体系现在包含运行时 fixture 加载、扩展 case 元数据、更丰富 summary 输出、本地 dashboard、可选 Rust 对照，以及通过 `perf_runner` 进行诊断复现的路径。
  - 发布清单、benchmark 文档、包概览与多语言 README 已统一到 `0.2.11` 的发布叙事。

- **算法与稳定性（0.2.8）**：
  - 引入了 determinant、inverse、rank、eigen 相关能力所依赖的 LU / QR 分解支持。
  - 将 determinant 与 rank 的行为推进到更稳定的消元实现方向。

- **Native 优化（0.2.7）**：
  - 在 Native 后端引入基于转置 + dot-product 的矩阵乘法策略，相比朴素实现可获得超过 2 倍性能提升。
  - 优化了 `make`、`new`、`transpose`，去除了热点路径中的昂贵整数除法。

- **性能重构（0.2.4）**：
  - 优化了 `mapi`、`each_row_col` 等次级工具。
  - 改进了混合矩阵乘法与向量线性组合性能。

- **其他修正与重命名**：
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - 修正了 `0x0` 矩阵的 determinant 行为。
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
