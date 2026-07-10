# 接入 Algebra 生态

`algebra` 描述向量和矩阵对象整体的数学能力。外部库只应实现运算含义、封闭性与
所有权行为真正符合自身类型的 trait。

## 选择 Algebra 接入级别

| 路径 | Trait | 前置条件 | 数学承诺 |
|---|---|---|---|
| Shape | `VectorShape` | 无 | 返回向量长度 |
| Vector 1 | `AdditiveVector` | `VectorShape + Add + Neg + Sub` | 在同一类型内完成加法、取负和减法 |
| Vector 2 | `VecMulVector` | `AdditiveVector + Mul` | `Mul` 表示逐元素/Hadamard 乘法 |
| Shape | `MatrixShape` | 无 | 返回矩阵形状 |
| Matrix 1 | `TransposeMatrix` | `MatrixShape` | 转置返回同一矩阵类型 |
| Matrix 2 | `AdditiveMatrix` | `TransposeMatrix + Add + Neg + Sub` | 在同一类型内完成矩阵加法、取负和减法 |
| Matrix 3 | `MatMulMatrix` | `AdditiveMatrix + Mul` | `Mul` 表示矩阵乘法 |

应停在下游算法需要的最小级别。Shape 不代表元素访问；`TransposeMatrix` 不代表
矩阵乘法；`AdditiveVector` 不代表内积、范数、标量作用或逐元素乘法。

## 运算符边界

较强的 trait 复用 MoonBit 运算符并返回 `Self`，而不是 `Result`。实现前需要确认：

- 运算符已有含义与 trait 一致，尤其 `MatMulMatrix` 的 `Mul` 必须表示矩阵乘法。
- 结果封闭在同一个具体类型中。
- 运行时形状前置条件及失败行为已经写入文档。
- 运算不会静默切换后端或所有权模型。

动态长方形矩阵可能因形状不兼容而无法相乘。`MatMulMatrix` 本身不定义受检错误通道。
需要 checked API 的后端应保留自己的受检方法，并只在运算符契约合理时实现该 trait。

## Algebra 与 Container 相互独立

| 需求 | 使用的层 |
|---|---|
| 观察元素或转换存储 | `container` read/build 字典 |
| 表达封闭的整体数学运算 | `algebra` trait |
| 两者都需要 | 分别实现对应 trait 并发布 container 字典 |

`MatrixShape` 是语义形状能力，不是受检元素访问。algebra 转置返回同一类型；
container 转置可以构造不同目标类型。

不要仅为了容器互操作而实现宽泛的标量 trait。只有后端真正支持相应定律和操作时，
才直接使用 `Luna-Flow/luna-generic` 与 `Luna-Flow/arithmetic`。

## 实现放在哪里

公开运算符与 algebra 实现通常应位于具体类型所属包，让类型作者决定运算语义。
如果确实需要独立互操作包，应在该包中定义自己拥有的 wrapper 类型，再为 wrapper
实现 trait。不要假设 bridge 包可以安全重定义一个不归自己所有的外部类型运算符。

## 同类型封闭示例

这里刻意定义的是 `1x1` 矩阵，而不是把标量伪装成任意动态矩阵。对 `1x1` 矩阵而言，
转置就是恒等操作，元素加法就是矩阵加法，唯一元素之间的乘积也正是标准矩阵乘法。
固定形状保证所有运算封闭，并且不存在运行时形状失败。

```moonbit check
///|
struct EcosystemScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for EcosystemScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for EcosystemScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for EcosystemScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for EcosystemScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for EcosystemScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for EcosystemScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveMatrix for EcosystemScalarMatrix

///|
impl @algebra.MatMulMatrix for EcosystemScalarMatrix

///|
fn[M : @algebra.MatMulMatrix] ecosystem_gram(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "external algebra type participates by capability" {
  let matrix : EcosystemScalarMatrix = { value: 3 }
  let other : EcosystemScalarMatrix = { value: 4 }
  inspect((matrix + other).value, content="7")
  inspect(matrix.transpose().value, content="3")
  inspect(ecosystem_gram(matrix).value, content="9")
}
```

外部库可以停在 `MatrixShape`、`TransposeMatrix` 或 `AdditiveMatrix`，后续级别不是
强制要求。动态矩阵后端还必须另外定义形状不兼容时的运算符行为，不能照搬这个固定形状
示例的假设。

## 接入检查清单

- 选择符合类型与算法需求的最小 trait。
- 确认 `Add` / `Neg` / `Sub` / `Mul` 的含义与 trait 一致。
- 测试封闭性、形状、转置后的形状，以及该类型支持的代表性代数定律。
- 对有运行时形状前置条件的运算符测试非法形状行为。
- 记录分配、共享存储和隐藏修改行为。
- 不要把内积、范数、标量作用、分解或求解器塞进现有 trait。
- 如需元素级互操作，单独添加 container 字典。
