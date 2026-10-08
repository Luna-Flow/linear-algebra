# mutable API

## Purpose

`Luna-Flow/linear-algebra/mutable` provides execution-oriented dense linear
algebra: `Matrix[T]` stores its entries in one row-major `Array[T]` and can be
updated in place, `Vector[T]` wraps an `Array[T]`, and `RowView`, `ColView`
and `Transpose` are live views into a matrix. On top of the storage the
package implements the numerical routines of the repository: LU-based
determinant, inverse and rank, Cholesky factorization, symmetric eigenvalues,
the power method, row reduction and simple statistics.

Source: [`src/mutable`](../../../src/mutable/matrix.mbt). The algorithms and
their numerical properties are derived in the [mutable design](../design/mutable.md);
[`immut`](immut.md) is the value-oriented counterpart with the same core names.

## Importing

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/mutable",
}
```

The examples on this page write every name with its package prefix, such as
`@mutable.`, instead of a `using` declaration: all pages of this manual
compile into one test package, where the declarations of different pages
would clash.

## Conventions

- **Shapes and storage.** A matrix has `row()` rows and `col()` columns, both
  non-negative; $0 \times n$ and $n \times 0$ are valid and distinct. Entry
  $(i, j)$ is stored at offset $i \cdot \mathrm{col} + j$.
- **Mutation.** Methods returning `Unit` (`set`, `swap_rows`, `*_inplace`,
  view writes) change the matrix in place, and every view or alias of it sees
  the change. All other methods return new values and leave their arguments
  unchanged, except `reduce_row_elimination`, which works in place and returns
  its receiver.
- **Aliasing constructors.** `Matrix::from_array` and `Vector::from_array`
  adopt the given array without copying. `from_2d_array`, `copy` and every
  conversion to arrays copy.
- **Bounds.** All public accessors check row and column separately and abort
  on an out-of-range index; this includes iterators, views and the transpose
  view.
- **Checked and unchecked.** Operations with a runtime failure mode return
  `Result[_, LinearAlgebraError]` and have an `unchecked_*` partner that aborts
  (or returns `Option`, for `unchecked_inverse`). See the
  [error design](../design/error.md).
- **Numerical routines** require `T : Compare + Field + Num + Tolerance` (plus
  `Sqrt` where a square root is taken). `Tolerance` is implemented only for
  `Double` and `Float`, so these routines are for floating-point matrices.
- **Targets.** The kernels are tuned separately for `native`, `js`, `wasm` and
  `wasm-gc`. The public semantics are the same on every target; floating-point
  results may differ in the last bits where a kernel sums in a different order.

## Types

### `Matrix`

`Matrix[T]` is a mutable dense matrix.

```mbti
type Matrix[T] derive(Eq)
```

The type is abstract. It implements `Eq` (shape and entries), `Show`, `Add`,
`Sub`, `Neg` and `Mul` (matrix product), under the element constraints of the
corresponding methods.

### `Lens`

`Lens[T]` is the row accessor returned by `m[r]`; it backs `m[r][c]` and
`m[r][c] = x`.

```mbti
type Lens[T]
```

### `Lens::at`, `Lens::set`

`Lens::at(l, c)` reads and `Lens::set(l, c, x)` writes column `c` of the row
the lens points to.

```mbti
#alias("_[_]")
pub fn[T] Lens::at(Self[T], Int) -> T
#alias("_[_]=_")
pub fn[T] Lens::set(Self[T], Int, T) -> Unit
```

A lens obtained from a `Transpose` addresses the transposed matrix. An
out-of-range column aborts.

### `RowView`, `ColView`

`RowView[T]` and `ColView[T]` are live views of one row or one column.

```mbti
pub struct RowView[T] {
  data : Matrix[T]
  row : Int
}
pub struct ColView[T] {
  data : Matrix[T]
  col : Int
}
```

The fields are readable. Writes through a view change the underlying matrix.

### `Transpose`

`Transpose[T]` is a live transposed view of a matrix.

```mbti
pub struct Transpose[T](Matrix[T])
```

It shares storage with the wrapped matrix. Its methods address the transposed
matrix: entry $(i, j)$ of the view is entry $(j, i)$ of the matrix.

### `Vector`

`Vector[A]` is a mutable dense vector, a wrapper around `Array[A]`.

```mbti
pub struct Vector[A](Array[A])
```

The array is readable as `v.0`. It implements `Eq`, `Show` (`|a, b, c|`),
`Add`, `Mul` (element-wise), `Neg`, `Debug` and quickcheck's `Arbitrary`.

### `Tolerance`

`Tolerance` provides the absolute threshold used by the numerical routines.

```mbti
pub trait Tolerance {
  fn tolerance() -> Self
}
pub impl Tolerance for Float
pub impl Tolerance for Double
```

Both instances return $10^{-11}$. The trait is not open: other packages cannot
add instances. How and where the threshold is applied is explained in the
[mutable design](../design/mutable.md#tolerance-based-decisions).

### `Sqrt`

`Sqrt` is a re-export of `Luna-Flow/arithmetic.Sqrt`, needed by
`cholesky_decomposition`, `eigen`, `is_positive_definite`, `frobenius_norm`
and `std_dev`.

```mbti
pub using @arithmetic {trait Sqrt}
```

## Construction

### `Matrix::make`

`Matrix::make(r, c, f)` builds the $r \times c$ matrix with entries $f(i, j)$.

```mbti
pub fn[A] Matrix::make(Int, Int, (Int, Int) -> A) -> Self[A]
```

Negative dimensions abort. `f` should be pure; the number of times it is
called for an entry is not specified.

### `Matrix::new`

`Matrix::new(r, c, x)` builds an $r \times c$ matrix filled with `x`.

```mbti
pub fn[T] Matrix::new(Int, Int, T) -> Self[T]
```

### `Matrix::from_2d_array`

`Matrix::from_2d_array(rows)` copies nested rows into a new matrix.

```mbti
pub fn[T] Matrix::from_2d_array(Array[Array[T]]) -> Self[T]
```

`[]` gives $0 \times 0$; ragged rows abort.

### `Matrix::from_array`

`Matrix::from_array(r, c, data)` adopts `data` as the row-major storage of an
$r \times c$ matrix.

```mbti
pub fn[T] Matrix::from_array(Int, Int, Array[T]) -> Self[T]
```

Negative dimensions or `data.length() != r * c` abort. The array is **not**
copied: later writes to `data` change the matrix and vice versa.

### `identity`

`identity(n)` builds the $n \times n$ identity matrix. It is a top-level
function, `@mutable.identity(n)`.

```mbti
pub fn[T : @luna-generic.Zero + @luna-generic.One] identity(Int) -> Matrix[T]
```

### `Matrix::copy`

`Matrix::copy(m)` returns a deep copy with its own storage.

```mbti
pub fn[T] Matrix::copy(Self[T]) -> Self[T]
```

```moonbit check
///|
test "mutable construction and aliasing" {
  let data = [1, 2, 3, 4]
  let shared = @mutable.Matrix::from_array(2, 2, data)
  data[0] = 100
  inspect(shared.get(0, 0), content="100")
  let separate = shared.copy()
  shared.set(0, 0, 1)
  inspect(separate.get(0, 0), content="100")
  let id : @mutable.Matrix[Double] = @mutable.identity(2)
  inspect(id, content="|1, 0|\n|0, 1|")
  inspect(
    @mutable.Matrix::make(2, 3, (i, j) => i * 3 + j),
    content="|0, 1, 2|\n|3, 4, 5|",
  )
}
```

## Shape and element access

### `Matrix::row`, `Matrix::col`, `Matrix::shape`

Row count, column count, and `(row, col)`.

```mbti
pub fn[T] Matrix::row(Self[T]) -> Int
pub fn[T] Matrix::col(Self[T]) -> Int
pub fn[T] Matrix::shape(Self[T]) -> (Int, Int)
```

### `Matrix::is_square`

`Matrix::is_square(m)` returns `row() == col()`.

```mbti
pub fn[T] Matrix::is_square(Self[T]) -> Bool
```

### `Matrix::get`, `Matrix::set`

`get(r, c)` reads entry $(r, c)$; `set(r, c, x)` writes it in place.

```mbti
pub fn[T] Matrix::get(Self[T], Int, Int) -> T
pub fn[T] Matrix::set(Self[T], Int, Int, T) -> Unit
```

Both are $O(1)$ and abort on out-of-range indices. They are the fastest way to
access single entries.

### `Matrix::at`

`Matrix::at(m, r)` returns a `Lens` for row `r`; it backs `m[r][c]` and
`m[r][c] = x`.

```mbti
#alias("_[_]")
pub fn[T] Matrix::at(Self[T], Int) -> Lens[T]
```

### `Matrix::row_view`, `Matrix::col_view`

`row_view(r)` and `col_view(c)` return live views of one row or column.

```mbti
pub fn[T] Matrix::row_view(Self[T], Int) -> RowView[T]
pub fn[T] Matrix::col_view(Self[T], Int) -> ColView[T]
```

The index is checked when the view is created.

### `Matrix::to_transpose`

`Matrix::to_transpose(m)` returns a live transposed view sharing storage with
`m`, in $O(1)$.

```mbti
pub fn[T] Matrix::to_transpose(Self[T]) -> Transpose[T]
```

### `Matrix::equal`, `Matrix::to_string`

`equal` compares shape and entries (backs `==`); `to_string` renders rows as
`|a, b|` lines.

```mbti
pub fn[T : Eq] Matrix::equal(Self[T], Self[T]) -> Bool
pub fn[T : Show] Matrix::to_string(Self[T]) -> String
```

```moonbit check
///|
test "mutable access" {
  let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  m[0][2] = 30
  m.set(1, 0, 40)
  inspect(m.get(0, 2), content="30")
  inspect(m[1][0], content="40")
  let r = m.row_view(1)
  r[2] = 60
  inspect(m, content="|1, 2, 30|\n|40, 5, 60|")
  debug_inspect(m.shape(), content="(2, 3)")
}
```

## Traversal and in-place transforms

### `Matrix::each`, `Matrix::eachi`

`each(f)` calls `f` on every entry in row-major order; `eachi(f)` also passes
the flat row-major index.

```mbti
pub fn[T] Matrix::each(Self[T], (T) -> Unit) -> Unit
pub fn[T] Matrix::eachi(Self[T], (Int, T) -> Unit) -> Unit
```

### `Matrix::each_row_col`

`each_row_col(f)` calls `f(i, j, a_ij)` for every entry in row-major order.

```mbti
pub fn[T] Matrix::each_row_col(Self[T], (Int, Int, T) -> Unit) -> Unit
```

### `Matrix::each_row`, `Matrix::eachi_row`, `Matrix::each_col`, `Matrix::eachi_col`

Visit one row (left to right) or one column (top to bottom); the `eachi_*`
forms pass the position within the row or column.

```mbti
pub fn[T] Matrix::each_row(Self[T], Int, (T) -> Unit) -> Unit
pub fn[T] Matrix::eachi_row(Self[T], Int, (Int, T) -> Unit) -> Unit
pub fn[T] Matrix::each_col(Self[T], Int, (T) -> Unit) -> Unit
pub fn[T] Matrix::eachi_col(Self[T], Int, (Int, T) -> Unit) -> Unit
```

### `Matrix::iter`, `Matrix::iter_row`, `Matrix::iter_col`

Iterators over all entries (row-major), one row, or one column.

```mbti
pub fn[T] Matrix::iter(Self[T]) -> Iter[T]
pub fn[T] Matrix::iter_row(Self[T], Int) -> Iter[T]
pub fn[T] Matrix::iter_col(Self[T], Int) -> Iter[T]
```

### `Matrix::map`, `Matrix::mapi`

`map(f)` and `mapi(f)` return a new matrix with `f` applied to every entry;
`mapi` also receives `(i, j)`.

```mbti
pub fn[T, U] Matrix::map(Self[T], (T) -> U) -> Self[U]
pub fn[T, U] Matrix::mapi(Self[T], (Int, Int, T) -> U) -> Self[U]
```

### `Matrix::map_inplace`, `Matrix::map_row_inplace`, `Matrix::map_col_inplace`

Replace every entry, every entry of one row, or every entry of one column by
`f(entry)`, in place.

```mbti
#alias(map_in_place, deprecated)
pub fn[T] Matrix::map_inplace(Self[T], (T) -> T) -> Unit
#alias(map_row_in_place, deprecated)
pub fn[T] Matrix::map_row_inplace(Self[T], Int, (T) -> T) -> Unit
#alias(map_col_in_place, deprecated)
pub fn[T] Matrix::map_col_inplace(Self[T], Int, (T) -> T) -> Unit
```

### `Matrix::swap_rows`, `Matrix::swap_cols`

Exchange two rows or two columns in place.

```mbti
pub fn[T] Matrix::swap_rows(Self[T], Int, Int) -> Unit
pub fn[T] Matrix::swap_cols(Self[T], Int, Int) -> Unit
```

Out-of-range indices abort; equal indices leave the matrix unchanged.

```moonbit check
///|
test "mutable traversal" {
  let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  let mut sum = 0
  m.each(x => sum = sum + x)
  inspect(sum, content="10")
  m.map_col_inplace(1, x => x * 10)
  m.swap_rows(0, 1)
  inspect(m, content="|3, 40|\n|1, 20|")
  debug_inspect(m.iter_col(0).to_array(), content="[3, 1]")
}
```

## Conversion

### `Matrix::to_array`, `Matrix::to_2d_array`, `Matrix::to_vector`

Copy all entries into a flat row-major array, nested rows, or a flat
`Vector`.

```mbti
pub fn[T] Matrix::to_array(Self[T]) -> Array[T]
pub fn[T] Matrix::to_2d_array(Self[T]) -> Array[Array[T]]
pub fn[T] Matrix::to_vector(Self[T]) -> Vector[T]
```

### `Matrix::row_to_array`, `Matrix::col_to_array`, `Matrix::row_to_vector`, `Matrix::col_to_vector`

Copy one row or column into an array or a `Vector`.

```mbti
pub fn[T] Matrix::row_to_array(Self[T], Int) -> Array[T]
pub fn[T] Matrix::col_to_array(Self[T], Int) -> Array[T]
pub fn[T] Matrix::row_to_vector(Self[T], Int) -> Vector[T]
pub fn[T] Matrix::col_to_vector(Self[T], Int) -> Vector[T]
```

### `Matrix::transpose`

`Matrix::transpose(m)` returns a new materialized transpose; compare
`to_transpose`, which returns a view.

```mbti
pub fn[T] Matrix::transpose(Self[T]) -> Self[T]
```

### `Matrix::horizontal_combine`, `Matrix::vertical_combine`

Block concatenation $[A \; B]$ and $\begin{bmatrix} A \\ B \end{bmatrix}$;
different row (respectively column) counts abort.

```mbti
pub fn[T] Matrix::horizontal_combine(Self[T], Self[T]) -> Self[T]
pub fn[T] Matrix::vertical_combine(Self[T], Self[T]) -> Self[T]
```

## Arithmetic

### `Matrix::add`, `Matrix::sub`, `Matrix::neg`

Entry-wise $A + B$, $A - B$, $-A$; they back the operators and abort on
different shapes.

```mbti
pub fn[T : Add] Matrix::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] Matrix::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] Matrix::neg(Self[T]) -> Self[T]
```

### `Matrix::scale`, `Matrix::add_constant`

Multiply every entry on the right by a scalar, or add a scalar to every entry.

```mbti
pub fn[T : Mul] Matrix::scale(Self[T], T) -> Self[T]
pub fn[T : Add] Matrix::add_constant(Self[T], T) -> Self[T]
```

### `Matrix::adjoint`

`Matrix::adjoint(m)` returns the conjugate transpose $A^{*}$; it needs a
scalar type with `Conjugate`.

```mbti
pub fn[T : @luna-generic.Conjugate] Matrix::adjoint(Self[T]) -> Self[T]
```

### `Matrix::null`

`Matrix::null(m)` returns `true` when every entry equals `Zero::zero()`
exactly.

```mbti
pub fn[T : Compare + @luna-generic.Zero] Matrix::null(Self[T]) -> Bool
```

### `Matrix::mul`

`Matrix::mul(a, b)` is the matrix product behind `a * b`.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Matrix::mul(Self[T], Self[T]) -> Self[T]
```

