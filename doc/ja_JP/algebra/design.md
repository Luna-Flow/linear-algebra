# algebra Design

## 責務

- 線形代数で使う意味論的な数学構造を表します。
- structure-level trait と operation-only arithmetic trait を分離します。
- 近似 floating-point 振る舞いを exact な代数法則として扱いません。
- `AdditiveVector` / `TransposeMatrix` で object 形状 と閉じた演算を直接表します。
- carrier type が lawful global identity を提供できる場合は、`AddGroup`、`Semiring`、`Ring` など upstream の law-bearing trait を組み合わせてより強い代数構造を表します。

## 非責務

- 密 バックエンド 型を import しません。
- storage、mutation、algorithm execution trait は定義しません。
- inner product、norm などの scalar-valued functor を中核構造層に置きません。
- 明示的な scalar action model なしに `Module` や `VectorSpace` を追加しません。
- パッケージ-local な 形状-dependent zero を upstream `Zero` の代わりに導入しません。
