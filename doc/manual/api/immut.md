# immut API

## Purpose

`Luna-Flow/linear-algebra/immut` provides value-oriented dense linear algebra:
`Matrix[T]` and `Vector[T]` are immutable values backed by a persistent vector,
and `MatrixFn[T]` is a lazy matrix given by a function of its coordinates.
Every operation returns a new value and leaves its arguments unchanged.

Source: [`src/immut`](../../../src/immut/matrix.mbt). The value semantics, the
determinant algorithm and the cost model are explained in the
[immut design](../design/immut.md); [`mutable`](mutable.md) is the in-place
counterpart with the same core names.

## Importing

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/immut",
}
```

The examples on this page write every name with its package prefix, such as
`@immut.`, instead of a `using` declaration: all pages of this manual
compile into one test package, where the declarations of different pages
would clash.

## Conventions

- **Shapes.** A matrix has `row()` rows and `col()` columns, both
  non-negative. $0 \times n$ and $n \times 0$ are valid and distinct; `==`
  compares shape and entries.
- **Storage.** Entries are stored in row-major order in a persistent vector
  (`moonbitlang/core/immut/vector`, a 32-way trie). Reading or replacing one
  entry costs $O(\log_{32}(rc))$; whole-matrix operations cost $O(rc)$.
- **Indexing.** `m[r][c]` reads an entry: `m[r]` (`Matrix::at`) returns an
  `Indexed[T]` row accessor and `[c]` (`Indexed::at`) reads from it. Both
  indices are bounds-checked and abort when out of range. There is no
  `m[r][c] = x`; use `set`, which returns a new matrix.
- **Checked and unchecked.** `matmul`, `trace`, `determinant` and `pow` return
  `Result[_, LinearAlgebraError]`. Their `unchecked_*` partners and the
  operators `+`, `-`, `*` abort when the precondition fails. See the
  [error design](../design/error.md) for the law relating the two.
- **Scalars.** Bounds come from `luna-generic`: `Zero`, `One`, `Semiring`,
  `Num` (a ring with `abs` and `signum`), `Conjugate`. Determinants also
  require this package's `DeterminantScalar` strategy.

## Types

### `Matrix`

`Matrix[T]` is an immutable dense $r \times c$ matrix.

```mbti
type Matrix[T] derive(Eq)
```

The type is abstract: build it with the constructors below. It implements
`Eq`, `Show` (rows printed as `|a, b|` separated by newlines), `Add`, `Sub`,
`Neg`, `Mul` (matrix product) under the element constraints of the
corresponding methods.

### `Indexed`

`Indexed[T]` is the row accessor returned by `m[r]`.

```mbti
type Indexed[T]
```

It is a function from a column index to an entry; it holds no copy of the row.

### `Indexed::at`

`Indexed::at(row, c)` returns the entry in column `c`; it backs `m[r][c]`.

```mbti
#alias("_[_]")
pub fn[T] Indexed::at(Self[T], Int) -> T
```

A column index outside `0..<col()` aborts.

### `MatrixFn`

`MatrixFn[T]` is a lazy matrix: a shape and a function $(i, j) \mapsto a_{ij}$.

```mbti
type MatrixFn[T]
```

Entries are computed on every read and never stored. Its methods are listed in
[`MatrixFn` operations](#matrixfn-operations).

### `Vector`

`Vector[T]` is an immutable dense vector.

```mbti
#alias(VecLib)
type Vector[T] derive(Eq)
```

It implements `Eq`, `Show` (printed as `|a, b, c|`), `Add`, `Mul`
(element-wise), `Neg`, `Debug` and quickcheck's `Arbitrary`.

### `VecLib`

`VecLib[T]` is an alias of `Vector[T]`.

```mbti
#alias(VecLib)
type Vector[T]
```

### `VecCore`

`VecCore[T]` is an alias of the core persistent vector
`@moonbitlang/core/immut/vector.Vector[T]` that backs `Vector`.

```mbti
pub using @vector {type Vector as VecCore}
```

## Matrix construction

### `Matrix::make`

`Matrix::make(r, c, f)` builds the $r \times c$ matrix with entries
$a_{ij} = f(i, j)$.

```mbti
pub fn[T] Matrix::make(Int, Int, (Int, Int) -> T) -> Self[T]
```

`f` is called once per entry in row-major order, and not at all when $r = 0$ or
$c = 0$. Negative dimensions abort.

### `Matrix::new`

`Matrix::new(r, c, x)` builds an $r \times c$ matrix with every entry `x`.

```mbti
pub fn[T] Matrix::new(Int, Int, T) -> Self[T]
```

### `Matrix::from_2d_array`

`Matrix::from_2d_array(rows)` builds a matrix from nested row arrays.

```mbti
pub fn[T] Matrix::from_2d_array(Array[Array[T]]) -> Self[T]
```

`[]` gives $0 \times 0$; `[[], []]` gives $2 \times 0$. Rows of different
lengths abort. The input is copied.

### `Matrix::from_array`

`Matrix::from_array(r, c, v)` uses the vector `v` as the row-major entries of
an $r \times c$ matrix.

```mbti
pub fn[T] Matrix::from_array(Int, Int, Vector[T]) -> Self[T]
```

Negative dimensions or `v.length() != r * c` abort. No copy is made; `v` is
immutable.

### `Matrix::identity`

`Matrix::identity(n)` builds the $n \times n$ identity matrix $I_n$.

```mbti
pub fn[T : @luna-generic.One + @luna-generic.Zero] Matrix::identity(Int) -> Self[T]
```

A negative `n` aborts.

```moonbit check
///|
test "immut matrix construction" {
  let a = @immut.Matrix::make(2, 3, (i, j) => 10 * i + j)
  inspect(a, content="|0, 1, 2|\n|10, 11, 12|")
  let b = @immut.Matrix::from_array(
    2,
    2,
    @immut.Vector::from_array([1, 2, 3, 4]),
  )
  inspect(b, content="|1, 2|\n|3, 4|")
  let i3 : @immut.Matrix[Int] = @immut.Matrix::identity(3)
  inspect(i3, content="|1, 0, 0|\n|0, 1, 0|\n|0, 0, 1|")
  let empty : @immut.Matrix[Int] = @immut.Matrix::from_2d_array([[], []])
  debug_inspect(empty.shape(), content="(2, 0)")
}
```

## Shape and access

### `Matrix::row`, `Matrix::col`

`row` and `col` return the number of rows and columns.

```mbti
pub fn[T] Matrix::row(Self[T]) -> Int
pub fn[T] Matrix::col(Self[T]) -> Int
```

### `Matrix::shape`

`Matrix::shape(m)` returns `(row, col)`.

```mbti
pub fn[T] Matrix::shape(Self[T]) -> (Int, Int)
```

### `Matrix::is_square`

`Matrix::is_square(m)` returns `row() == col()`; a $0 \times 0$ matrix is
square.

```mbti
pub fn[T] Matrix::is_square(Self[T]) -> Bool
```

### `Matrix::null`

`Matrix::null(m)` returns `true` when every entry equals `Zero::zero()`;
an empty matrix is null.

```mbti
pub fn[T : Compare + @luna-generic.Zero] Matrix::null(Self[T]) -> Bool
```

### `Matrix::at`

`Matrix::at(m, r)` returns the accessor for row `r`; it backs `m[r]`.

```mbti
#alias("_[_]")
pub fn[T] Matrix::at(Self[T], Int) -> Indexed[T]
```

A row index outside `0..<row()` aborts immediately.

### `Matrix::set`

`Matrix::set(m, r, c, x)` returns a matrix equal to `m` except that entry
$(r, c)$ is `x`.

```mbti
pub fn[T] Matrix::set(Self[T], Int, Int, T) -> Self[T]
```

`m` is unchanged. Out-of-range indices abort. Cost $O(\log_{32}(rc))$; the new
matrix shares all other storage with `m`.

### `Matrix::equal`

`Matrix::equal(a, b)` compares shapes and entries; it backs `==`.

```mbti
pub fn[T : Eq] Matrix::equal(Self[T], Self[T]) -> Bool
```

### `Matrix::to_string`

`Matrix::to_string(m)` renders the rows as `|a, b|` lines joined by `\n`.

```mbti
pub fn[T : Show] Matrix::to_string(Self[T]) -> String
```

An empty matrix renders as the empty string.

```moonbit check
///|
test "immut access and update" {
  let m = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let m2 = m.set(0, 1, 20)
  inspect(m[0][1], content="2")
  inspect(m2[0][1], content="20")
  inspect(m == m2, content="false")
  inspect(m.is_square(), content="true")
  inspect(@immut.Matrix::new(2, 2, 0).null(), content="true")
}
```

## Element-wise transforms

### `Matrix::map`

`Matrix::map(m, f)` applies `f` to every entry; the element type may change.

```mbti
pub fn[T, U] Matrix::map(Self[T], (T) -> U) -> Self[U]
```

### `Matrix::mapi`

`Matrix::mapi(m, f)` applies `f(i, j, a_ij)` to every entry.

```mbti
pub fn[T, U] Matrix::mapi(Self[T], (Int, Int, T) -> U) -> Self[U]
```

### `Matrix::scale`

`Matrix::scale(m, a)` multiplies every entry on the right by `a`: $(a_{ij} a)$.

```mbti
pub fn[T : Mul] Matrix::scale(Self[T], T) -> Self[T]
```

### `Matrix::add_constant`

`Matrix::add_constant(m, a)` adds `a` to every entry.

```mbti
pub fn[T : Add] Matrix::add_constant(Self[T], T) -> Self[T]
```

### `Matrix::adjoint`

`Matrix::adjoint(m)` returns the conjugate transpose $A^{*}$,
$(A^{*})_{ij} = \overline{a_{ji}}$.

```mbti
pub fn[T : @luna-generic.Conjugate] Matrix::adjoint(Self[T]) -> Self[T]
```

It needs a scalar type that implements `Conjugate`, such as a complex number
type; the builtin real types do not.

```moonbit check
///|
test "immut element-wise transforms" {
  let m = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  inspect(m.map(x => x * x), content="|1, 4|\n|9, 16|")
  inspect(
    m.mapi((i, j, x) => if i == j { x } else { 0 }),
    content="|1, 0|\n|0, 4|",
  )
  inspect(m.scale(10).add_constant(1), content="|11, 21|\n|31, 41|")
}
```

## Arithmetic

### `Matrix::add`, `Matrix::sub`, `Matrix::neg`

Entry-wise $A + B$, $A - B$ and $-A$; these back the operators.

```mbti
pub fn[T : Add] Matrix::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] Matrix::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] Matrix::neg(Self[T]) -> Self[T]
```

Operands of different shapes abort.

### `Matrix::mul`

`Matrix::mul(a, b)` is the matrix product behind `a * b`; it is
`unchecked_matmul`.

```mbti
pub fn[T : Mul + Add + @luna-generic.Zero] Matrix::mul(Self[T], Self[T]) -> Self[T]
```

### `Matrix::matmul`

`Matrix::matmul(a, b)` returns `Ok(AB)` when
$\operatorname{cols}(A) = \operatorname{rows}(B)$, and `Err` with kind
`DimensionMismatch` otherwise.

```mbti
pub fn[T : Mul + Add + @luna-generic.Zero] Matrix::matmul(Self[T], Self[T]) -> Result[Self[T], @error.LinearAlgebraError]
```

$(AB)_{ik} = \sum_{j} a_{ij} b_{jk}$, summed in increasing $j$. When the inner
dimension is $0$ the result is the zero matrix of shape
$\operatorname{rows}(A) \times \operatorname{cols}(B)$, the empty sum. Cost:
$rcn$ multiply-adds plus an $O(cn)$ transposed copy of $B$.

### `Matrix::unchecked_matmul`

`Matrix::unchecked_matmul(a, b)` returns $AB$ and aborts on incompatible
shapes.

```mbti
pub fn[T : Mul + Add + @luna-generic.Zero] Matrix::unchecked_matmul(Self[T], Self[T]) -> Self[T]
```

### `Matrix::pow`

`Matrix::pow(a, k)` returns `Ok(A^k)` for a square matrix and $k \ge 0$, with
$A^0 = I$.

```mbti
pub fn[T : @luna-generic.Semiring] Matrix::pow(Self[T], Int) -> Result[Self[T], @error.LinearAlgebraError]
```

A non-square matrix gives `NonSquareMatrix` (checked first); a negative
exponent gives `NegativeExponent`. The power is computed by binary
exponentiation with at most $2\lfloor\log_2 k\rfloor + 1$ matrix products.

### `Matrix::unchecked_pow`

`Matrix::unchecked_pow(a, k)` returns $A^k$ and aborts on a non-square matrix
or negative exponent.

```mbti
pub fn[T : @luna-generic.Semiring] Matrix::unchecked_pow(Self[T], Int) -> Self[T]
```

### `Matrix::trace`

`Matrix::trace(a)` returns `Ok(tr A)`, $\sum_i a_{ii}$, for a square matrix,
and `NonSquareMatrix` otherwise.

```mbti
pub fn[T : Add + @luna-generic.Zero] Matrix::trace(Self[T]) -> Result[T, @error.LinearAlgebraError]
```

The trace of the $0 \times 0$ matrix is `Zero::zero()`.

### `Matrix::unchecked_trace`

`Matrix::unchecked_trace(a)` returns $\operatorname{tr} A$ and aborts on a
non-square matrix.

```mbti
pub fn[T : Add + @luna-generic.Zero] Matrix::unchecked_trace(Self[T]) -> T
```

### `Matrix::determinant`

`Matrix::determinant(a)` returns `Ok(det A)` for a square matrix and
`NonSquareMatrix` otherwise.

```mbti
pub fn[T : DeterminantScalar] Matrix::determinant(Self[T]) -> Result[T, @error.LinearAlgebraError]
```

For the `Bareiss` strategy, $n \le 4$ evaluates closed cofactor formulas;
for $n \ge 5$ it runs
fraction-free (Bareiss) elimination, choosing as pivot the entry of largest
`abs` in the current column, whose divisions are exact in an integral domain.
The result is therefore **exact** for `BigInt`, and exact for `Int` and
`Int64` as long as no intermediate product overflows (for $n \le 4$, as long as
the determinant itself fits). If a whole pivot column is zero the result is
`Zero::zero()` at once. $\det$ of the $0 \times 0$ matrix is `One::one()`.
Cost $O(n^3)$ arithmetic operations. See the
[immut design](../design/immut.md) for the derivation.

For `PivotedLU` (`Float` and `Double`), every size uses Gaussian elimination
with partial pivoting on a private copy, then multiplies the pivots with the
row-swap sign. No tolerance is applied: an exactly zero pivot returns zero.
This is a determinant computation, not a numerical-rank test. Floating-point
rounding and elimination growth remain. Finite pivot products are accumulated
with a mantissa and binary exponent to avoid avoidable overflow or underflow;
final results still overflow or underflow when outside the scalar range. NaN
and infinity follow scalar arithmetic and are propagated. The $60 \times 60$ upper
bidiagonal matrix with diagonal $1000$ and superdiagonal $1$ now returns a
finite approximation to $10^{180}$ instead of Bareiss's NaN.

### `DeterminantAlgorithm`, `DeterminantScalar`

`DeterminantScalar` is an open strategy trait extending `Compare + Num + Div`.
Its `determinant_algorithm()` method selects `Bareiss` or `PivotedLU`.
`Int`, `Int16`, `Int64` and `BigInt` select `Bareiss`; `Float` and `Double`
select `PivotedLU` with scaled pivot accumulation. Custom scalars must
implement the trait explicitly; the default pivot product uses native scalar
multiplication.

```mbti
pub(all) enum DeterminantAlgorithm {
  Bareiss
  PivotedLU
}
pub(open) trait DeterminantScalar : Compare + @luna-generic.Num + Div {
  fn determinant_algorithm() -> DeterminantAlgorithm
  fn determinant_product(Array[Self]) -> Self = _
}
```

Choose `Bareiss` for a commutative integral domain with exact division of
divisible values, without intermediate overflow. Choose `PivotedLU` for
field-like division, accepting rounding for inexact scalars. These obligations
are not checked by the compiler. Generic callers must replace
`T : Compare + Num + Div` with `T : @immut.DeterminantScalar`.

### `Matrix::unchecked_determinant`

`Matrix::unchecked_determinant(a)` returns $\det A$ and aborts on a non-square
matrix.

```mbti
pub fn[T : DeterminantScalar] Matrix::unchecked_determinant(Self[T]) -> T
```

```moonbit check
///|
test "immut checked algebra" {
  let a = @immut.Matrix::from_2d_array([[1, 1], [1, 0]])
  inspect(a.pow(10).unwrap(), content="|89, 55|\n|55, 34|")
  inspect(a.trace().unwrap(), content="1")
  inspect(a.determinant().unwrap(), content="-1")
  let r = @immut.Matrix::from_2d_array([[1, 2, 3]])
  inspect(r.matmul(r) is Err(_), content="true")
  inspect(r.matmul(r.transpose()).unwrap(), content="|14|")
}