It checks $\operatorname{cols}(A) = \operatorname{rows}(B)$ and aborts with
`Matrix::mul: dimension mismatch` otherwise, then calls `unchecked_matmul`.
There is no `Result`-returning `matmul` in this package; check shapes first
or use `@immut.Matrix::matmul`.

### `Matrix::unchecked_matmul`

`Matrix::unchecked_matmul(a, b)` returns $AB$ **without validating shapes**.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Matrix::unchecked_matmul(Self[T], Self[T]) -> Self[T]
```

> [!CAUTION]
> The caller must guarantee $\operatorname{cols}(A) = \operatorname{rows}(B)$.
> On a violation the result is unspecified: it may abort with an array index
> error or silently return a wrong matrix. Use `*` unless the shapes are known.

Cost: $rcn$ multiply-adds. Large products (at least $4 \times 16 \times 16$)
pack the columns of $B$ contiguously before multiplying.

### `Matrix::mul_vec`

`Matrix::mul_vec(a, x)` returns `Ok(Ax)` when
$\operatorname{cols}(A) = \operatorname{len}(x)$ and `DimensionMismatch`
otherwise.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Matrix::mul_vec(Self[T], Vector[T]) -> Result[Vector[T], @error.LinearAlgebraError]
```

### `Matrix::unchecked_mul_vec`

