# mutable tutorial

This tutorial shows how to use `@mutable.Matrix` and `@mutable.Vector` as
working buffers: build and edit them in place, work through row, column and
transpose views, and run the numerical routines (inverse, determinant,
Cholesky, eigenvalues, statistics) with proper error handling. The algorithms
and their accuracy are explained in the [mutable design](../design/mutable.md).

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/mutable",
}
```

```moonbit check
///|
test "first mutable matrix" {
  let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  m.set(0, 1, 9.0)
  inspect(m, content="|1, 9|\n|3, 4|")
  inspect(m.determinant().unwrap(), content="-23")
}
```

`set` changes `m` in place; `determinant` returns a `Result` because it is
only defined for square matrices.

## Everyday tasks

### Edit rows and columns through views

```moonbit check
///|
test "normalize each row to sum one" {
  let m = @mutable.Matrix::from_2d_array([[1.0, 3.0], [2.0, 2.0], [0.0, 5.0]])
  for i in 0..<m.row() {
    let row = m.row_view(i)
    let mut sum = 0.0
    row.each(x => sum = sum + x)
    row.map_inplace(x => x / sum)
  }
  inspect(m, content="|0.25, 0.75|\n|0.5, 0.5|\n|0, 1|")
  let first_col = m.col_view(0)
  first_col[2] = 1.0
  inspect(m.get(2, 0), content="1")
}
```

### Solve a small linear system

There is no public solver for a right-hand side; for small systems multiply
by the inverse, and handle the singular case:

```moonbit check
///|
fn mut_tut_solve(
  a : @mutable.Matrix[Double],
  b : @mutable.Vector[Double],
) -> Result[@mutable.Vector[Double], @la_error.LinearAlgebraError] {
  let inv = match a.inverse() {
    Ok(inv) => inv
    Err(e) => return Err(e)
  }
  inv.mul_vec(b)
}

///|
test "solve 2x + y = 5, x + 3y = 10" {
  let a = @mutable.Matrix::from_2d_array([[2.0, 1.0], [1.0, 3.0]])
  let x = mut_tut_solve(a, @mutable.Vector::from_array([5.0, 10.0])).unwrap()
  inspect((x[0] - 1.0).abs() < 1.0e-12, content="true")
  inspect((x[1] - 3.0).abs() < 1.0e-12, content="true")
  let singular = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])
  match mut_tut_solve(singular, @mutable.Vector::from_array([1.0, 2.0])) {
    Err(e) => inspect(e.is_singular_matrix(), content="true")
    Ok(_) => fail("singular systems have no unique solution")
  }
}
```

Compare floating-point results with a tolerance, as above, rather than with
`==`.

### Check positive definiteness and factor

```moonbit check
///|
test "covariance-like matrix" {
  let c = @mutable.Matrix::from_2d_array([
    [4.0, 2.0, 0.0],
    [2.0, 5.0, 1.0],
    [0.0, 1.0, 3.0],
  ])
  inspect(c.is_symmetric(), content="true")
  match c.cholesky_decomposition() {
    Some(l) => {
      let back = l * l.transpose()
      let mut err = 0.0
      back.each_row_col((i, j, x) => err = err + (x - c.get(i, j)).abs())
      inspect(err < 1.0e-12, content="true")
    }
    None => fail("c is positive definite")
  }
  let indefinite = @mutable.Matrix::from_2d_array([[1.0, 2.0], [2.0, 1.0]])
  inspect(indefinite.cholesky_decomposition() is None, content="true")
}
```

### Eigenvalues of a symmetric matrix

```moonbit check
///|
test "vibration modes of a three-mass chain" {
  let k = @mutable.Matrix::from_2d_array([
    [2.0, -1.0, 0.0],
    [-1.0, 2.0, -1.0],
    [0.0, -1.0, 2.0],
  ])
  let (values, vectors) = k.eigen()
  let sorted = values.iter().to_array()
  sorted.sort()
  let expected = [2.0 - 1.4142135623730951, 2.0, 2.0 + 1.4142135623730951]
  for i in 0..<3 {
    inspect((sorted[i] - expected[i]).abs() < 1.0e-12, content="true")
  }
  let check = vectors.transpose() * vectors
  inspect((check.get(0, 0) - 1.0).abs() < 1.0e-12, content="true")
  inspect(check.get(0, 1).abs() < 1.0e-12, content="true")
}
```

The eigenvalues come back unsorted; sort them yourself when order matters.

### Summary statistics

```moonbit check
///|
test "statistics of a measurement grid" {
  let grid = @mutable.Matrix::from_2d_array([
    [2.0, 4.0],
    [4.0, 4.0],
    [5.0, 5.0],
    [7.0, 9.0],
  ])
  inspect(grid.mean().unwrap(), content="5")
  inspect(grid.std_dev().unwrap(), content="2")
  inspect(grid.min_element().unwrap(), content="2")
  let empty : @mutable.Matrix[Double] = @mutable.Matrix::new(0, 2, 0.0)
  inspect(empty.mean() is Err(_), content="true")
}
```

## Going further

**Avoiding copies.** `Matrix::from_array` and `Vector::from_array` adopt the
array you pass. This is fast but means the array and the matrix change
together; call `copy()` when you need independence.

**Transpose without copying.** `to_transpose()` is an $O(1)$ view; products
of two views reuse the matrix kernel. Use `transpose()` or `materialize()`
when you need an independent matrix.

**Unchecked forms in hot loops.** After you have established the
preconditions (for example square matrices built by your own code), the
`unchecked_*` methods skip validation. Never use `unchecked_matmul` on shapes
you have not checked: it does not validate and may return a wrong result.

**Scaling.** The routines decide "zero" with an absolute threshold of
$10^{-11}$. Scale your data to order one first; otherwise tiny but regular
matrices are reported singular. See the
[design page](../design/mutable.md#tolerance-based-decisions).

**Generic code.** Wrap the matrix in `@default.DenseMatrix` to pass it to
functions bounded by the `algebra` traits; `inner()` gets it back.

## Common pitfalls

- **Forgetting that `reduce_row_elimination` mutates.** It transforms the
  receiver in place and returns it. Call `copy()` first.
- **Expecting normalized $2 \times 2$ eigenvectors.** For $2 \times 2$ input,
  the eigenvector columns are not normalized; larger inputs return orthonormal
  columns.
- **Numerical routines on integers.** `determinant`, `inverse`, `rank`, `eigen`
  and friends need `Tolerance`, which exists only for `Float` and `Double`. For
  exact integer determinants use `@immut.Matrix::determinant`.
- **`Float` precision.** The tolerance is far below `Float` precision; nearly
  singular `Float` matrices are not detected. Prefer `Double`.
- **Power method on symmetric spectra.** Eigenvalues $\pm\lambda$ of equal
  magnitude prevent convergence; `power_method` then returns `None`.

## Next steps

- [mutable API](../api/mutable.md) for every method, its errors and cost.
- [mutable design](../design/mutable.md) for LU, Cholesky, QL and their error
  bounds.
- [error tutorial](error.md) for handling checked results.
- [immut tutorial](immut.md) for exact, value-oriented work.
