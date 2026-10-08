# internal API

`Luna-Flow/linear-algebra/internal` holds the shape-checking helpers shared by
[`immut`](immut.md) and [`mutable`](mutable.md). It defines the `HasShape`
trait and, for each precondition, a checked guard returning
`Result[Unit, LinearAlgebraError]` and an aborting guard.

> [!NOTE]
> MoonBit's internal-package rule applies: only packages inside
> `Luna-Flow/linear-algebra` can import this package. It is documented here
> because its trait appears in the public interfaces of `immut` and `mutable`
> (`pub impl HasShape for Matrix[T]`), and because the promoted
> `Matrix::shape` methods come from it.

Source: [`src/internal/algebra.mbt`](../../../src/internal/algebra.mbt).

## `HasShape`

`HasShape` reports the `(rows, cols)` of a matrix-like value.

```mbti
pub(open) trait HasShape {
  fn shape(Self) -> (Int, Int)
}
```

Implemented by `@immut.Matrix`, `@immut.MatrixFn` and `@mutable.Matrix`. It
mirrors `@algebra.MatrixShape` but lives below `algebra`, so the concrete
packages need not depend on the experimental `algebra` layer.

### `HasShape::shape`

`HasShape::shape(m)` returns `(rows, cols)`.

```mbti
fn HasShape::shape(Self) -> (Int, Int)
```

## Guards

Each precondition has two forms. The `_checked` form returns `Ok(())` when the
precondition holds and an `Err` of the listed kind otherwise. The plain form
returns `()` or aborts with the error's message. For every input,
`ensure_x(m)` aborts exactly when `ensure_x_checked(m)` is `Err`.

| Guard | Precondition | Error kind |
| --- | --- | --- |
| `ensure_square` | rows = cols | `NonSquareMatrix` |
| `ensure_row_in_bounds` | $0 \le r <$ rows | `IndexOutOfBounds` |
| `ensure_col_in_bounds` | $0 \le c <$ cols | `IndexOutOfBounds` |
| `ensure_index_in_bounds` | row and column in bounds (row checked first) | `IndexOutOfBounds` |
| `ensure_same_shape` | `shape(a) == shape(b)` | `DimensionMismatch` |
| `ensure_mul_compatible` | cols(a) = rows(b) | `DimensionMismatch` |

### `ensure_square`, `ensure_square_checked`

```mbti
pub fn[M : HasShape] ensure_square(M) -> Unit
pub fn[M : HasShape] ensure_square_checked(M) -> Result[Unit, @error.LinearAlgebraError]
```

### `ensure_row_in_bounds`, `ensure_row_in_bounds_checked`

```mbti
pub fn[M : HasShape] ensure_row_in_bounds(M, Int) -> Unit
pub fn[M : HasShape] ensure_row_in_bounds_checked(M, Int) -> Result[Unit, @error.LinearAlgebraError]
```

### `ensure_col_in_bounds`, `ensure_col_in_bounds_checked`

```mbti
pub fn[M : HasShape] ensure_col_in_bounds(M, Int) -> Unit
pub fn[M : HasShape] ensure_col_in_bounds_checked(M, Int) -> Result[Unit, @error.LinearAlgebraError]
```

### `ensure_index_in_bounds`, `ensure_index_in_bounds_checked`

```mbti
pub fn[M : HasShape] ensure_index_in_bounds(M, Int, Int) -> Unit
pub fn[M : HasShape] ensure_index_in_bounds_checked(M, Int, Int) -> Result[Unit, @error.LinearAlgebraError]
```

### `ensure_same_shape`, `ensure_same_shape_checked`

```mbti
pub fn[A : HasShape, B : HasShape] ensure_same_shape(A, B) -> Unit
pub fn[A : HasShape, B : HasShape] ensure_same_shape_checked(A, B) -> Result[Unit, @error.LinearAlgebraError]
```

### `ensure_mul_compatible`, `ensure_mul_compatible_checked`

```mbti
pub fn[A : HasShape, B : HasShape] ensure_mul_compatible(A, B) -> Unit
pub fn[A : HasShape, B : HasShape] ensure_mul_compatible_checked(A, B) -> Result[Unit, @error.LinearAlgebraError]
```

The two operands may have different types, for example a `Matrix` and a
`MatrixFn`.

## Example

The guards are not importable from outside the repository; their effect is
visible through the public methods built on them:

```moonbit check
///|
test "guards behind public methods" {
  let a = @immut.Matrix::from_2d_array([[1, 2, 3]])
  match a.matmul(a) {
    Err(e) =>
      inspect(
        e.message,
        content="Matrix dimensions are not compatible for multiplication",
      )
    Ok(_) => fail("1x3 times 1x3 is not defined")
  }
  match a.trace() {
    Err(e) => inspect(e.message, content="Matrix must be square")
    Ok(_) => fail("a 1x3 matrix has no trace")
  }
  debug_inspect(a.shape(), content="(1, 3)")
}
```
