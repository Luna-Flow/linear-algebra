# immut tutorial

This tutorial shows how to work with immutable matrices and vectors: build
them, update them without losing earlier versions, compute exact integer
results such as powers and determinants, and use lazy matrices for structured
data. The reasoning behind the package is in the [immut design](../design/immut.md).

| I want to | Use |
| --- | --- |
| build a matrix | `@immut.Matrix::from_2d_array`, `make`, `identity` |
| change one entry and keep the old matrix | `Matrix::set` |
| multiply with a shape check | `Matrix::matmul` |
| compute an exact power or determinant | `Matrix::pow`, `Matrix::determinant` over `Int` or `BigInt` |
| build matrices from vectors | `Vector::to_row_matrix`, `tensor_product`, `scaled_matrix` |
| describe a structured matrix without storing it | `@immut.MatrixFn::make` |

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/immut",
}
```

```moonbit check
///|
test "first immutable matrix" {
  let a = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let b = a.set(0, 0, 10)
  inspect(a, content="|1, 2|\n|3, 4|")
  inspect(b, content="|10, 2|\n|3, 4|")
  inspect(a * b, content="|16, 10|\n|42, 22|")
}
```

`set` returns a new matrix; `a` keeps its value.

## Everyday tasks

### Keep a history of edits

Because every update returns a new value, a history is just an array of
matrices that share most of their storage:

```moonbit check
///|
test "undo by keeping old versions" {
  let history = [@immut.Matrix::new(2, 2, 0)]
  for step in 0..<3 {
    let current = history[history.length() - 1]
    history.push(current.set(step % 2, step / 2, step + 1))
  }
  inspect(history[3], content="|1, 3|\n|2, 0|")
  inspect(history[1], content="|1, 0|\n|0, 0|")
}
```

### Count paths with a matrix power

Entry $(i, j)$ of $A^k$ counts the walks of length $k$ from $i$ to $j$ in the
graph with adjacency matrix $A$. Integer powers are exact:

```moonbit check
///|
test "walks in a triangle graph" {
  let triangle = @immut.Matrix::from_2d_array([[0, 1, 1], [1, 0, 1], [1, 1, 0]])
  let walks = triangle.pow(4).unwrap()
  inspect(walks[0][0], content="6")
  inspect(walks[0][1], content="5")
  match triangle.pow(-1) {
    Err(e) => inspect(e.is_negative_exponent(), content="true")
    Ok(_) => fail("negative powers are rejected")
  }
}
```

### Exact determinants

`determinant` uses fraction-free elimination, so integer matrices get exact
results, and `BigInt` matrices are exact at any size. Scaling every entry by
$10^{12}$ scales the $5 \times 5$ determinant by $10^{60}$:

```moonbit check
///|
test "exact determinant of an integer matrix" {
  let m = @immut.Matrix::from_2d_array([
    [2, 0, 1, 3, 1],
    [1, 3, 2, 0, 4],
    [0, 1, 4, 1, 2],
    [3, 2, 0, 5, 1],
    [1, 0, 2, 1, 3],
  ])
  inspect(m.determinant().unwrap(), content="62")
  let big = m.map(x => BigInt::from_int(x) * 1000000000000N)
  inspect(
    big.determinant().unwrap(),
    content="62000000000000000000000000000000000000000000000000000000000000",
  )
}
```

### Build matrices from vectors

```moonbit check
///|
test "outer products and diagonals" {
  let u = @immut.Vector::from_array([1, 2, 3])
  let ones = @immut.Vector::make(3, 1)
  let rank_one = u.tensor_product(ones)
  inspect(rank_one, content="|1, 1, 1|\n|2, 2, 2|\n|3, 3, 3|")
  let d = u.scaled_matrix()
  inspect(d * rank_one, content="|1, 1, 1|\n|4, 4, 4|\n|9, 9, 9|")
  inspect(u.to_row_matrix() * u.to_col_matrix(), content="|14|")
}
```

### Describe a structured matrix lazily

A `MatrixFn` stores a rule instead of entries. It is a good fit for matrices
defined by a formula, such as a band matrix, when you read only part of them:

```moonbit check
///|
test "a lazy tridiagonal matrix" {
  let n = 1000
  let band = @immut.MatrixFn::make(n, n, (i, j) => {
    if i == j {
      2
    } else if i - j == 1 || j - i == 1 {
      -1
    } else {
      0
    }
  })
  inspect(band[500][499], content="-1")
  inspect(band[500][700], content="0")
  let small = @immut.MatrixFn::make(3, 3, (i, j) => band[i][j])
  inspect(small, content="|2, -1, 0|\n|-1, 2, -1|\n|0, -1, 2|")
  inspect(small.determinant(), content="4")
}
```

No $1000 \times 1000$ array is ever allocated.

## Going further

**Generic code.** The concrete type does not implement the `algebra` traits.
Wrap it in `@default.ImmutableDenseMatrix` to pass it to functions bounded by
`MatMulMatrix` (see the [backends/default tutorial](backends/default.md)).

**Converting to `mutable`.** For numerical work such as inverses,
decompositions or statistics, convert with the
[`container` adapters](container/adapters.md) and use [`mutable`](mutable.md).

**Your own scalar type.** Determinants require `DeterminantScalar` in addition
to its inherited `Compare + Num + Div` operations. Select `Bareiss` for an
integral domain with exact division on divisible values, or `PivotedLU` for
field-like division. A modular ring with zero divisors is not an integral
domain. Generic determinant callers must add `T : @immut.DeterminantScalar`;
any `Semiring` still gets `pow`.

**Performance.** Reads and single-entry updates cost $O(\log_{32} N)$. For a
long series of edits on a large matrix, a `@mutable.Matrix` working buffer is
faster; freeze it into an `immut` value at the end.

## Common pitfalls

- **Integer overflow.** `Int` arithmetic wraps. `pow` is then exact modulo
  $2^{32}$, which is rarely what you want; use `Int64` or `BigInt` for large
  values.
- **Assigning through indexing.** `m[r][c] = x` does not exist here; use
  `m.set(r, c, x)` and keep the result.
- **Subtracting vectors.** `Vector` has no `-` operator; write `u + -v`.
- **Reading lazy powers.** Every read of a `MatrixFn` power recomputes the
  nested products. Materialize first with `Matrix::make(r, c, (i, j) => f[i][j])`
  if you read many entries.
- **Operators abort.** `+`, `-`, `*` abort on shape mismatch; use `matmul`
  when shapes come from input.
- **Floating-point determinants.** `Float` and `Double` use pivoted LU for
  every size. No tolerance is used to classify a pivot as zero, so this is
  not a numerical-rank test. Rounding, overflow and underflow remain possible;
  use an error budget appropriate to the matrix instead of exact equality.

## Next steps

- [immut API](../api/immut.md) for every method and its cost.
- [immut design](../design/immut.md) for value semantics and the Bareiss
  derivation.
- [mutable tutorial](mutable.md) for in-place numerical work.
- [container tutorial](container.md) for moving data between representations.
