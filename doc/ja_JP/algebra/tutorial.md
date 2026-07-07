# algebra Tutorial

単一操作ではなく意味論的な構造が必要な汎用コードでは `linear-algebra/algebra` を使います。

```moonbit
fn[T : Semiring](value : T) -> T {
  value + T::zero()
}
```

近似 floating scalar バックエンド が意図される場合は `FloatingScalarOps` を使います。exact field law の主張としては扱わないでください。
