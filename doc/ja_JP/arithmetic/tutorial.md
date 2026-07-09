# arithmetic チュートリアル

## プロジェクト設定

まず共有抽象パッケージを追加してください。

```sh
moon add Luna-Flow/linear-algebra@0.4.3
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

## 小さなケース: 符号付き残差をペナルティ値に変える

```moonbit check
///|
fn[T : @la_arithmetic.Abs] residual_penalty(value : T) -> T {
  @la_arithmetic.Abs::abs(value)
}

///|
test "Abs-based penalty helper compiles for Int" {
  inspect(residual_penalty(-3), content="3")
}
```

この例は小さいですが、`arithmetic` 層の役割をそのまま表しています。

1. 線形代数処理から生まれた生のスカラー値を受け取る。
2. ここで本当に必要な操作だけを要求する。今回は `Abs`。
3. より強い代数構造を主張せず、符号付き残差をペナルティ値へ変換する。

必要なのが「計算可能な操作」であって「完全な数学構造」ではない場合、
この分け方が最も自然です。

## 推奨フロー

1. `abs`、検査付き除算、検査付き平方根、近似比較のような具体操作が必要なら `arithmetic` を使います。
2. 制約はできるだけ狭く保ち、より多くのスカラー型で再利用できるようにします。
3. より強い構造的意味が必要になったときだけ `algebra` へ上がります。

## 実践ガイド

- `Luna-Flow/luna-generic` や `Luna-Flow/arithmetic` に既存の trait があるなら、それを優先して使います。
- 上流に適切な名前がない場合にだけ、線形代数向けのローカル trait を追加します。
- arithmetic-only trait を、より強い代数保証の代わりに使わないでください。
