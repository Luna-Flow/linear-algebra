# `linear-algebra/arithmetic`

このページは現在の `0.4.0` リポジトリにおける
`Luna-Flow/linear-algebra/arithmetic` の公開 API を説明します。

## 役割

`arithmetic` は線形代数パッケージで使う操作レベルの trait を提供します。ここでの trait は「その操作が利用できる」ことだけを表し、代数法則は主張しません。法則を持つ構造は `linear-algebra/algebra` に属します。

## 再公開される型

`Luna-Flow/arithmetic` から:

- `ArithmeticContext`
- `ArithmeticError`
- `ArithmeticErrorKind`
- `FpClass`
- `RoundingMode`

これらは上流パッケージでの意味を保ち、検査付き演算で使います。

## 再公開される操作 trait

`Luna-Flow/luna-generic` から:

- `Zero`
- `One`
- `Inverse`
- `Conjugate`

`Luna-Flow/arithmetic` から:

- `Sqrt`
- `Cbrt`
- `Power`
- `Constants`
- `Exponential`
- `Logarithmic`
- `SqrtChecked`
- `DivChecked`
- `CompareChecked`

## `Abs`

```moonbit
pub(open) trait Abs {
  fn abs(Self) -> Self
}
```

絶対値操作です。実装対象:

- `Int`
- `Float`
- `Double`

## `ApproxEq`

```moonbit
pub(open) trait ApproxEq {
  fn approx_eq(Self, Self) -> Bool
}
```

近似等価を判定する操作です。これは操作能力であり、同値関係の法則を主張するものではありません。実装対象:

- `Int`
- `Float`
- `Double`

## `CheckedDiv`

```moonbit
pub(open) trait CheckedDiv {
  fn checked_div(Self, Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

`ArithmeticContext` を使う検査付き除算です。`Float` と `Double` に実装されています。

## `CheckedSqrt`

```moonbit
pub(open) trait CheckedSqrt {
  fn checked_sqrt(Self, ArithmeticContext) -> Result[Self, ArithmeticError]
}
```

`ArithmeticContext` を使う検査付き平方根です。`Float` と `Double` に実装されています。

## `CheckedCompare`

```moonbit
pub(open) trait CheckedCompare {
  fn checked_compare(Self, Self) -> Result[Int, ArithmeticError]
}
```

検査付きスカラー比較です。`Float` と `Double` に実装されています。

## 境界

このパッケージは matrix、vector、backend 型を import しません。依存方向では `algebra` とすべての backend パッケージより下位にあります。
