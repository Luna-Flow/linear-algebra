# `linear-algebra/arithmetic`

API baseline for `Luna-Flow/linear-algebra/arithmetic` in the current `0.4.4`
repository state.

## Purpose

`arithmetic` owns operation-level traits used by the linear-algebra package. An
operation trait means “this operation is available”; it does not state algebraic
laws. Algebraic law-bearing structure belongs in `linear-algebra/algebra`.

## Project Setup

If you want to use the linear-algebra operation traits together with the shared
upstream abstractions, start with:

```sh
moon add Luna-Flow/linear-algebra@0.4.4
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

## Re-exported Types

From `Luna-Flow/arithmetic`:

- `ArithmeticContext`
- `ArithmeticError`
- `ArithmeticErrorKind`
- `FpClass`
- `RoundingMode`

These preserve their upstream behavior and are used by checked operations.

## Re-exported Operation Traits

From `Luna-Flow/luna-generic`:

- `Zero`
- `One`
- `Inverse`
- `Conjugate`

From `Luna-Flow/arithmetic`:

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

Absolute-value operation. Implemented for:

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

Approximate equality operation. It is an operation-level capability, not an
equivalence-law claim. Implemented for:

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

Checked division operation using `ArithmeticContext`. Implemented for:

- `Float`
- `Double`

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

Checked square-root operation using `ArithmeticContext`. Implemented for:

- `Float`
- `Double`

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

Checked scalar comparison. Implemented for:

- `Float`
- `Double`

## Boundary

This package must not import matrix, vector, or backend types. In the
dependency graph, it sits below `algebra` and all backend packages.
