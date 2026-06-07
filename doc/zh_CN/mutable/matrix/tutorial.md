# mutable/matrix 教程

本页用于说明这个模块的实际使用路径。 这里聚焦 Luna-Flow/linear-algebra 中的 mutable/matrix。

## 建议阅读顺序

1. 先看仓库 README 和 mutable/matrix 的 API 文档。
2. 从 `src/mutable` 中的构造入口或主入口开始。
3. 在依赖边界行为之前，先结合已有测试或示例验证语义。

## 实践建议

- 优先使用已文档化的入口，而不是内部辅助函数。
- 下游代码里显式记录运行时、数值或证明状态前提。
