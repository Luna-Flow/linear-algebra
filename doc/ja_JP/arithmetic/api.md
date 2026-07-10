# `linear-algebra/arithmetic`

このページは、現在の `0.4.7` リポジトリにおける
`Luna-Flow/linear-algebra/arithmetic` の公開 API 基準をまとめたものです。

## 役割

`arithmetic` は線形代数パッケージで使う操作レベルの trait を提供します。ここでの trait は「その操作が利用できる」ことだけを表し、代数法則は主張しません。法則を持つ構造は `linear-algebra/algebra` に属します。

## プロジェクト設定

線形代数向けの操作 trait と共有の上流抽象を一緒に使うなら、まず次の依存を追加してください。

```sh
moon add Luna-Flow/linear-algebra@0.4.7
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推奨する `moon.pkg` インポート:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

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

```moonbit check
///|
test "Abs captures absolute-value support" {
  inspect(@la_arithmetic.Abs::abs(-3), content="3")
}
```

絶対値操作です。実装対象:

- `Int`
- `Float`
- `Double`

## `ApproxEq`

```moonbit check
///|
test "ApproxEq captures approximate comparison support" {
  inspect(
    @la_arithmetic.ApproxEq::approx_eq(1.0, 1.0 + 1.0e-13),
    content="true",
  )
}
```

近似等価を判定する操作です。これは操作能力であり、同値関係の法則を主張するものではありません。実装対象:

- `Int`
- `Float`
- `Double`

## `CheckedDiv`

```moonbit check
///|
test "CheckedDiv carries context-aware division" {
  let ctx : @lf_arith.ArithmeticContext = @lf_arith.ArithmeticContext::new(32)
  inspect(
    @la_arithmetic.CheckedDiv::checked_div(6.0, 2.0, ctx).unwrap(),
    content="3",
  )
}
```

`ArithmeticContext` を使う検査付き除算です。`Float` と `Double` に実装されています。

## `CheckedSqrt`

```moonbit check
///|
test "CheckedSqrt carries context-aware square root" {
  let ctx : @lf_arith.ArithmeticContext = @lf_arith.ArithmeticContext::new(32)
  inspect(
    @la_arithmetic.CheckedSqrt::checked_sqrt(9.0, ctx).unwrap(),
    content="3",
  )
}
```

`ArithmeticContext` を使う検査付き平方根です。`Float` と `Double` に実装されています。

## `CheckedCompare`

```moonbit check
///|
test "CheckedCompare returns an explicit ordering result" {
  inspect(
    @la_arithmetic.CheckedCompare::checked_compare(2.0, 3.0).unwrap(),
    content="-1",
  )
}
```

検査付きスカラー比較です。`Float` と `Double` に実装されています。

## 境界

このパッケージは行列、ベクトル、バックエンド型をインポートしません。依存方向では、`algebra` とすべてのバックエンドパッケージより下位にあります。