`Matrix::unchecked_mul_vec(a, x)` returns $Ax$ and aborts on a length mismatch.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Matrix::unchecked_mul_vec(Self[T], Vector[T]) -> Vector[T]
```

### `Matrix::pow`, `Matrix::matrix_power`

`pow(k)` returns `Ok(A^k)` for square $A$ and $k \ge 0$ ($A^0 = I$), by binary
exponentiation. `matrix_power` is the same function under another name.

```mbti
pub fn[T : @luna-generic.Semiring] Matrix::pow(Self[T], Int) -> Result[Self[T], @error.LinearAlgebraError]
pub fn[T : @luna-generic.Semiring] Matrix::matrix_power(Self[T], Int) -> Result[Self[T], @error.LinearAlgebraError]
```

Errors: `NonSquareMatrix` (checked first), then `NegativeExponent`.

### `Matrix::unchecked_pow`, `Matrix::unchecked_matrix_power`

Aborting forms of `pow` and `matrix_power`.

```mbti
pub fn[T : @luna-generic.Semiring] Matrix::unchecked_pow(Self[T], Int) -> Self[T]
pub fn[T : @luna-generic.Semiring] Matrix::unchecked_matrix_power(Self[T], Int) -> Self[T]
```

### `Matrix::trace`, `Matrix::unchecked_trace`

`trace()` returns `Ok(Σ a_ii)` for a square matrix and `NonSquareMatrix`
otherwise; `unchecked_trace` aborts instead.

```mbti
pub fn[T : @luna-generic.AddMonoid] Matrix::trace(Self[T]) -> Result[T, @error.LinearAlgebraError]
pub fn[T : @luna-generic.AddMonoid] Matrix::unchecked_trace(Self[T]) -> T
```

```moonbit check
///|
test "mutable arithmetic" {
  let a = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let x = @mutable.Vector::from_array([1.0, 1.0])
  inspect(a.mul_vec(x).unwrap(), content="|3, 7|")
  inspect(a * a, content="|7, 10|\n|15, 22|")
  inspect(a.pow(0).unwrap(), content="|1, 0|\n|0, 1|")
  inspect(a.trace().unwrap(), content="5")
  inspect(
    a.mul_vec(@mutable.Vector::from_array([1.0])) is Err(_),
    content="true",
  )
}
```

## Linear systems and decompositions

All routines in this section are for `Float` and `Double` matrices. Decisions
such as "this pivot is zero" compare absolute values with `Tolerance::tolerance()`
($10^{-11}$); see the [design page](../design/mutable.md) for the algorithms,
costs and error bounds.

### `Matrix::determinant`

`Matrix::determinant(a)` returns `Ok(det A)` for a square matrix and
`NonSquareMatrix` otherwise.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::determinant(Self[T]) -> Result[T, @error.LinearAlgebraError]
```

