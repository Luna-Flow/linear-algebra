# arithmetic design

## Design goal

Linear-algebra algorithms need a handful of scalar operations beyond the ring
operators: an absolute value for pivoting, a square root for norms, a
comparison for ordering, and a way to compare floating-point results. The
`arithmetic` package names these operations for linear-algebra code without
claiming that the scalar types satisfy laws they do not satisfy. It reuses the
upstream vocabulary wherever it exists and adds a trait only where none does.

## Constraints

- Trait instances can only be written in the package that owns the trait or
  the type, so names that already exist upstream must be re-exported, not
  redefined.
- `Float` and `Double` satisfy algebraic laws only up to rounding, so no trait
  here may claim laws.
- The package sits below every other package of the repository and may depend
  only on `luna-generic` and `Luna-Flow/arithmetic`.

## Design decisions

### Reuse upstream names

The scalar traits `Zero`, `One`, `Inverse`, `Conjugate` and the analytic
traits of `Luna-Flow/arithmetic` are re-exported with `pub using` rather than
redefined. A local copy would create a second, incompatible `Sqrt`, and a
scalar type implementing the upstream trait would not satisfy the local one.
With `pub using`, `@la_arithmetic.Sqrt` *is* `@lf_arith.Sqrt`.

### Small local traits

`Abs`, `ApproxEq`, `CheckedDiv`, `CheckedSqrt` and `CheckedCompare` exist
because linear-algebra code wanted these names when the upstream package did
not provide them in this form. Each is one method, so a scalar type can opt in
to exactly the operations it supports. The checked traits delegate to the
upstream checked traits for `Float` and `Double`, so the two layers agree on
every input.

### Context accepted and ignored for binary floating point

`checked_div` and `checked_sqrt` take an `ArithmeticContext` so that one
signature serves fixed-precision and arbitrary-precision scalar types. For
`Float` and `Double` the precision is fixed by the hardware format and rounding
is round-to-nearest-even, so the context has no effect.

### Fixed absolute tolerances

`ApproxEq` uses $10^{-12}$ for `Double` and $10^{-6}$ for `Float`. These are
about $9000u$ and $17u$ for the unit roundoff $u$ of each format ($2^{-53}$
and $2^{-24}$), so they suit values of order one, such as entries of normalized vectors.
For other scales, compare with an explicit tolerance in your own code.

## Mathematical background

### Operations versus structures

A *structure* trait such as `Field` promises equations: associativity,
distributivity, inverses. An *operation* trait such as `Sqrt` promises only
that a function $\sqrt{\cdot} : T \to T$ exists. The distinction matters
because the builtin floating-point types implement the operations but satisfy
the equations only approximately: for `Double`,

$$
\mathrm{fl}\big(\mathrm{fl}(2^{53} + 1) - 2^{53}\big) = 0 \ne 1
= \mathrm{fl}\big(2^{53} - 2^{53}\big) + 1 ,
$$

so $(a + b) - c \ne (a - c) + b$ in general. Every trait of this package is an
operation trait.

### Partial operations and their totalizations

Division and square root are partial functions on the reals:
$x / y$ is defined on $\{(x, y) : y \ne 0\}$ and $\sqrt{x}$ on $\{x \ge 0\}$.
IEEE 754 makes them total by returning special values ($\pm\infty$, NaN),
which then propagate silently. A checked operation instead totalizes a partial
function $f : D \rightharpoonup C$ into

$$
\hat f : X \to C + E, \qquad
\hat f(x) =
\begin{cases}
\mathrm{Ok}\,(f(x)) & x \in D, \\
\mathrm{Err}\,(e(x)) & x \notin D,
\end{cases}
$$

where $E$ is a set of error values and $e(x)$ says *why* $x$ is outside the
domain. `CheckedDiv` uses the following domain decomposition for floating-point
operands:

