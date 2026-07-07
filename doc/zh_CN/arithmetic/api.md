# `linear-algebra/arithmetic`

本文档描述当前 `0.4.0` 仓库中 `Luna-Flow/linear-algebra/arithmetic` 的公开 API。

## 职责

`arithmetic` 拥有线性代数包使用的操作级 traits。操作 trait 只表示“该操作可用”，不声明代数律。带代数律的结构属于 `linear-algebra/algebra`。

## 重导出的类型

来自 `Luna-Flow/arithmetic`：

- `ArithmeticContext`
- `ArithmeticError`
- `ArithmeticErrorKind`
- `FpClass`
- `RoundingMode`

这些类型保持上游行为，用于 checked operations。

## 重导出的操作 traits

来自 `Luna-Flow/luna-generic`：

- `Zero`
- `One`
- `Inverse`
- `Conjugate`

来自 `Luna-Flow/arithmetic`：

- `Sqrt`
- `Cbrt`
- `Power`
- `Constants`
- `Exponential`
- `Logarithmic`
- `SqrtChecked`
- `DivChecked`
- `CompareChecked`

## `Abs`

```moonbit
pub(open) trait Abs {
  fn abs(Self) -> Self
}
```

绝对值操作。当前实现给：

- `Int`
- `Float`
- `Double`

## `ApproxEq`

```moonbit
pub(open) trait ApproxEq {
  fn approx_eq(Self, Self) -> Bool
}
```

近似相等操作。它是操作能力，不是等价关系公理声明。当前实现给：

- `Int`
- `Float`
- `Double`

## `CheckedDiv`

```moonbit
pub(open) trait CheckedDiv {
  fn checked_div(Self, Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

带 `ArithmeticContext` 的 checked division。当前实现给 `Float` 和 `Double`。

## `CheckedSqrt`

```moonbit
pub(open) trait CheckedSqrt {
  fn checked_sqrt(Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

带 `ArithmeticContext` 的 checked square root。当前实现给 `Float` 和 `Double`。

## `CheckedCompare`

```moonbit
pub(open) trait CheckedCompare {
  fn checked_compare(Self, Self) -> Result[Int, ArithmeticError]
}
```

带检查的标量比较。当前实现给 `Float` 和 `Double`。

## 边界

本包不能导入矩阵、向量或后端类型。依赖方向上，它位于 `algebra` 和所有后端包之下。