For $n \le 4$: closed cofactor formulas. For $n \ge 5$: the product of the
diagonal if the matrix is exactly triangular, otherwise LU
factorization with partial pivoting, $\det A = (-1)^{s} \prod_i u_{ii}$ for $s$
row exchanges. If a pivot falls below the tolerance the result is exactly
zero; otherwise it is a product of pivots of magnitude at least $10^{-11}$,
which can still underflow to zero or overflow to infinity for large $n$.
$\det$ of the $0 \times 0$ matrix is $1$.

### `Matrix::unchecked_determinant`

Aborting form of `determinant`.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::unchecked_determinant(Self[T]) -> T
```

### `Matrix::inverse`

`Matrix::inverse(a)` returns `Ok(A^{-1})`, `NonSquareMatrix` for a non-square
matrix, or `SingularMatrix` when a pivot is below the tolerance.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::inverse(Self[T]) -> Result[Self[T], @error.LinearAlgebraError]
```

Identity, diagonal and permutation matrices are recognized and inverted
directly ($P^{-1} = P^{\mathsf T}$); other matrices are solved column by column
from an LU factorization with partial pivoting. Cost $\approx \tfrac{8}{3} n^3$
flops. The inverse of the $0 \times 0$ matrix is the $0 \times 0$ matrix.

The recognition is exact: only a matrix that has the structure exactly takes
the shortcut, so the shortcut returns what the LU path would.

### `Matrix::unchecked_inverse`

`Matrix::unchecked_inverse(a)` returns `Some(A^{-1})` or `None` for a singular
matrix, and aborts on a non-square one.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::unchecked_inverse(Self[T]) -> Self[T]?
```

### `Matrix::is_invertible`, `Matrix::unchecked_is_invertible`

`is_invertible()` returns `Ok(true)` when LU factorization finds no pivot
below the tolerance, `Ok(false)` otherwise, and `NonSquareMatrix` for a
non-square matrix; `unchecked_is_invertible` aborts instead.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::is_invertible(Self[T]) -> Result[Bool, @error.LinearAlgebraError]
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::unchecked_is_invertible(Self[T]) -> Bool
```

### `Matrix::rank`

`Matrix::rank(a)` returns the number of pivots found by Gaussian elimination
with partial pivoting on a copy of `a`.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::rank(Self[T]) -> Int
```

A column whose largest remaining entry is below the tolerance contributes no
pivot. Works for any shape; `a` is unchanged. Cost $O(\min(r, c)\, r c)$.

### `Matrix::reduce_row_elimination`

`Matrix::reduce_row_elimination(a)` transforms `a` **in place** into reduced
row echelon form by Gauss–Jordan elimination with partial pivoting, and
returns `a` itself.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::reduce_row_elimination(Self[T]) -> Self[T]
```

Columns are processed left to right. In each column the entry of largest
magnitude at or below the current row is swapped up; if its magnitude is at
most the tolerance, that one entry is set to zero and the column is skipped
(the other entries below it, also at most the tolerance, are left as they
are). Otherwise the pivot row is divided by the pivot, which makes the pivot
one, and every other row with an entry of magnitude above the tolerance in the
pivot column has a multiple of the pivot row subtracted; an entry at or below
the tolerance is set to zero without touching the rest of its row. Copy first
if you need the original.

### `Matrix::cholesky_decomposition`

`Matrix::cholesky_decomposition(a)` returns `Some(L)` with $L$ lower
triangular, positive diagonal and $L L^{\mathsf T} = A$, or `None`.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + @arithmetic.Sqrt + Tolerance] Matrix::cholesky_decomposition(Self[T]) -> Self[T]?
```

`None` means that `a` is not square, not symmetric within tolerance, or that a
diagonal pivot $a_{jj} - \sum_{k<j} l_{jk}^2$ is at most the tolerance (the
matrix is not positive definite, or nearly singular). Only the lower triangle
of `a` is read. Cost $\approx n^3/3$ flops.

Two fast paths run first: the exact identity is returned as a copy, and an
exactly diagonal matrix gives the square roots of its diagonal (or `None` if
one of them is at most the tolerance).

### `Matrix::is_positive_definite`

`Matrix::is_positive_definite(a)` returns whether `cholesky_decomposition`
succeeds.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + @arithmetic.Sqrt + Tolerance] Matrix::is_positive_definite(Self[T]) -> Bool
```

