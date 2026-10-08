# arithmetic API

`Luna-Flow/linear-algebra/arithmetic` is the scalar-operation layer of the
repository. It re-exports the scalar types and traits that linear-algebra code
uses from `Luna-Flow/luna-generic` and `Luna-Flow/arithmetic`, and adds five
small operation traits: `Abs`, `ApproxEq`, `CheckedDiv`, `CheckedSqrt` and
`CheckedCompare`. An operation trait says that an operation is available; it
does not claim algebraic laws.

Source: [`src/arithmetic/operation_traits.mbt`](../../../src/arithmetic/operation_traits.mbt),
[`src/arithmetic/alias.mbt`](../../../src/arithmetic/alias.mbt). The reasoning
is in the [arithmetic design](../design/arithmetic.md).

## Import

The examples on this page use these aliases:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

## Re-exported names

The package re-exports these upstream names with `pub using`, so
`@la_arithmetic.Sqrt` and `@lf_arith.Sqrt` denote the same trait. Their
behaviour is documented upstream: [luna-generic](https://lunaflow.cn/en/luna-generic/)
and [arithmetic](https://lunaflow.cn/en/arithmetic/).

| Name | Kind | From | Meaning |
| --- | --- | --- | --- |
| `Zero` | trait | luna-generic | additive identity `zero()` |
| `One` | trait | luna-generic | multiplicative identity `one()` |
| `Inverse` | trait | luna-generic | multiplicative inverse `inv(x)` |
| `Conjugate` | trait | luna-generic | involution `conjugate(x)`; the builtin real types have no instance |
| `Sqrt` | trait | arithmetic | unchecked `sqrt(x)` |
| `Cbrt` | trait | arithmetic | unchecked `cbrt(x)` |
| `Power` | trait | arithmetic | unchecked `pow(x, y)` |
| `Exponential` | trait | arithmetic | `exp(x)`, `exp2(x)` |
| `Logarithmic` | trait | arithmetic | `ln(x)`, `log2(x)`, `log10(x)` |
| `Constants` | trait | arithmetic | `pi()`, `tau()`, `e()` |
| `SqrtChecked` | trait | arithmetic | `sqrt_checked(x, ctx)` returning `Result` |
| `DivChecked` | trait | arithmetic | `div_checked(x, y, ctx)` returning `Result` |
| `CompareChecked` | trait | arithmetic | `compare_checked(x, y)` returning `Result[Int, _]` |
| `ArithmeticContext` | type | arithmetic | precision and rounding settings passed to checked operations |
| `ArithmeticError` | type | arithmetic | structured scalar error with `kind` and `message` |
| `ArithmeticErrorKind` | type | arithmetic | `DivisionByZero`, `DomainError`, `UnorderedComparison`, ... |
| `FpClass` | type | arithmetic | `Finite`, `Infinity`, `NaN` |
| `RoundingMode` | type | arithmetic | `ToNearestEven`, `TowardZero`, ... |

## Absolute value

### `Abs`

`Abs` marks scalar types with an absolute value.

```mbti
pub(open) trait Abs {
  fn abs(Self) -> Self
}
pub impl Abs for Int
pub impl Abs for Float
pub impl Abs for Double
```

### `Abs::abs`

`Abs::abs` returns $|x|$.

```mbti
fn Abs::abs(Self) -> Self
```

The implementations delegate to `Num::abs` of `luna-generic`. For `Int`,
$|-2^{31}|$ wraps to $-2^{31}$, as in two's-complement arithmetic.

```moonbit check
///|
fn[T : @la_arithmetic.Abs] arith_api_magnitude(x : T) -> T {
  @la_arithmetic.Abs::abs(x)
}

///|
test "Abs on integers and doubles" {
  inspect(arith_api_magnitude(-3), content="3")
  inspect(arith_api_magnitude(-2.5), content="2.5")
}
```

## Approximate equality

### `ApproxEq`

`ApproxEq` marks scalar types with an approximate comparison.

```mbti
pub(open) trait ApproxEq {
  fn approx_eq(Self, Self) -> Bool
}
pub impl ApproxEq for Int
pub impl ApproxEq for Float
pub impl ApproxEq for Double
```

### `ApproxEq::approx_eq`

`ApproxEq::approx_eq` reports whether two values are within a fixed absolute
tolerance of each other.

```mbti
fn ApproxEq::approx_eq(Self, Self) -> Bool
```

| Type | Rule |
| --- | --- |
| `Int` | $a = b$ |
| `Float` | $\lvert a - b\rvert \le 10^{-6}$ |
| `Double` | $\lvert a - b\rvert \le 10^{-12}$ |

The tolerance is absolute, so it is too strict for large magnitudes and too
loose for tiny ones, and the relation is not transitive. It returns `false`
whenever an operand is NaN. See the [design page](../design/arithmetic.md) for
the consequences.

```moonbit check
///|
test "ApproxEq uses an absolute tolerance" {
  inspect(
    @la_arithmetic.ApproxEq::approx_eq(1.0, 1.0 + 1.0e-13),
    content="true",
  )
  inspect(
    @la_arithmetic.ApproxEq::approx_eq(1.0e20, 1.0e20 + 1.0e5),
    content="false",
  )
  inspect(@la_arithmetic.ApproxEq::approx_eq(3, 3), content="true")
}
```

## Checked operations

The checked traits return `Result[_, ArithmeticError]` instead of a NaN or an
infinity. The implementations for `Float` and `Double` delegate to the upstream
`DivChecked`, `SqrtChecked` and `CompareChecked` traits; they accept an
`ArithmeticContext` for interface uniformity but ignore it, because hardware
binary floating point has a fixed precision.

### `CheckedDiv`

`CheckedDiv` marks scalar types with a division that reports invalid operands.

```mbti
pub(open) trait CheckedDiv {
  fn checked_div(Self, Self, @Luna-Flow/arithmetic.ArithmeticContext) -> Result[Self, @Luna-Flow/arithmetic.ArithmeticError]
}
pub impl CheckedDiv for Float
pub impl CheckedDiv for Double
```

### `CheckedDiv::checked_div`

`CheckedDiv::checked_div(x, y, ctx)` returns `Ok(x / y)` or an error.

```mbti
fn CheckedDiv::checked_div(Self, Self, ArithmeticContext) -> Result[Self, ArithmeticError]
```

| Operands | Result |
| --- | --- |
| $0 / 0$ | `Err`, kind `DomainError` |
| $\pm\infty / \pm\infty$ | `Err`, kind `DomainError` |
| $x / 0$, $x \ne 0$ | `Err`, kind `DivisionByZero` |
| otherwise | `Ok(x / y)`, rounded to nearest |

### `CheckedSqrt`

`CheckedSqrt` marks scalar types with a square root that reports domain errors.

```mbti
pub(open) trait CheckedSqrt {
  fn checked_sqrt(Self, @Luna-Flow/arithmetic.ArithmeticContext) -> Result[Self, @Luna-Flow/arithmetic.ArithmeticError]
}
pub impl CheckedSqrt for Float
pub impl CheckedSqrt for Double
```

### `CheckedSqrt::checked_sqrt`

`CheckedSqrt::checked_sqrt(x, ctx)` returns `Ok(√x)` for $x \ge 0$ and an
error with kind `DomainError` for $x < 0$.

```mbti
fn CheckedSqrt::checked_sqrt(Self, ArithmeticContext) -> Result[Self, ArithmeticError]
```

A NaN argument is passed through as `Ok(NaN)`.

### `CheckedCompare`

`CheckedCompare` marks scalar types with a three-way comparison that reports
unordered operands.

```mbti
pub(open) trait CheckedCompare {
  fn checked_compare(Self, Self) -> Result[Int, @Luna-Flow/arithmetic.ArithmeticError]
}
pub impl CheckedCompare for Float
pub impl CheckedCompare for Double
```

### `CheckedCompare::checked_compare`

`CheckedCompare::checked_compare(x, y)` returns `Ok(-1)`, `Ok(0)` or `Ok(1)`
for $x < y$, $x = y$ and $x > y$, and an error with kind `UnorderedComparison`
when either operand is NaN.

```mbti
fn CheckedCompare::checked_compare(Self, Self) -> Result[Int, ArithmeticError]
```

The three checked traits together:

```moonbit check
///|
test "checked scalar operations" {
  let ctx = @lf_arith.ArithmeticContext::new(53)
  inspect(
    @la_arithmetic.CheckedDiv::checked_div(6.0, 2.0, ctx).unwrap(),
    content="3",
  )
  match @la_arithmetic.CheckedDiv::checked_div(1.0, 0.0, ctx) {
    Err(e) => inspect(e.is_division_by_zero(), content="true")
    Ok(_) => fail("1 / 0 must fail")
  }
  match @la_arithmetic.CheckedSqrt::checked_sqrt(-4.0, ctx) {
    Err(e) => inspect(e.is_domain_error(), content="true")
    Ok(_) => fail("sqrt(-4) must fail")
  }
  inspect(
    @la_arithmetic.CheckedCompare::checked_compare(2.0, 3.0).unwrap(),
    content="-1",
  )
  let nan = 0.0 / 0.0
  inspect(
    @la_arithmetic.CheckedCompare::checked_compare(nan, 1.0) is Err(_),
    content="true",
  )
}
```

## Where the traits are used

The concrete matrix packages take their scalar bounds from `luna-generic`
(`Zero`, `AddMonoid`, `Semiring`, `Field`, `Num`) and from `Sqrt`. The
`@mutable` numerical routines use `Sqrt` through this re-export and their own
`Tolerance` trait (see the [`mutable` API](mutable.md#tolerance)). The local
traits `Abs`, `ApproxEq` and the checked traits are building blocks for
downstream algorithms; no matrix method of this repository requires them.
