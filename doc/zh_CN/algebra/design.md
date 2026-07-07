# algebra 设计

## 职责

- 表示线性代数需要的语义数学结构。
- 将结构级 trait 与操作级算术 trait 分开。
- 避免把近似浮点行为写成精确代数律。
- 用 `AdditiveVector` / `TransposeMatrix` 直接表达对象形状和同类型闭合运算。
- 当承载类型能合法提供全局单位元时，用 `AddGroup`、`Semiring`、`Ring` 等上游带律 trait 组合出更强代数结构。

## 非职责

- 不导入稠密后端类型。
- 不定义存储、可变操作或算法执行 trait。
- 不把内积、范数等返回标量值的映射放入核心结构层。
- 不在缺少显式标量作用模型时引入 `Module` 或 `VectorSpace`。
- 不用包内依赖形状的零元替代上游 `Zero`。
