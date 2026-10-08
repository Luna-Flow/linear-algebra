# error tutorial

This tutorial shows how to handle the failures of checked linear-algebra calls:
recognize what went wrong, recover where that makes sense, chain several
checked steps, and report failures from your own helpers in the same
vocabulary. The reasoning behind the error type is in the
[error design](../design/error.md).

| I want to | Use |
| --- | --- |
| know why a checked call failed | an `is_*` predicate or `e.kind` |
| recover from a singular matrix | `match` on `Err(e)` with `e.is_singular_matrix()` |
| chain several checked steps | `match` with early return, or `Result::bind` |
| report failures from my own helper | the `LinearAlgebraError` constructors |
| turn a scalar failure into a matrix error | `LinearAlgebraError::arithmetic_failure` |

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/error" @la_error,
  "Luna-Flow/linear-algebra/mutable",
}
```

A checked call returns `Result[_, LinearAlgebraError]`. Branch on the result
and use a predicate to classify the failure:

```moonbit check
///|
test "classify a failed inverse" {
  let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  let status = match m.inverse() {
    Ok(_) => "ok"
    Err(e) => if e.is_singular_matrix() { "singular" } else { e.message }
  }
  inspect(status, content="singular")
}
```

The output is `singular`.

## Everyday tasks

### Recover differently for different failures

```moonbit check
///|
fn err_tut_inverse_report(m : @mutable.Matrix[Double]) -> String {
  match m.inverse() {
    Ok(inv) => "inverse has \{inv.row()} rows"
    Err(e) =>
      if e.is_non_square_matrix() {
        "not square: use a least-squares method instead"
      } else if e.is_singular_matrix() {
        "singular: regularize the matrix"
      } else {
        e.message
      }
  }
}

///|
test "different recovery paths" {
  let rect = @mutable.Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  inspect(
    err_tut_inverse_report(rect),
    content="not square: use a least-squares method instead",
  )
  let ok = @mutable.Matrix::from_2d_array([[2.0, 0.0], [0.0, 4.0]])
  inspect(err_tut_inverse_report(ok), content="inverse has 2 rows")
}
```

### Chain checked steps

Compute $\operatorname{tr}(A^{k})$ only when both steps succeed. An early
`return Err(e)` passes the first failure through unchanged:

```moonbit check
///|
fn err_tut_trace_of_power(
  a : @immut.Matrix[Int],
  k : Int,
) -> Result[Int, @la_error.LinearAlgebraError] {
  let p = match a.pow(k) {
    Ok(p) => p
    Err(e) => return Err(e)
  }
  p.trace()
}

///|
test "trace of a matrix power" {
  let a = @immut.Matrix::from_2d_array([[1, 1], [1, 0]])
  inspect(err_tut_trace_of_power(a, 5).unwrap(), content="11")
  match err_tut_trace_of_power(a, -1) {
    Err(e) => inspect(e.is_negative_exponent(), content="true")
    Ok(_) => fail("negative powers are not defined")
  }
}
```

$A^5$ of the Fibonacci matrix is $\begin{pmatrix} 8 & 5 \\ 5 & 3 \end{pmatrix}$,
so the trace is $11$.

### Report failures from your own helper

Use the constructors to return errors of the shared kinds:

```moonbit check
///|
fn err_tut_column_sum(
  m : @mutable.Matrix[Int],
  col : Int,
) -> Result[Int, @la_error.LinearAlgebraError] {
  guard col >= 0 && col < m.col() else {
    return Err(
      @la_error.LinearAlgebraError::index_out_of_bounds(
        "column \{col} is outside 0..<\{m.col()}",
      ),
    )
  }
  let mut sum = 0
  m.each_col(col, x => sum = sum + x)
  Ok(sum)
}

///|
test "a custom checked helper" {
  let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  inspect(err_tut_column_sum(m, 1).unwrap(), content="6")
  match err_tut_column_sum(m, 5) {
    Err(e) => {
      inspect(e.is_index_out_of_bounds(), content="true")
      inspect(e.message, content="column 5 is outside 0..<2")
    }
    Ok(_) => fail("column 5 does not exist")
  }
}
```

### Wrap a scalar failure

When a helper mixes scalar checked operations and matrix operations, wrap the
`ArithmeticError` so the helper has a single error type:

```moonbit check
///|
fn err_tut_rms(
  m : @mutable.Matrix[Double],
) -> Result[Double, @la_error.LinearAlgebraError] {
  let n = (m.row() * m.col()).to_double()
  let mut sum = 0.0
  m.each(x => sum = sum + x * x)
  let ctx = @lf_arith.ArithmeticContext::new(53)
  match @la_arithmetic.CheckedDiv::checked_div(sum, n, ctx) {
    Ok(mean_sq) => Ok(mean_sq.sqrt())
    Err(e) => Err(@la_error.LinearAlgebraError::arithmetic_failure(e))
  }
}

///|
test "wrapping a scalar error" {
  let m = @mutable.Matrix::from_2d_array([[3.0, 4.0]])
  inspect(err_tut_rms(m).unwrap(), content="3.5355339059327378")
  let empty : @mutable.Matrix[Double] = @mutable.Matrix::new(0, 0, 0.0)
  match err_tut_rms(empty) {
    Err(e) => inspect(e.is_arithmetic_failure(), content="true")
    Ok(_) => fail("0 / 0 must fail")
  }
}
```

## Going further

**Unchecked forms.** Every checked method has an `unchecked_*` partner that
aborts instead of returning `Err` (`unchecked_inverse` returns `Option`). Use
it only after your code has established the precondition, for example in an
inner loop over matrices you constructed as square. The law is
`checked(x) == Ok(unchecked(x))` whenever `x` is in the domain.

**Methods that still abort.** Not every partial operation has a checked form
in this release. Constructors such as `from_2d_array` abort on ragged input,
the operators `+`, `-` and `*` abort on shape mismatch, and `eigen` aborts on
non-symmetric input. The API pages of [`immut`](../api/immut.md) and
[`mutable`](../api/mutable.md) mark each one; validate inputs first when they
come from outside your program.

**Errors from the container layer.** The `container` dictionaries and
algorithms return the same error type, so a pipeline that converts storage and
then computes needs no conversion between error types.

## Common pitfalls

- **Matching on `message`.** Messages are diagnostics and may change between
  releases; branch on predicates or `kind`.
- **Printing the error directly.** `LinearAlgebraError` has no `Show` or
  `Debug` implementation; print `e.message`.
- **Comparing whole errors.** `==` compares the message too. Compare
  `a.kind == b.kind` when only the category matters.
- **Assuming a reserved kind can occur.** `NonConvergence`, `RaggedRows` and
  `InvalidLength` are not produced by this release.

## Next steps

- [error API](../api/error.md) for every constructor and predicate.
- [error design](../design/error.md) for the checked/unchecked law.
- [mutable tutorial](mutable.md) and [immut tutorial](immut.md) for the
  checked matrix operations themselves.