### `Matrix::is_symmetric`

`Matrix::is_symmetric(a)` returns `true` when `a` is square and
$|a_{ij} - a_{ji}| \le \mathrm{tol}$ for all $i < j$.

```mbti
pub fn[T : Compare + @luna-generic.Num + Tolerance] Matrix::is_symmetric(Self[T]) -> Bool
```

```moonbit check
///|
test "solving and factorizing" {
  let a = @mutable.Matrix::from_2d_array([[4.0, 2.0], [2.0, 3.0]])
  inspect(a.determinant().unwrap(), content="8")
  inspect(a.inverse().unwrap(), content="|0.375, -0.25|\n|-0.25, 0.5|")
  let l = a.cholesky_decomposition().unwrap()
  inspect(l, content="|2, 0|\n|1, 1.4142135623730951|")
  inspect(a.is_positive_definite(), content="true")
  let r = @mutable.Matrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [2.0, 4.0, 6.0],
    [7.0, 8.0, 9.0],
  ])
  inspect(r.rank(), content="2")
  inspect(r.is_invertible().unwrap(), content="false")
}
```

## Eigenvalues

### `Matrix::eigen`

`Matrix::eigen(a)` returns the eigenvalues and eigenvectors of a real
symmetric matrix as `(values, vectors)`, where column $k$ of `vectors` is an
eigenvector for `values[k]`.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + @arithmetic.Sqrt + Tolerance] Matrix::eigen(Self[T]) -> (Vector[T], Self[T])
```

- Aborts if `a` is not square, not symmetric within tolerance, or if an
  eigenvalue does not converge within 60 iterations.
- For $2 \times 2$ input a closed formula is used on the symmetric part
  $\begin{pmatrix} a & s \\ s & d \end{pmatrix}$, $s = \tfrac12 (a_{01} + a_{10})$:
  $\lambda_{1,2} = m \pm \sqrt{\big(\tfrac{a-d}{2}\big)^2 + s^2}$ with
  $m = \tfrac12 \operatorname{tr} A$, ordered $\lambda_1 \ge \lambda_2$. The
  eigenvector columns are **not normalized**: each is scaled so that its entry
  of largest magnitude is $1$. A diagonal matrix returns its diagonal entries
  exactly.
- For other sizes the matrix is reduced to tridiagonal form by Householder
  reflections and diagonalized by the implicit QL algorithm with Wilkinson
  shifts. Only the lower triangle is read. The eigenvector columns are
  orthonormal up to rounding. The eigenvalues are not sorted.
- Cost $O(n^3)$.

Every decision inside `eigen` is relative to the entries (a deflated
off-diagonal entry is negligible next to its diagonal neighbours), so
`eigen` of $sA$ is $s$ times `eigen` of $A$ up to rounding, for any scale $s$;
only the symmetry check uses the absolute tolerance. See the
[design page](../design/mutable.md#symmetric-eigenvalue-problem).

### `Matrix::power_method`

`Matrix::power_method(a, max_iterations)` approximates a dominant eigenpair
$(\lambda, x)$ by power iteration and returns `Some((λ, x))` once
$\lVert A x - \lambda x \rVert_\infty \le \mathrm{tol}$.

```mbti
pub fn[T : Compare + @luna-generic.Field + @luna-generic.Num + Tolerance] Matrix::power_method(Self[T], Int) -> (T, Vector[T])?
```

- $x$ is scaled so that $\lVert x \rVert_\infty = 1$; $\lambda$ is the Rayleigh
  quotient $x^{\mathsf T} A x / x^{\mathsf T} x$.
- Returns `None` when the iteration does not meet the residual test within
  `max_iterations` steps, or when the iterate becomes numerically zero (for
  example for a nilpotent matrix). Two dominant eigenvalues of equal magnitude
  and opposite sign, such as $\pm 1$, prevent convergence.
- Aborts for a non-square or empty matrix.
- Each iteration costs two matrix-vector products, $O(n^2)$: one for the
  Rayleigh quotient and the residual, and one for the next iterate (the code
  does not reuse the first). The starting vector is $(1, \dots, 1)$, or the
  first coordinate vector $e_k$ with $A e_k$ above the tolerance if
  $A (1, \dots, 1)^{\mathsf T}$ is not; it is multiplied by $A$ and scaled
  once before the first residual test.
- The residual test is absolute, so the accuracy of $x$ scales with
  $\lVert A \rVert$: for a matrix of size about $10^{-6}$ the test passes while
  $x$ is still wrong in the sixth digit.

```moonbit check
///|
test "eigenvalues" {
  let a = @mutable.Matrix::from_2d_array([[2.0, 1.0], [1.0, 2.0]])
  let (values, vectors) = a.eigen()
  inspect(values, content="|3, 1|")
  inspect(vectors, content="|1, 1|\n|1, -1|")
  let b = @mutable.Matrix::from_2d_array([[2.0, 1.0], [1.0, 3.0]])
  let (lambda, x) = b.power_method(200).unwrap()
  inspect((lambda - 3.618033988749895).abs() < 1.0e-9, content="true")
  inspect(x[1], content="1")
  let flip = @mutable.Matrix::from_2d_array([[1.0, 0.0], [0.0, -1.0]])
  inspect(flip.power_method(100) is None, content="true")
  let close = @mutable.Matrix::from_2d_array([[1.0, 1.0e-6], [1.0e-6, 1.0]])
  let (cv, cw) = close.eigen()
  inspect((cv[0] - cv[1] - 2.0e-6).abs() < 1.0e-15, content="true")
  inspect(cw, content="|1, 1|\n|1, -1|")
}
```

## Statistics and norms

The statistics treat the matrix as a flat list of its $N = rc$ entries.

### `Matrix::mean`, `Matrix::unchecked_mean`

`mean()` returns `Ok(\bar a)`, $\bar a = \tfrac1N \sum a_{ij}$, or
`EmptyMatrix` when $N = 0$; `unchecked_mean` aborts instead.

```mbti
pub fn[T : @luna-generic.Field] Matrix::mean(Self[T]) -> Result[T, @error.LinearAlgebraError]
pub fn[T : @luna-generic.Field] Matrix::unchecked_mean(Self[T]) -> T
```

### `Matrix::variance`, `Matrix::unchecked_variance`

`variance()` returns the population variance
$\tfrac1N \sum (a_{ij} - \bar a)^2$ (two-pass), or `EmptyMatrix`.

```mbti
pub fn[T : @luna-generic.Field] Matrix::variance(Self[T]) -> Result[T, @error.LinearAlgebraError]
pub fn[T : @luna-generic.Field] Matrix::unchecked_variance(Self[T]) -> T
```

### `Matrix::std_dev`, `Matrix::unchecked_std_dev`

`std_dev()` returns the square root of the population variance, or
`EmptyMatrix`.

```mbti
pub fn[T : @luna-generic.Field + @arithmetic.Sqrt] Matrix::std_dev(Self[T]) -> Result[T, @error.LinearAlgebraError]
pub fn[T : @luna-generic.Field + @arithmetic.Sqrt] Matrix::unchecked_std_dev(Self[T]) -> T
```

### `Matrix::max_element`, `Matrix::min_element`

The largest or smallest entry by `Compare`, or `EmptyMatrix`.

```mbti
pub fn[T : Compare] Matrix::max_element(Self[T]) -> Result[T, @error.LinearAlgebraError]
pub fn[T : Compare] Matrix::min_element(Self[T]) -> Result[T, @error.LinearAlgebraError]
```

With NaN entries the result depends on their position; filter them first.

### `Matrix::unchecked_max_element`, `Matrix::unchecked_min_element`

Aborting forms of `max_element` and `min_element`.

```mbti
pub fn[T : Compare] Matrix::unchecked_max_element(Self[T]) -> T
pub fn[T : Compare] Matrix::unchecked_min_element(Self[T]) -> T
```

### `Matrix::frobenius_norm`

`Matrix::frobenius_norm(a)` returns $\lVert A \rVert_F = \sqrt{\sum a_{ij}^2}$.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul + @arithmetic.Sqrt] Matrix::frobenius_norm(Self[T]) -> T
```