| Region | IEEE result | Checked result |
| --- | --- | --- |
| $y \ne 0$, not both infinite | $\mathrm{fl}(x / y)$ | `Ok` of the same value |
| $x = y = 0$ | NaN | `DomainError` |
| $x, y$ both infinite | NaN | `DomainError` |
| $x \ne 0$ (finite, infinite or NaN), $y = \pm 0$ | $\pm\infty$ or NaN | `DivisionByZero` |
| $y \ne 0$, $x$ or $y$ NaN | NaN | `Ok(NaN)` |

A NaN operand with a non-zero divisor passes through as `Ok(NaN)`: it is
already outside the reals, and the check reports only the operands for which
the division itself is undefined. A zero divisor is reported even when the
dividend is NaN.

### Ordering with NaN

`Compare` on `Double` is not a total order: NaN is neither less than, equal to,
nor greater than any value, so sorting or pivot selection on data containing
NaN gives order-dependent results. `CheckedCompare` restricts the comparison to
the ordered subset and reports `UnorderedComparison` outside it, which makes
the result a total order on its domain.

### Approximate equality

`ApproxEq` uses the absolute rule $a \approx b \iff |a - b| \le \varepsilon$.
On finite values this relation is reflexive and symmetric but not transitive. From
$|a - b| \le \varepsilon$ and $|b - c| \le \varepsilon$ the triangle inequality
gives only

$$
|a - c| \le |a - b| + |b - c| \le 2\varepsilon ,
$$

and the bound is attained: with $a = 0$, $b = \varepsilon$, $c = 2\varepsilon$
we have $a \approx b$, $b \approx c$ and $a \not\approx c$. So `approx_eq` is
not an equivalence relation, and the package does not present it as one.

An absolute tolerance is also not scale-invariant. Floating-point spacing
grows with magnitude: adjacent `Double` values near $x$ are about
$2^{-52}|x|$ apart. Near $10^{20}$ that spacing is about $1.6 \times 10^{4}$,
so two different values can never be within $10^{-12}$; near $10^{-20}$ every
pair of values is. A relative rule
$|a - b| \le \varepsilon \max(|a|, |b|)$ fixes the scale problem but fails near
zero, which is why careful code combines both; this package leaves that choice
to the caller.

## Correctness and invariants

- For `Float` and `Double`, `checked_div(x, y, ctx)` returns `Err` exactly
  when $y = \pm 0$ or when $x$ and $y$ are both infinite; otherwise it returns
  `Ok(v)` where `v` is the IEEE quotient bit for bit (NaN for a NaN operand). Note that IEEE 754 itself signals no exception for
  $\infty / 0$, which `checked_div` nevertheless reports as `DivisionByZero`.
- `checked_sqrt(x, ctx)` returns `Ok(√x)` for $x \ge 0$ and for NaN, and
  `Err` with kind `DomainError` for $x < 0$, including $-\infty$. Note that
  $-0.0 \ge 0$ holds, so `checked_sqrt(-0.0)` is `Ok(-0.0)`, as IEEE 754
  requires.
- `checked_compare` is antisymmetric on its domain:
  `checked_compare(a, b) == Ok(k)` implies `checked_compare(b, a) == Ok(-k)`.
- `approx_eq` is symmetric, and reflexive on finite values. It is false
  whenever an operand is NaN, and also for $\infty$ against itself, because
  $\infty - \infty$ is NaN.

## Alternatives rejected

- **A local `Real` or `Number` trait** combining all operations. It would hide
  which operations an algorithm uses and force exotic scalars to implement
  everything.
- **Making `approx_eq` part of `Eq`.** `Eq` must be an equivalence relation;
  approximate equality is not transitive.
- **Relative tolerances in `ApproxEq`.** They need a policy near zero that
  depends on the application; the trait stays simple and documented instead.

## Boundaries

`arithmetic` defines no vector, matrix or backend types and does not depend on
the other packages of this repository. It does not define algebraic structure
traits (those come from `luna-generic`), does not choose tolerances for matrix
algorithms (that is the `Tolerance` trait of [`mutable`](mutable.md)), and does
not implement arbitrary-precision arithmetic.
