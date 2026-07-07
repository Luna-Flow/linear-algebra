# algebra 设计

## 职责

- 表示线性代数需要的语义数学结构。
- 将结构级 trait 与操作级 arithmetic trait 分开。
- 避免把近似浮点行为写成精确代数律。
- 用 `AdditiveVector` / `TransposeMatrix` 直接表达对象 shape 和闭合运算。
- 当承载类型能合法提供全局 identity 时，用 `AddGroup`、`Semiring`、`Ring` 等上游带律 traits 组合出更强代数结构。

## 非职责

- 不导入 稠密 后端类型。
- 不定义存储、mutation 或算法执行 trait。
- 不把 inner product、norm 等标量值函子放入核心结构层。
- 不在缺少显式标量作用模型时引入 `Module` 或 `VectorSpace`。
- 不用包内 shape-dependent zero 替代上游 `Zero`。
