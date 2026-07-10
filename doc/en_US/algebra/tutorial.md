# algebra Tutorial

## Project Setup

If you want to use the abstract linear-algebra layers directly, install the
full dependency set first:

```sh
moon add Luna-Flow/linear-algebra@0.4.7
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

This gives you one clear split: `@algebra` for linear-algebra structure traits,
`@la_arithmetic` for linear-algebra-facing operation traits, `@lf_alg` for the
shared upstream algebraic abstractions, and `@lf_arith` for upstream arithmetic
types.

## Small Case: Build One Backend-Independent Gram Step

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] gram_step(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "algebra tutorial uses linear-algebra traits with a real backend" {
  let features : @default.ImmutableDenseMatrix[Int] = @default.ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  let gram = gram_step(features)
  let (rows, cols) = @algebra.MatrixShape::shape(gram)

  inspect(rows, content="2")
  inspect(cols, content="2")
  inspect(gram.inner(), content="|10, 14|\n|14, 20|")
}
```

This case shows how to describe a backend-independent linear-algebra step in
terms of the structure traits owned by this package:

1. Require `MatMulMatrix` so the algorithm can multiply one matrix-like value by another.
2. Reuse `TransposeMatrix` through the `MatMulMatrix` hierarchy instead of naming a dense backend API directly.
3. Ask `MatrixShape` for the result shape without depending on storage layout.
4. Run the same helper on a real default backend wrapper to confirm the trait contract is practical, not just abstract.

The result stays generic while still expressing a recognizably linear-algebraic
operation.

## Suggested Flow

1. Reach for `algebra` when the mathematical meaning matters more than one backend helper.
2. Use traits such as `AdditiveVector`, `MatrixShape`, `TransposeMatrix`, and `MatMulMatrix` to state the required structure.
3. Add narrower arithmetic-only constraints only when the algorithm truly needs a specific computable operation.

## Practical Guidance

- Prefer the smallest structure that still matches the algorithm's mathematical meaning.
- Keep backend-specific products, norms, or solve routines out of the core structure layer unless they can be expressed generically.
