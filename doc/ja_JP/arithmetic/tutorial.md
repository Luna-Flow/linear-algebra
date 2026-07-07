# arithmetic Tutorial

汎用線形代数コードが完全な代数構造ではなく計算可能なスカラー操作だけを必要とする場合、`linear-algebra/arithmetic` を使います。

```moonbit
fn[T : Abs](value : T) -> T {
  Abs::abs(value)
}
```

対応する trait が `Luna-Flow/luna-generic` または `Luna-Flow/arithmetic` に既にある場合は、そちらを優先して再利用してください。
