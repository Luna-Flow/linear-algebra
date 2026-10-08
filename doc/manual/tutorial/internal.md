# internal tutorial

This page is for contributors who add a matrix operation to `immut` or
`mutable` and need to validate its inputs. Downstream code cannot import
`internal`; it sees the guards only through the public methods. The rules are
in the [internal design](../design/internal.md).

## Quick start

Inside the repository, import the package in `moon.pkg` and bring the guards
into scope:

```moonbit nocheck
///|
// moon.pkg
import {
  "Luna-Flow/linear-algebra/internal",
}
```

```moonbit nocheck
///|
using @internal {trait HasShape, ensure_square, ensure_square_checked}
```

## Everyday tasks

### Add a checked/unchecked pair

Validate with the checked guard, then call the unchecked form, so the
checked/unchecked law holds by construction:

```moonbit nocheck
///|
pub fn[T : Add + Zero] Matrix::anti_trace(
  self : Matrix[T],
) -> Result[T, LinearAlgebraError] {
  match ensure_square_checked(self) {
    Ok(_) => Ok(self.unchecked_anti_trace())
    Err(err) => Err(err)
  }
}

///|
pub fn[T : Add + Zero] Matrix::unchecked_anti_trace(self : Matrix[T]) -> T {
  ensure_square(self)
  let n = self.row
  let mut sum = Zero::zero()
  for i in 0..<n {
    sum = sum + self[i][n - 1 - i]
  }
  sum
}
```

### Check indices on access

Use `ensure_row_in_bounds` when a row is selected and
`ensure_index_in_bounds` before computing a storage offset; never test only the
flat offset.

### Observe the result from outside

The public behaviour is what tests should pin down:

```moonbit check
///|
test "the same guard in both packages" {
  let i = @immut.Matrix::from_2d_array([[1, 2, 3]])
  let m = @mutable.Matrix::from_2d_array([[1, 2, 3]])
  let ei = match i.trace() {
    Err(e) => e.message
    Ok(_) => ""
  }
  let em = match m.trace() {
    Err(e) => e.message
    Ok(_) => ""
  }
  inspect(ei == em, content="true")
}
```

## Going further

New matrix-like types inside the repository implement `HasShape` once and get
every guard. Keep error kinds and messages unchanged when refactoring: the
[`consistency`](consistency.md) tests and downstream users rely on them.

## Common pitfalls

- **Calling the aborting guard in a checked method.** The checked method would
  abort instead of returning `Err`.
- **Checking after mutating.** In `mutable`, validate before the first write so
  that an error leaves the matrix unchanged.

## Next steps

- [internal API](../api/internal.md).
- [error design](../design/error.md) for the checked/unchecked law.
- [Contributing guide](../../../CONTRIBUTING.md).
