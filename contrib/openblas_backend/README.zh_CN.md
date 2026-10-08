# OpenBLAS 后端（暂时撤下）

[English](./README.md) | [日本語](./README.ja_JP.md)

本目录保存原 `Luna-Flow/linear-algebra/backends/openblas` 包：仅支持 native 的
OpenBLAS 后端，提供 `Float` / `Double` 的 `BlasMatrix[T]` 与 `BlasVector[T]`。
它位于 `src/` 之外，因此**不会**随模块构建、测试或发布；仓库其余部分不受影响。

## 撤下原因

该后端依赖 `Kaida-Amethyst/openblas` `0.1.3`（最新发布版本）。该包仍使用
MoonBit 0.10 已移除的 `typealias` 语法，位于 `cblas/cblas.mbt` 约第 86、97、220 行，
导致 native 构建解析失败，从而使整个模块的 `moon check --target all` 失败，
也迫使 `src/doc_*` 文档包只能在 native 下构建。撤下后，其余所有包（包括文档包）
都能在 `wasm-gc`、`js`、`native`、`wasm` 上构建和测试。上游尚无修复版本。

## 内容

- `src/`：迁移到 MoonBit 0.10 后的包源码（含 `extends.mbt`、`openblas_wbtest.mbt`、`moon.pkg`）。
- `doc/{en_US,zh_CN,ja_JP}/`：原 `doc/<locale>/backends/openblas/*` 页面，已标注撤下。
- `openblas_0.1.3_typealias.patch`：把上述三处声明改写为 `pub type Alias = Target` 的补丁。

在本地打过补丁的 `0.1.3` 上验证过：后端 native 检查无警告，15 个 native 测试与
文档中 12 个编译示例全部通过。

## 恢复步骤

1. `mv contrib/openblas_backend/src src/backends/openblas`。
2. 在 `moon.mod` 中重新加入可在 MoonBit 0.10 下编译的 `Kaida-Amethyst/openblas` 版本。
3. 把文档移回 `doc/<locale>/backends/openblas/`；建议用单独的 native 专用文档包暴露这些页面，
   而不是让 `src/doc_*` 重新依赖 `backends/openblas`。
4. 恢复 CI（`libopenblas-dev` 安装与 `moon test src/backends/openblas --target native`）。
5. 更新 README、`doc/*/README.md`、`doc/*/container/*` 与 `CHANGELOG.md`。

本地试用时可在依赖下载后执行（仅限本地实验）：
`patch .mooncakes/Kaida-Amethyst/openblas/cblas/cblas.mbt < contrib/openblas_backend/openblas_0.1.3_typealias.patch`。

## 其他托管方式

也可以把该后端交给 `openblas.mbt` 项目托管，让绑定与 `linear-algebra` 集成一同发布。
