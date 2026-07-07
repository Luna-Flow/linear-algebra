# arithmetic Tutorial

Use `linear-algebra/arithmetic` when generic linear-algebra code needs a
computable scalar operation without claiming a full algebraic structure.

```moonbit
fn[T : Abs](value : T) -> T {
  Abs::abs(value)
}
```

Prefer existing `Luna-Flow/luna-generic` or `Luna-Flow/arithmetic` traits when
they already express the operation. Add local traits only for linear-algebra
integration names that are missing upstream.
