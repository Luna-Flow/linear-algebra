# `linear-algebra/arithmetic`

This page documents the public API exported by
`Luna-Flow/linear-algebra/arithmetic` in the current `0.4.0` repository state.

## Purpose

`arithmetic` owns operation-level traits used by the linear-algebra package. An
operation trait means “this operation is available”; it does not state algebraic
laws. Algebraic law-bearing structure belongs in `linear-algebra/algebra`.

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

```moonbit
pub(open) trait Abs {
  fn abs(Self) -> Self
}
```

Absolute-value operation. Implemented for:

- `Int`
- `Float`
- `Double`

## `ApproxEq`

```moonbit
pub(open) trait ApproxEq {
  fn approx_eq(Self, Self) -> Bool
}
```

Approximate equality operation. It is an operation-level capability, not an
equivalence-law claim. Implemented for:

- `Int`
- `Float`
- `Double`

## `CheckedDiv`

```moonbit
pub(open) trait CheckedDiv {
  fn checked_div(Self, Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

Checked division operation using `ArithmeticContext`. Implemented for:

- `Float`
- `Double`

## `CheckedSqrt`

```moonbit
pub(open) trait CheckedSqrt {
  fn checked_sqrt(Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

Checked square-root operation using `ArithmeticContext`. Implemented for:

- `Float`
- `Double`

## `CheckedCompare`

```moonbit
pub(open) trait CheckedCompare {
  fn checked_compare(Self, Self) -> Result[Int, ArithmeticError]
}
```

Checked scalar comparison. Implemented for:

- `Float`
- `Double`

## Boundary

This package must not import matrix, vector, or backend types. It is below
`algebra` and all backend packages in the dependency direction.