The sum of squares is not rescaled, so entries above about $10^{154}$ overflow
for `Double`. An empty matrix has norm $0$.

```moonbit check
///|
test "statistics" {
  let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  inspect(m.mean().unwrap(), content="2.5")
  inspect(m.variance().unwrap(), content="1.25")
  inspect(m.max_element().unwrap(), content="4")
  inspect(
    @mutable.Matrix::from_2d_array([[3.0, 4.0]]).frobenius_norm(),
    content="5",
  )
}
```

## Views

### `RowView::get`, `RowView::set`, `ColView::get`, `ColView::set`

Read or write position `i` of the viewed row or column; they back `view[i]`
and `view[i] = x`.

```mbti
#alias("_[_]")
pub fn[T] RowView::get(Self[T], Int) -> T
#alias("_[_]=_")
pub fn[T] RowView::set(Self[T], Int, T) -> Unit
#alias("_[_]")
pub fn[T] ColView::get(Self[T], Int) -> T
#alias("_[_]=_")
pub fn[T] ColView::set(Self[T], Int, T) -> Unit
```

### `RowView::length`, `ColView::length`

The number of columns (row view) or rows (column view) of the matrix.

```mbti
pub fn[T] RowView::length(Self[T]) -> Int
pub fn[T] ColView::length(Self[T]) -> Int
```

### `RowView::each`, `RowView::eachi`, `RowView::iter`, `ColView::each`, `ColView::eachi`, `ColView::iter`

Traverse the viewed entries in order.

```mbti
pub fn[T] RowView::each(Self[T], (T) -> Unit) -> Unit
pub fn[T] RowView::eachi(Self[T], (Int, T) -> Unit) -> Unit
pub fn[T] RowView::iter(Self[T]) -> Iter[T]
pub fn[T] ColView::each(Self[T], (T) -> Unit) -> Unit
pub fn[T] ColView::eachi(Self[T], (Int, T) -> Unit) -> Unit
pub fn[T] ColView::iter(Self[T]) -> Iter[T]
```

### `RowView::map_inplace`, `ColView::map_inplace`

Replace every viewed entry by `f(entry)`, in the underlying matrix.

```mbti
pub fn[T] RowView::map_inplace(Self[T], (T) -> T) -> Unit
pub fn[T] ColView::map_inplace(Self[T], (T) -> T) -> Unit
```

### `RowView::to_array`, `RowView::to_vector`, `ColView::to_array`, `ColView::to_vector`

Copy the viewed entries out.

```mbti
pub fn[T] RowView::to_array(Self[T]) -> Array[T]
pub fn[T] RowView::to_vector(Self[T]) -> Vector[T]
pub fn[T] ColView::to_array(Self[T]) -> Array[T]
pub fn[T] ColView::to_vector(Self[T]) -> Vector[T]
```

### `RowView::to_string`, `ColView::to_string`

Render the viewed entries as `|a, b, c|`.

```mbti
pub fn[T : Show] RowView::to_string(Self[T]) -> String
pub fn[T : Show] ColView::to_string(Self[T]) -> String
```

## Transpose view

Every `Transpose` method addresses the transposed matrix and works on the
shared storage, unless it is documented to return a new value.

### `Transpose::row`, `Transpose::col`

The shape of the view: `row()` is the column count of the wrapped matrix and
`col()` its row count.

```mbti
pub fn[T] Transpose::row(Self[T]) -> Int
pub fn[T] Transpose::col(Self[T]) -> Int
```

### `Transpose::get`, `Transpose::set`, `Transpose::at`

`get(i, j)` and `set(i, j, x)` access entry $(i, j)$ of the view, that is
$(j, i)$ of the matrix; `at` backs `t[i][j]` and `t[i][j] = x`.

```mbti
pub fn[T] Transpose::get(Self[T], Int, Int) -> T
pub fn[T] Transpose::set(Self[T], Int, Int, T) -> Unit
#alias("_[_]")
pub fn[T] Transpose::at(Self[T], Int) -> Lens[T]
```

### `Transpose::transpose`