///|
test "exact determinant with BigInt" {
  let h = @immut.Matrix::make(6, 6, (i, j) => BigInt::from_int(i * i + j + 1))
  let v = @immut.Matrix::make(6, 6, (i, j) => {
    let mut p = 1N
    for _ in 0..<j {
      p = p * BigInt::from_int(i + 2)
    }
    p
  })
  inspect(h.determinant().unwrap(), content="0")
  inspect(v.determinant().unwrap(), content="34560")
}
```

The second matrix is a Vandermonde matrix with nodes $2, \dots, 7$, whose
determinant is $\prod_{i<j}(x_j - x_i) = 1!\,2!\,3!\,4!\,5! = 34560$.

## Structural operations

### `Matrix::transpose`

`Matrix::transpose(m)` returns the materialized transpose $A^{\mathsf T}$.

```mbti
pub fn[T] Matrix::transpose(Self[T]) -> Self[T]
```

### `Matrix::horizontal_combine`

`Matrix::horizontal_combine(a, b)` places `b` to the right of `a`: the block
matrix $[A \; B]$.

```mbti
pub fn[T] Matrix::horizontal_combine(Self[T], Self[T]) -> Self[T]
```

Different row counts abort.

### `Matrix::vertical_combine`

`Matrix::vertical_combine(a, b)` places `b` below `a`.

```mbti
pub fn[T] Matrix::vertical_combine(Self[T], Self[T]) -> Self[T]
```

Different column counts abort.

### `Matrix::swap_rows`, `Matrix::swap_cols`

`swap_rows(i, j)` and `swap_cols(i, j)` return a matrix with two rows or two
columns exchanged.

```mbti
pub fn[T] Matrix::swap_rows(Self[T], Int, Int) -> Self[T]
pub fn[T] Matrix::swap_cols(Self[T], Int, Int) -> Self[T]
```

Out-of-range indices abort. Swapping an index with itself returns `m` itself.
Otherwise the whole matrix is rebuilt, $O(rc)$.

```moonbit check
///|
test "immut structural operations" {
  let a = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let b = @immut.Matrix::from_2d_array([[5], [6]])
  inspect(a.horizontal_combine(b), content="|1, 2, 5|\n|3, 4, 6|")
  inspect(
    a.vertical_combine(a.swap_rows(0, 1)),
    content="|1, 2|\n|3, 4|\n|3, 4|\n|1, 2|",
  )
  inspect(a.transpose().swap_cols(0, 1), content="|3, 1|\n|4, 2|")
}
```

## Iteration and conversion

### `Matrix::iter`

`Matrix::iter(m)` iterates over all entries in row-major order.

```mbti
pub fn[T] Matrix::iter(Self[T]) -> Iter[T]
```

### `Matrix::iter_row`, `Matrix::iter_col`

`iter_row(r)` iterates over row `r` left to right; `iter_col(c)` over column
`c` top to bottom.

```mbti
pub fn[T] Matrix::iter_row(Self[T], Int) -> Iter[T]
pub fn[T] Matrix::iter_col(Self[T], Int) -> Iter[T]
```

Out-of-range indices abort when the iterator is created.

### `Matrix::to_array`

`Matrix::to_array(m)` copies the entries into a flat row-major array.

```mbti
pub fn[T] Matrix::to_array(Self[T]) -> Array[T]
```

### `Matrix::to_2d_array`

`Matrix::to_2d_array(m)` copies the entries into nested row arrays.

```mbti
pub fn[T] Matrix::to_2d_array(Self[T]) -> Array[Array[T]]
```

For an $r \times 0$ matrix the result has $r$ empty rows.

```moonbit check
///|
test "immut iteration" {
  let m = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  debug_inspect(m.iter_col(1).to_array(), content="[2, 4]")
  debug_inspect(m.iter().fold(init=0, (s, x) => s + x), content="10")
  debug_inspect(m.to_2d_array(), content="[[1, 2], [3, 4]]")
}
```

## `MatrixFn` operations

All `MatrixFn` operations are lazy: they compose functions and do no work until
an entry is read. Shape checks happen eagerly; bounds checks happen on reads.

### `MatrixFn::make`

`MatrixFn::make(r, c, f)` builds the lazy matrix with entries $f(i, j)$.

```mbti
pub fn[T] MatrixFn::make(Int, Int, (Int, Int) -> T) -> Self[T]
```

Negative dimensions abort. Reading an entry outside the shape aborts.

### `MatrixFn::new`

`MatrixFn::new(r, c)` builds an $r \times c$ lazy matrix whose entries are
`T::default()`.

```mbti
pub fn[T : Default] MatrixFn::new(Int, Int) -> Self[T]
```

### `MatrixFn::from_2d_array`

`MatrixFn::from_2d_array(rows)` builds a lazy view of nested rows.

```mbti
pub fn[T] MatrixFn::from_2d_array(Array[Array[T]]) -> Self[T]
```

Ragged input aborts. The arrays are captured, not copied: later writes to them
are visible through the `MatrixFn`.

### `MatrixFn::identity`

`MatrixFn::identity(n)` is the lazy $n \times n$ identity.

```mbti
pub fn[T : @luna-generic.One + @luna-generic.Zero] MatrixFn::identity(Int) -> Self[T]
```

### `MatrixFn::shape`

`MatrixFn::shape(m)` returns `(rows, cols)`.

```mbti
pub fn[T] MatrixFn::shape(Self[T]) -> (Int, Int)
```

### `MatrixFn::at`

`MatrixFn::at(m, r)` returns the row accessor behind `m[r][c]`.

```mbti
#alias("_[_]")
pub fn[T] MatrixFn::at(Self[T], Int) -> Indexed[T]
```

The row index is checked immediately, the column when it is read.

### `MatrixFn::map`

`MatrixFn::map(m, f)` composes `f` after every entry.

```mbti
pub fn[T, U] MatrixFn::map(Self[T], (T) -> U) -> Self[U]
```

### `MatrixFn::map_row`, `MatrixFn::map_col`

`map_row(r, f)` and `map_col(c, f)` apply `f` to one row or one column.

```mbti
pub fn[T] MatrixFn::map_row(Self[T], Int, (T) -> T) -> Self[T]
pub fn[T] MatrixFn::map_col(Self[T], Int, (T) -> T) -> Self[T]
```

Out-of-range indices abort immediately.

### `MatrixFn::zip_with`

`MatrixFn::zip_with(a, b, f)` combines two lazy matrices entry by entry.

```mbti
pub fn[T, U, W] MatrixFn::zip_with(Self[T], Self[U], (T, U) -> W) -> Self[W]
```

Different shapes abort.

### `MatrixFn::fold`

`MatrixFn::fold(m, init~, f)` reduces all entries in row-major order.

```mbti
pub fn[T, U] MatrixFn::fold(Self[T], init~ : U, (U, T) -> U) -> U
```

This forces every entry once.

### `MatrixFn::add`, `MatrixFn::sub`, `MatrixFn::neg`, `MatrixFn::scale`

Lazy entry-wise $A + B$, $A - B$, $-A$ and $A a$.

```mbti
pub fn[T : Add] MatrixFn::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Add + Neg] MatrixFn::sub(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] MatrixFn::neg(Self[T]) -> Self[T]
pub fn[T : Mul] MatrixFn::scale(Self[T], T) -> Self[T]
```

`MatrixFn` has no public `*` operator; use `pow` or convert to `Matrix`.

### `MatrixFn::pow`

`MatrixFn::pow(a, k)` returns the lazy power $A^k$ by binary exponentiation.

```mbti
pub fn[T : @luna-generic.Semiring] MatrixFn::pow(Self[T], Int) -> Self[T]
```

Non-square input or a negative exponent aborts. Because nothing is cached,
reading one entry of $A^{k}$ recomputes the nested products. One entry of the
lazy square $B \cdot B$ reads $2n$ entries of $B$, so one entry of $A^{2^d}$
reads $(2n)^d = k^{1 + \log_2 n}$ entries of $A$ for $k = 2^d$; read all entries
into a `Matrix` with `Matrix::make` if you need more than a few.

### `MatrixFn::determinant`

`MatrixFn::determinant(a)` materializes the matrix and returns its determinant
with the algorithm of `Matrix::determinant`.

```mbti
pub fn[T : DeterminantScalar] MatrixFn::determinant(Self[T]) -> T
```

A non-square matrix aborts; there is no checked form.

### `MatrixFn::transpose`, `MatrixFn::adjoint`

Lazy transpose and conjugate transpose.

```mbti
pub fn[T] MatrixFn::transpose(Self[T]) -> Self[T]
pub fn[T : @luna-generic.Conjugate] MatrixFn::adjoint(Self[T]) -> Self[T]
```

### `MatrixFn::swap_rows`, `MatrixFn::swap_cols`

Lazy row and column exchange; out-of-range indices abort.

```mbti
pub fn[T] MatrixFn::swap_rows(Self[T], Int, Int) -> Self[T]
pub fn[T] MatrixFn::swap_cols(Self[T], Int, Int) -> Self[T]
```

### `MatrixFn::horizontal_combine`, `MatrixFn::vertical_combine`

Lazy block concatenation; mismatched row or column counts abort.

```mbti
pub fn[T] MatrixFn::horizontal_combine(Self[T], Self[T]) -> Self[T]
pub fn[T] MatrixFn::vertical_combine(Self[T], Self[T]) -> Self[T]
```

### `MatrixFn::equal`, `MatrixFn::to_string`

`equal` compares shapes and every entry (forcing them); `to_string` renders
like `Matrix`.

```mbti
pub fn[T : Eq] MatrixFn::equal(Self[T], Self[T]) -> Bool
pub fn[T : Show] MatrixFn::to_string(Self[T]) -> String
```

```moonbit check
///|
test "lazy matrices" {
  let hilbert_denominators = @immut.MatrixFn::make(3, 3, (i, j) => i + j + 1)
  inspect(hilbert_denominators, content="|1, 2, 3|\n|2, 3, 4|\n|3, 4, 5|")
  let fib = @immut.MatrixFn::from_2d_array([[1, 1], [1, 0]]).pow(20)
  inspect(fib[0][1], content="6765")
  let total = hilbert_denominators.fold(init=0, (s, x) => s + x)
  inspect(total, content="27")
  inspect(
    hilbert_denominators.transpose() == hilbert_denominators,
    content="true",
  )
}
```

## Vector

### `Vector::from_array`

`Vector::from_array(xs)` copies an array into a new vector.

```mbti
pub fn[T] Vector::from_array(Array[T]) -> Self[T]
```

### `Vector::make`, `Vector::makei`

`make(n, x)` builds $n$ copies of `x`; `makei(n, f)` builds
$(f(0), \dots, f(n-1))$.

```mbti
pub fn[T] Vector::make(Int, T) -> Self[T]
pub fn[T] Vector::makei(Int, (Int) -> T) -> Self[T]
```

### `Vector::length`

`Vector::length(v)` returns the number of elements.

```mbti
pub fn[T] Vector::length(Self[T]) -> Int
```

### `Vector::at`

`Vector::at(v, i)` returns element `i`; it backs `v[i]`. An out-of-range index
aborts.

```mbti
#alias("_[_]")
pub fn[T] Vector::at(Self[T], Int) -> T
```

### `Vector::set`

`Vector::set(v, i, x)` returns a vector equal to `v` except at `i`, in
$O(\log_{32} n)$; `v` is unchanged.

```mbti
pub fn[T] Vector::set(Self[T], Int, T) -> Self[T]
```

### `Vector::iter`

`Vector::iter(v)` iterates over the elements in order.

```mbti
pub fn[T] Vector::iter(Self[T]) -> Iter[T]
```

### `Vector::map`, `Vector::zip_with`

`map(f)` applies `f` to every element; `zip_with(w, f)` combines two vectors
element by element and aborts on different lengths.

```mbti
pub fn[T, U] Vector::map(Self[T], (T) -> U) -> Self[U]
pub fn[T, U, V] Vector::zip_with(Self[T], Self[U], (T, U) -> V) -> Self[V]
```

### `Vector::add`, `Vector::mul`, `Vector::neg`

Element-wise $u + v$, Hadamard $u \odot v$ and $-u$; they back the operators.
Different lengths abort.

```mbti
pub fn[T : Add] Vector::add(Self[T], Self[T]) -> Self[T]
pub fn[T : Mul] Vector::mul(Self[T], Self[T]) -> Self[T]
pub fn[T : Neg] Vector::neg(Self[T]) -> Self[T]
```

`Vector` has no `Sub` implementation; write `u + -v`.

### `Vector::add_constant`

`Vector::add_constant(v, a)` adds `a` to every element.

```mbti
pub fn[T : Add] Vector::add_constant(Self[T], T) -> Self[T]
```

### `Vector::left_scale`, `Vector::right_scale`

`left_scale(a)` returns $(a v_i)_i$; `right_scale(a)` returns $(v_i a)_i$. They
differ only for non-commutative scalars.

```mbti
pub fn[T : Mul] Vector::left_scale(Self[T], T) -> Self[T]
pub fn[T : Mul] Vector::right_scale(Self[T], T) -> Self[T]
```

### `Vector::lerp`

`Vector::lerp(u, v, t)` returns $(1 - t) u + t v$, with scalars on the left.

```mbti
pub fn[T : @luna-generic.One + Mul + Add + Neg] Vector::lerp(Self[T], Self[T], T) -> Self[T]
```

Different lengths abort.

### `lin_comb`

`lin_comb(a, u, b, v)` returns $a u + b v$, with scalars on the left.

```mbti
pub fn[T : Add + Mul] lin_comb(T, Vector[T], T, Vector[T]) -> Vector[T]
```

### `Vector::to_row_matrix`, `Vector::to_col_matrix`

The vector as a $1 \times n$ or an $n \times 1$ matrix.

```mbti
pub fn[T] Vector::to_row_matrix(Self[T]) -> Matrix[T]
pub fn[T] Vector::to_col_matrix(Self[T]) -> Matrix[T]
```

### `Vector::scaled_matrix`

`Vector::scaled_matrix(v)` returns the diagonal matrix
$\operatorname{diag}(v_0, \dots, v_{n-1})$.

```mbti
pub fn[T : @luna-generic.Zero] Vector::scaled_matrix(Self[T]) -> Matrix[T]
```

### `Vector::tensor_product`

`Vector::tensor_product(u, v)` returns the outer product $u v^{\mathsf T}$,
the $m \times n$ matrix with entries $u_i v_j$.

```mbti
pub fn[T : Mul] Vector::tensor_product(Self[T], Self[T]) -> Matrix[T]
```

### `Vector::equal`, `Vector::to_string`

`equal` compares lengths and elements; `to_string` renders `|a, b, c|`.

```mbti
pub fn[T : Eq] Vector::equal(Self[T], Self[T]) -> Bool
pub fn[T : Show] Vector::to_string(Self[T]) -> String
```

```moonbit check
///|
test "immut vectors" {
  let u = @immut.Vector::from_array([1, 2, 3])
  let v = @immut.Vector::makei(3, i => 10 * i)
  inspect(u + v, content="|1, 12, 23|")
  inspect(u * v, content="|0, 20, 60|")
  inspect(@immut.lin_comb(2, u, -1, v), content="|2, -6, -14|")
  inspect(u.set(0, 100), content="|100, 2, 3|")
  inspect(u, content="|1, 2, 3|")
  inspect(
    u.tensor_product(@immut.Vector::from_array([1, -1])),
    content="|1, -1|\n|2, -2|\n|3, -3|",
  )
  inspect(u.scaled_matrix(), content="|1, 0, 0|\n|0, 2, 0|\n|0, 0, 3|")
  inspect(u.lerp(@immut.Vector::make(3, 5), 2), content="|9, 8, 7|")
}
```

## Deprecated

These method forms exist only for source compatibility; they are hidden from
the interface and warn when used.

| Item | Replacement |
| --- | --- |
| `Matrix::not_equal`, `MatrixFn::not_equal`, `Vector::not_equal` | `!=` |
| `Matrix::output`, `MatrixFn::output`, `Vector::output` | string interpolation or `Show::output(x, logger)` |
| `Vector::to_repr` | `Repr(v)` or `@debug.Debug::to_repr(v)` |
| `Vector::arbitrary` | `@quickcheck.Arbitrary::arbitrary` |
