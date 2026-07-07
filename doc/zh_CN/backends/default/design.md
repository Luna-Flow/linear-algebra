# backends/default 设计

## 职责

- 将 `immut` 和 `mutable` 呈现为默认 稠密 后端。
- 为默认 稠密 matrix/vector 类型实现 capability traits。
- 提供小型泛型辅助函数来验证 trait dispatch。

## 非职责

- 不重新定义标量代数或算术律。
- 不要求未来后端必须是 稠密 或 contiguous。
- 不把标量值映射放入核心线性代数 trait 表面。

## 扩展模型

未来 sparse、lazy、static-size、GPU 或外部库后端应直接实现相同结构 traits，不需要先转换成 `DenseMatrix` 或 `DenseVector`。
