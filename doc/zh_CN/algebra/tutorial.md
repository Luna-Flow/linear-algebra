# algebra 教程

当泛型代码需要语义结构，而不是单个操作时，使用 `linear-algebra/algebra`。

```moonbit
fn[T : Semiring](value : T) -> T {
  value + T::zero()
}
```

当确实需要浮点近似语义时使用 `FloatingScalarOps`，不要把它当作精确域公理。
