# `linear-algebra/arithmetic`

本页记录当前 `0.4.6` 仓库中 `Luna-Flow/linear-algebra/arithmetic` 的公开 API 基线。

## 职责

`arithmetic` 拥有线性代数包使用的操作级 traits。操作 trait 只表示“该操作可用”，不声明代数律。带代数律的结构属于 `linear-algebra/algebra`。

## 项目配置

如果你要把线性代数操作 trait 和共享上游抽象一起使用，先加上这三条依赖：

```sh
moon add Luna-Flow/linear-algebra@0.4.6
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推荐的 `moon.pkg` 导入写法：

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

## 重导出的类型

来自 `Luna-Flow/arithmetic`：

- `ArithmeticContext`
- `ArithmeticError`
- `ArithmeticErrorKind`
- `FpClass`
- `RoundingMode`

这些类型保持上游行为，用于带检查的运算。

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

```moonbit check
///|
test "Abs captures absolute-value support" {
  inspect(@la_arithmetic.Abs::abs(-3), content="3")
}
```

绝对值操作。当前实现给：

- `Int`
- `Float`
- `Double`

## `ApproxEq`

```moonbit check
///|
test "ApproxEq captures approximate comparison support" {
  inspect(
    @la_arithmetic.ApproxEq::approx_eq(1.0, 1.0 + 1.0e-13),
    content="true",
  )
}
```

近似相等操作。它是操作能力，不是等价关系公理声明。当前实现给：

- `Int`
- `Float`
- `Double`

## `CheckedDiv`

```moonbit check
///|
test "CheckedDiv carries context-aware division" {
  let ctx : @lf_arith.ArithmeticContext = @lf_arith.ArithmeticContext::new(32)
  inspect(
    @la_arithmetic.CheckedDiv::checked_div(6.0, 2.0, ctx).unwrap(),
    content="3",
  )
}
```

带 `ArithmeticContext` 的除法检查。当前实现给 `Float` 和 `Double`。

## `CheckedSqrt`

```moonbit check
///|
test "CheckedSqrt carries context-aware square root" {
  let ctx : @lf_arith.ArithmeticContext = @lf_arith.ArithmeticContext::new(32)
  inspect(
    @la_arithmetic.CheckedSqrt::checked_sqrt(9.0, ctx).unwrap(),
    content="3",
  )
}
```

带 `ArithmeticContext` 的平方根检查。当前实现给 `Float` 和 `Double`。

## `CheckedCompare`

```moonbit check
///|
test "CheckedCompare returns an explicit ordering result" {
  inspect(
    @la_arithmetic.CheckedCompare::checked_compare(2.0, 3.0).unwrap(),
    content="-1",
  )
}
```

带检查的标量比较。当前实现给 `Float` 和 `Double`。

## 边界

本包不能导入矩阵、向量或后端类型。在依赖方向上，它位于 `algebra` 和所有后端包之下。
