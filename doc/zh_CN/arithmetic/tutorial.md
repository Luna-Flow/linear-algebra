# arithmetic 教程

当泛型线性代数代码只需要某个可计算标量操作，而不需要完整代数结构时，使用 `linear-algebra/arithmetic`。

```moonbit
fn[T : Abs](value : T) -> T {
  Abs::abs(value)
}
```

如果上游 `Luna-Flow/luna-generic` 或 `Luna-Flow/arithmetic` 已经有对应 trait，优先复用上游 trait。
