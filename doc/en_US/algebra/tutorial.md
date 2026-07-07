# algebra Tutorial

Use `linear-algebra/algebra` when generic code needs semantic structure rather
than a single operation.

```moonbit
fn[T : Semiring](value : T) -> T {
  value + T::zero()
}
```

Use `FloatingScalarOps` for floating scalar backends when approximate behavior
is intended. Do not use it as a claim of exact field laws.
