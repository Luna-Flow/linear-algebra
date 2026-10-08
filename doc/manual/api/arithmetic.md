# arithmetic API

## Purpose

`Luna-Flow/linear-algebra/arithmetic` is the scalar-operation layer of the
repository. It re-exports the scalar types and traits that linear-algebra code
uses from `Luna-Flow/luna-generic` and `Luna-Flow/arithmetic`, and adds five
small operation traits: `Abs`, `ApproxEq`, `CheckedDiv`, `CheckedSqrt` and
`CheckedCompare`. An operation trait says that an operation is available; it
does not claim algebraic laws.

Source: [`src/arithmetic/operation_traits.mbt`](../../../src/arithmetic/operation_traits.mbt),
[`src/arithmetic/alias.mbt`](../../../src/arithmetic/alias.mbt). The reasoning
is in the [arithmetic design](../design/arithmetic.md).

## Importing

Import the package, and the upstream `Luna-Flow/arithmetic` for the context
and error types, in `moon.pkg`:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

The examples on this page write every name with its package prefix, such as
`@la_arithmetic.`, instead of a `using` declaration: all pages of this manual
compile into one test package, where the declarations of different pages
would clash.

## Re-exported names

The package re-exports upstream names with `pub using`, so
`@la_arithmetic.Sqrt` and `@lf_arith.Sqrt` denote the same trait, and a scalar
type that implements the upstream trait satisfies the re-exported one. Their
full behaviour is documented upstream:
[luna-generic](https://lunaflow.cn/en/luna-generic/) and
[arithmetic](https://lunaflow.cn/en/arithmetic/).

### `Zero`, `One`, `Inverse`, `Conjugate`

These re-export the scalar operation traits of `luna-generic`: the additive
and multiplicative identities, the multiplicative inverse and conjugation.

```mbti
pub using @luna-generic {trait Zero}
pub using @luna-generic {trait One}
pub using @luna-generic {trait Inverse}
pub using @luna-generic {trait Conjugate}
```

| Name | Method | Meaning |
| --- | --- | --- |
| `Zero` | `zero()` | additive identity $0$ |
| `One` | `one()` | multiplicative identity $1$ |
| `Inverse` | `inv(x)` | $x^{-1}$; the `Float` and `Double` instances abort on $0$ |
| `Conjugate` | `conjugate(x)` | $\overline{x}$; the builtin real types have no instance |

They state no laws by themselves; the structure traits of `luna-generic`
(`Ring`, `Field`, ...) give them their meaning.

### `Sqrt`, `Cbrt`, `Power`, `Exponential`, `Logarithmic`, `Constants`

These re-export the unchecked analytic operations of `Luna-Flow/arithmetic`.

```mbti
pub using @Luna-Flow/arithmetic {trait Sqrt}
pub using @Luna-Flow/arithmetic {trait Cbrt}
pub using @Luna-Flow/arithmetic {trait Power}
pub using @Luna-Flow/arithmetic {trait Exponential}
pub using @Luna-Flow/arithmetic {trait Logarithmic}
pub using @Luna-Flow/arithmetic {trait Constants}
```

| Name | Methods | Meaning |
| --- | --- | --- |
| `Sqrt` | `sqrt(x)` | $\sqrt{x}$; IEEE NaN for $x < 0$ |
| `Cbrt` | `cbrt(x)` | $\sqrt[3]{x}$ |
| `Power` | `pow(x, y)` | $x^y$ |
| `Exponential` | `exp(x)`, `exp2(x)` | $e^x$, $2^x$ |
| `Logarithmic` | `ln(x)`, `log2(x)`, `log10(x)` | logarithms |
| `Constants` | `pi()`, `tau()`, `e()` | $\pi$, $2\pi$, $e$ |

`Sqrt` is the one this repository uses: `mutable` needs it for
`cholesky_decomposition`, `eigen`, `frobenius_norm` and `std_dev`.

### `SqrtChecked`, `DivChecked`, `CompareChecked`

These re-export the checked operations of `Luna-Flow/arithmetic`, which return
`Result` instead of an IEEE special value.

```mbti
pub using @Luna-Flow/arithmetic {trait SqrtChecked}
pub using @Luna-Flow/arithmetic {trait DivChecked}
pub using @Luna-Flow/arithmetic {trait CompareChecked}
```

| Name | Method |
| --- | --- |
| `SqrtChecked` | `sqrt_checked(x, ctx) -> Result[Self, ArithmeticError]` |
| `DivChecked` | `div_checked(x, y, ctx) -> Result[Self, ArithmeticError]` |
| `CompareChecked` | `compare_checked(x, y) -> Result[Int, ArithmeticError]` |

The local traits `CheckedSqrt`, `CheckedDiv` and `CheckedCompare` below
delegate to them for `Float` and `Double`.

### `ArithmeticContext`, `ArithmeticError`, `ArithmeticErrorKind`, `FpClass`, `RoundingMode`

These re-export the types that the checked operations take and return.

```mbti
pub using @Luna-Flow/arithmetic {type ArithmeticContext}
pub using @Luna-Flow/arithmetic {type ArithmeticError}
pub using @Luna-Flow/arithmetic {type ArithmeticErrorKind}
pub using @Luna-Flow/arithmetic {type FpClass}
pub using @Luna-Flow/arithmetic {type RoundingMode}
```

| Name | Meaning |
| --- | --- |
| `ArithmeticContext` | precision and rounding settings; build it with `ArithmeticContext::new(precision)` |
| `ArithmeticError` | structured scalar error with fields `kind` and `message` |
| `ArithmeticErrorKind` | `DivisionByZero`, `DomainError`, `UnorderedComparison`, `ParseError`, `FormatError`, `UnsupportedOperation` |
| `FpClass` | `Finite`, `Infinity`, `NaN` |
| `RoundingMode` | `ToNearestEven`, `TowardZero`, `TowardPositive`, `TowardNegative`, `AwayFromZero` |

```moonbit check
///|
fn[T : @la_arithmetic.Zero + @la_arithmetic.Sqrt + Add + Mul] arith_api_hypot(
  x : T,
  y : T,
) -> T {
  @la_arithmetic.Sqrt::sqrt(@la_arithmetic.Zero::zero() + x * x + y * y)
}

///|
test "re-exported traits are the upstream ones" {
  inspect(arith_api_hypot(3.0, 4.0), content="5")
  let ctx = @lf_arith.ArithmeticContext::new(53)
  inspect(
    @la_arithmetic.SqrtChecked::sqrt_checked(-1.0, ctx) is Err(_),
    content="true",
  )
}
```

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
whenever an operand is NaN, and for an infinity compared with itself
($\infty - \infty$ is NaN). See the [design page](../design/arithmetic.md) for
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
| $x / 0$, $x \ne 0$ (also for $x = \infty$ or NaN) | `Err`, kind `DivisionByZero` |
| otherwise | `Ok(x / y)`, rounded to nearest; NaN operands give `Ok(NaN)` |

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
