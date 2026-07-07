# algebra Tutorial

単一操作ではなく意味論的な構造が必要な汎用コードでは `linear-algebra/algebra` を使います。

```moonbit
fn[T : Semiring](value : T) -> T {
  value + T::zero()
}
```

近似的な浮動小数点スカラーを前提にする場合は `FloatingScalarOps` を使います。厳密な体の法則を主張する trait として扱わないでください。