`Transpose::transpose(t)` returns the wrapped matrix itself, not a copy.

```mbti
pub fn[T] Transpose::transpose(Self[T]) -> Matrix[T]
```

### `Transpose::materialize`

`Transpose::materialize(t)` copies the view into a new matrix of the
transposed shape.

```mbti
pub fn[T] Transpose::materialize(Self[T]) -> Matrix[T]
```

### `Transpose::copy`

`Transpose::copy(t)` returns a view of a deep copy of the wrapped matrix.

```mbti
pub fn[T] Transpose::copy(Self[T]) -> Self[T]
```

### Traversal: `Transpose::each`, `Transpose::eachi`, `Transpose::each_row_col`, `Transpose::each_row`, `Transpose::eachi_row`, `Transpose::each_col`, `Transpose::eachi_col`

Traverse the view.

```mbti
pub fn[T] Transpose::each(Self[T], (T) -> Unit) -> Unit
pub fn[T] Transpose::eachi(Self[T], (Int, T) -> Unit) -> Unit
pub fn[T] Transpose::each_row_col(Self[T], (Int, Int, T) -> Unit) -> Unit
pub fn[T] Transpose::each_row(Self[T], Int, (T) -> Unit) -> Unit
pub fn[T] Transpose::eachi_row(Self[T], Int, (Int, T) -> Unit) -> Unit
pub fn[T] Transpose::each_col(Self[T], Int, (T) -> Unit) -> Unit
pub fn[T] Transpose::eachi_col(Self[T], Int, (Int, T) -> Unit) -> Unit
```

`each`, `eachi` and `each_row_col` visit entries in the storage order of the
wrapped matrix, which is column-major for the view; `eachi` passes the
row-major index *of the view*, and `each_row_col` passes view coordinates. The
row and column forms visit a row or column of the view in order.

### `Transpose::row_to_array`, `Transpose::col_to_array`, `Transpose::row_to_vector`, `Transpose::col_to_vector`

Copy one row or column of the view.

```mbti
pub fn[T] Transpose::row_to_array(Self[T], Int) -> Array[T]
pub fn[T] Transpose::col_to_array(Self[T], Int) -> Array[T]
pub fn[T] Transpose::row_to_vector(Self[T], Int) -> Vector[T]
pub fn[T] Transpose::col_to_vector(Self[T], Int) -> Vector[T]
```

### `Transpose::map`, `Transpose::map_inplace`, `Transpose::map_row_inplace`, `Transpose::map_col_inplace`

`map` returns a new view of a new matrix; the `*_inplace` forms change the
shared storage.

```mbti
pub fn[T] Transpose::map(Self[T], (T) -> T) -> Self[T]
#alias(map_in_place, deprecated)
pub fn[T] Transpose::map_inplace(Self[T], (T) -> T) -> Unit
#alias(map_row_in_place, deprecated)
pub fn[T] Transpose::map_row_inplace(Self[T], Int, (T) -> T) -> Unit
#alias(map_col_in_place, deprecated)
pub fn[T] Transpose::map_col_inplace(Self[T], Int, (T) -> T) -> Unit
```

### `Transpose::swap_rows`, `Transpose::swap_cols`

Exchange two rows or columns of the view in place (columns or rows of the
wrapped matrix).

```mbti
pub fn[T] Transpose::swap_rows(Self[T], Int, Int) -> Unit
pub fn[T] Transpose::swap_cols(Self[T], Int, Int) -> Unit
```

### `Transpose::horizontal_combine`, `Transpose::vertical_combine`

Block concatenation of views, returning a view of a new matrix.

```mbti
pub fn[T] Transpose::horizontal_combine(Self[T], Self[T]) -> Self[T]
pub fn[T] Transpose::vertical_combine(Self[T], Self[T]) -> Self[T]
```

### `Transpose::add`, `Transpose::sub`, `Transpose::neg`, `Transpose::scale`, `Transpose::add_constant`

Entry-wise arithmetic, returning a view of a new matrix.

```mbti
pub fn[T : Add] Transpose::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] Transpose::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] Transpose::neg(Self[T]) -> Self[T]
pub fn[T : Mul] Transpose::scale(Self[T], T) -> Self[T]
pub fn[T : Add] Transpose::add_constant(Self[T], T) -> Self[T]
```

### `Transpose::mul`

