# arithmetic Tutorial

## Project Setup

Install the shared abstraction packages first:

```sh
moon add Luna-Flow/linear-algebra@0.4.4
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

Recommended `moon.pkg` imports:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

## Small Case: Turn A Signed Residual Into A Penalty Signal

```moonbit check
///|
fn[T : @la_arithmetic.Abs] residual_penalty(value : T) -> T {
  @la_arithmetic.Abs::abs(value)
}

///|
test "Abs-based penalty helper compiles for Int" {
  inspect(residual_penalty(-3), content="3")
}
```

This case is small, but it captures the role of the `arithmetic` layer:

1. Start from a raw scalar value produced by a linear-algebra routine.
2. Ask only for the concrete operation you need, here `Abs`.
3. Convert the signed residual into a penalty value without claiming a richer algebraic structure.

That is the right fit when the algorithm needs a computable helper, not a full
mathematical contract.

## Suggested Flow

1. Use `arithmetic` when the algorithm needs an operation such as `abs`, checked division, checked square root, or approximate comparison.
2. Keep the requirement as narrow as possible so more scalar types can satisfy it.
3. Move up to `algebra` only when the algorithm depends on a stronger structural meaning.

## Practical Guidance

- Prefer existing `Luna-Flow/luna-generic` or `Luna-Flow/arithmetic` traits when they already express the operation.
- Add local linear-algebra-facing traits only when an upstream capability name is missing.
- Do not use an arithmetic-only trait as a substitute for a stronger algebraic guarantee.
