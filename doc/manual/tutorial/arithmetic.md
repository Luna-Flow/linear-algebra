# arithmetic tutorial

This tutorial shows how to use the scalar operation traits of `arithmetic` in
your own generic helpers: absolute values, approximate comparison, and checked
division, square root and comparison that turn invalid inputs into values you
can handle. The background is in the [arithmetic design](../design/arithmetic.md).

| I want to | Use |
| --- | --- |
| take an absolute value generically | `@la_arithmetic.Abs::abs` |
| compare floating-point results | `@la_arithmetic.ApproxEq::approx_eq` |
| divide without producing infinities | `@la_arithmetic.CheckedDiv::checked_div` |
| take a square root only on its domain | `@la_arithmetic.CheckedSqrt::checked_sqrt` |
| order values that may be NaN | `@la_arithmetic.CheckedCompare::checked_compare` |
| use `Sqrt`, `Zero`, `One` from one import | the re-exports of `@la_arithmetic` |

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
moon add Luna-Flow/arithmetic@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

A generic "largest magnitude" helper needs `Abs` and `Compare`:

```moonbit check
///|
fn[T : @la_arithmetic.Abs + Compare] arith_tut_max_abs(xs : Array[T]) -> T? {
  let mut best : T? = None
  for x in xs {
    let a = @la_arithmetic.Abs::abs(x)
    best = match best {
      Some(b) if b >= a => Some(b)
      _ => Some(a)
    }
  }
  best
}

///|
test "largest magnitude" {
  debug_inspect(arith_tut_max_abs([3, -7, 5]), content="Some(7)")
  debug_inspect(arith_tut_max_abs([0.5, -0.25]), content="Some(0.5)")
}
```

## Everyday tasks

### Normalize a vector without dividing by zero

`CheckedDiv` reports a zero divisor as an error instead of producing infinities:

```moonbit check
///|
fn arith_tut_normalize(
  xs : Array[Double],
  ctx : @lf_arith.ArithmeticContext,
) -> Result[Array[Double], @lf_arith.ArithmeticError] {
  let mut sum = 0.0
  for x in xs {
    sum = sum + x.abs()
  }
  let out = []
  for x in xs {
    match @la_arithmetic.CheckedDiv::checked_div(x, sum, ctx) {
      Ok(v) => out.push(v)
      Err(e) => return Err(e)
    }
  }
  Ok(out)
}

///|
test "normalize by the 1-norm" {
  let ctx = @lf_arith.ArithmeticContext::new(53)
  debug_inspect(
    arith_tut_normalize([1.0, 3.0], ctx).unwrap(),
    content="[0.25, 0.75]",
  )
  inspect(arith_tut_normalize([0.0, 0.0], ctx) is Err(_), content="true")
}
```

For the all-zero input the first division is $0/0$, which is reported with
kind `DomainError`.

### Take a square root only on its domain

```moonbit check
///|
fn arith_tut_std_from_variance(
  variance : Double,
) -> Result[Double, @lf_arith.ArithmeticError] {
  @la_arithmetic.CheckedSqrt::checked_sqrt(
    variance,
    @lf_arith.ArithmeticContext::new(53),
  )
}

///|
test "square root of a variance" {
  inspect(arith_tut_std_from_variance(2.25).unwrap(), content="1.5")
  match arith_tut_std_from_variance(-1.0e-18) {
    Err(e) => inspect(e.is_domain_error(), content="true")
    Ok(_) => fail("negative variance must be rejected")
  }
}
```

A slightly negative variance is a typical rounding artifact of a one-pass
formula; the checked call makes you decide what to do with it.

### Sort data that may contain NaN

`checked_compare` fails on NaN, so you can detect unordered data before
sorting:

```moonbit check
///|
fn arith_tut_all_ordered(xs : Array[Double]) -> Bool {
  for x in xs {
    if @la_arithmetic.CheckedCompare::checked_compare(x, x) is Err(_) {
      return false
    }
  }
  true
}

///|
test "detect NaN before sorting" {
  inspect(arith_tut_all_ordered([2.0, 1.0]), content="true")
  inspect(arith_tut_all_ordered([2.0, 0.0 / 0.0]), content="false")
}
```

### Compare results approximately

`ApproxEq` is convenient for values of order one, such as entries of a
normalized vector:

```moonbit check
///|
fn[T : @la_arithmetic.ApproxEq] arith_tut_all_close(
  xs : Array[T],
  ys : Array[T],
) -> Bool {
  if xs.length() != ys.length() {
    return false
  }
  for i in 0..<xs.length() {
    if !@la_arithmetic.ApproxEq::approx_eq(xs[i], ys[i]) {
      return false
    }
  }
  true
}

///|
test "approximate comparison of computed values" {
  inspect(arith_tut_all_close([0.1 + 0.2, 1.0], [0.3, 1.0]), content="true")
  inspect(0.1 + 0.2 == 0.3, content="false")
}
```

## Going further

**Your own scalar type.** All traits are `pub(open)`. A decimal or rational
type can implement `Abs`, `ApproxEq` (for an exact type, simply `==`) and the
checked traits; it then works with every helper written against them.

**Errors in matrix code.** The matrix packages report scalar failures with
`LinearAlgebraError::arithmetic_failure`, which wraps an `ArithmeticError`.
A helper that mixes matrix and scalar steps can convert with that constructor;
see the [error tutorial](error.md).

**Upstream traits.** For transcendental functions and contextual arithmetic,
use `Luna-Flow/arithmetic` directly; this package re-exports only the names
listed on the [API page](../api/arithmetic.md).

## Common pitfalls

- **Absolute tolerance at the wrong scale.** `approx_eq` on values around
  $10^{20}$ is effectively exact equality, and on values around $10^{-20}$ it
  accepts everything. Scale your data or use your own relative rule.
- **Chaining approximate comparisons.** $a \approx b$ and $b \approx c$ do not
  imply $a \approx c$.
- **Expecting the context to change `Double` results.** The precision of
  `ArithmeticContext` is ignored for binary floating point.
- **`Abs` on `Int.MIN_VALUE`.** The result wraps and stays negative.

## Next steps

- [arithmetic API](../api/arithmetic.md) for the exact rules of each trait.
- [arithmetic design](../design/arithmetic.md) for why `approx_eq` is not an
  equivalence relation.
- [mutable tutorial](mutable.md) for the matrix routines that depend on
  `Sqrt` and `Tolerance`.
- [Luna-Flow/arithmetic](https://lunaflow.cn/en/arithmetic/) for the full scalar
  operation library.