`Transpose::mul(s, t)` returns the product of two views, computed as
$A^{\mathsf T} B^{\mathsf T} = (BA)^{\mathsf T}$ without moving data.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Transpose::mul(Self[T], Self[T]) -> Self[T]
```

> [!WARNING]
> The identity $A^{\mathsf T} B^{\mathsf T} = (BA)^{\mathsf T}$ holds only for
> commuting scalars. For a non-commutative scalar type, materialize the views
> and multiply the matrices instead.

### `Transpose::equal`, `Transpose::to_string`

`equal` compares the wrapped matrices; `to_string` renders the view row by row.

```mbti
pub fn[T : Eq] Transpose::equal(Self[T], Self[T]) -> Bool
pub fn[T : Show] Transpose::to_string(Self[T]) -> String
```

```moonbit check
///|
test "transpose view" {
  let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let t = m.to_transpose()
  inspect(t, content="|1, 4|\n|2, 5|\n|3, 6|")
  t[2][0] = 30
  inspect(m.get(0, 2), content="30")
  let s = @mutable.Matrix::from_2d_array([[1, 0], [0, 1], [1, 1]]).to_transpose()
  let product = t * s
  debug_inspect((product.row(), product.col()), content="(3, 3)")
  inspect(t.materialize().row(), content="3")
  let order = []
  t.each(x => order.push(x))
  debug_inspect(order, content="[1, 2, 30, 4, 5, 6]")
}
```

## Vector

### `Vector::from_array`

`Vector::from_array(xs)` adopts `xs` as the vector's storage without copying.

```mbti
pub fn[A] Vector::from_array(Array[A]) -> Self[A]
```

### `Vector::make`, `Vector::makei`

$n$ copies of a value, or $(f(0), \dots, f(n-1))$.

```mbti
pub fn[A] Vector::make(Int, A) -> Self[A]
pub fn[A] Vector::makei(Int, (Int) -> A) -> Self[A]
```

### `Vector::length`, `Vector::copy`, `Vector::iter`

Length, deep copy, and iterator.

```mbti
pub fn[A] Vector::length(Self[A]) -> Int
pub fn[A] Vector::copy(Self[A]) -> Self[A]
pub fn[T] Vector::iter(Self[T]) -> Iter[T]
```

### `Vector::at`, `Vector::set`

Read or write element `i` in place; they back `v[i]` and `v[i] = x`. An
out-of-range index aborts.

```mbti
#alias("_[_]")
pub fn[A] Vector::at(Self[A], Int) -> A
#alias("_[_]=_")
pub fn[A] Vector::set(Self[A], Int, A) -> Unit
```

### `Vector::map`, `Vector::zip_with`, `Vector::map_inplace`

`map` and `zip_with` return new vectors (`zip_with` aborts on different
lengths); `map_inplace` rewrites every element.

```mbti
pub fn[A, B] Vector::map(Self[A], (A) -> B) -> Self[B]
pub fn[A, U, V] Vector::zip_with(Self[A], Self[U], (A, U) -> V) -> Self[V]
#alias(map_in_place, deprecated)
pub fn[A] Vector::map_inplace(Self[A], (A) -> A) -> Unit
```

### `Vector::add`, `Vector::mul`, `Vector::neg`, `Vector::add_constant`

Element-wise $u + v$, Hadamard $u \odot v$, $-u$, and $u + a$. Different
lengths abort. There is no `Sub`; write `u + -v`.

```mbti
pub fn[T : Add] Vector::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Mul] Vector::mul(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] Vector::neg(Self[T]) -> Self[T]
pub fn[T : Add] Vector::add_constant(Self[T], T) -> Self[T]
```

### `Vector::left_scale`, `Vector::right_scale`, `Vector::left_scale_inplace`, `Vector::right_scale_inplace`

$(a v_i)$ and $(v_i a)$, as new vectors or in place.

```mbti
pub fn[A : Mul] Vector::left_scale(Self[A], A) -> Self[A]
pub fn[A : Mul] Vector::right_scale(Self[A], A) -> Self[A]
#alias(left_scale_in_place, deprecated)
pub fn[A : Mul] Vector::left_scale_inplace(Self[A], A) -> Unit
#alias(right_scale_in_place, deprecated)
pub fn[A : Mul] Vector::right_scale_inplace(Self[A], A) -> Unit
```

### `Vector::dot`

`Vector::dot(u, v)` returns $\sum_i u_i v_i$, summed left to right; different
lengths abort.

```mbti
pub fn[T : @luna-generic.AddMonoid + Mul] Vector::dot(Self[T], Self[T]) -> T
```

### `Vector::lerp`

`Vector::lerp(u, v, t)` returns $(1 - t) u + t v$.

```mbti
pub fn[T : @luna-generic.MulMonoid + Add + Neg] Vector::lerp(Self[T], Self[T], T) -> Self[T]
```

### `Vector::lin_comb`

`Vector::lin_comb(weights, vectors)` returns $\sum_k w_k v_k$, accumulated
into one new vector.

```mbti
pub fn[T : Mul + Add + @luna-generic.Zero] Vector::lin_comb(Array[T], Array[Self[T]]) -> Self[T]
```

Empty inputs, different counts of weights and vectors, or vectors of different
lengths abort.

### `lin_comb`

`lin_comb(a, u, b, v)` returns $a u + b v$; it is a top-level function.

```mbti
pub fn[T : Add + Mul] lin_comb(T, Vector[T], T, Vector[T]) -> Vector[T]
```

### `Vector::to_row_matrix`, `Vector::to_col_matrix`, `Vector::scaled_matrix`, `Vector::tensor_product`

The vector as a $1 \times n$ or $n \times 1$ matrix (copied), the diagonal
matrix $\operatorname{diag}(v)$, and the outer product $u v^{\mathsf T}$.

```mbti
pub fn[T] Vector::to_row_matrix(Self[T]) -> Matrix[T]
pub fn[T] Vector::to_col_matrix(Self[T]) -> Matrix[T]
pub fn[T : @luna-generic.Zero] Vector::scaled_matrix(Self[T]) -> Matrix[T]
pub fn[T : Mul] Vector::tensor_product(Self[T], Self[T]) -> Matrix[T]
```

### `Vector::equal`, `Vector::to_string`

`equal` compares elements (backs `==`); `to_string` renders `|a, b, c|`.

```mbti
pub fn[T : Eq] Vector::equal(Self[T], Self[T]) -> Bool
pub fn[T : Show] Vector::to_string(Self[T]) -> String
```

```moonbit check
///|
test "mutable vectors" {
  let v = @mutable.Vector::from_array([1, 2, 3])
  v[0] = 10
  v.left_scale_inplace(2)
  inspect(v, content="|20, 4, 6|")
  inspect(v.dot(@mutable.Vector::make(3, 1)), content="30")
  let w = @mutable.Vector::lin_comb([1, 2], [
    v,
    @mutable.Vector::makei(3, i => i),
  ])
  inspect(w, content="|20, 6, 10|")
  inspect(@mutable.lin_comb(1, v, -1, w), content="|0, -2, -4|")
}
```

## Deprecated

| Item | Replacement |
| --- | --- |
| `Matrix::map_in_place`, `map_row_in_place`, `map_col_in_place` (aliases) | `map_inplace`, `map_row_inplace`, `map_col_inplace` |
| `Transpose::map_in_place`, `map_row_in_place`, `map_col_in_place` (aliases) | the `*_inplace` names |
| `Vector::map_in_place`, `left_scale_in_place`, `right_scale_in_place` (aliases) | `map_inplace`, `left_scale_inplace`, `right_scale_inplace` |
| `not_equal` method form on `Matrix`, `Transpose`, `Vector` (hidden) | `!=` |
| `output` method form on `Matrix`, `Transpose`, `RowView`, `ColView`, `Vector` (hidden) | string interpolation or `Show::output(x, logger)` |
| `Vector::to_repr` (hidden) | `Repr(v)` or `@debug.Debug::to_repr(v)` |
| `Vector::arbitrary` (hidden) | `@quickcheck.Arbitrary::arbitrary` |
