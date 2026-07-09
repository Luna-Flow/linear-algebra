# algebra チュートリアル

## プロジェクト設定

抽象線形代数レイヤーを直接使うなら、まず依存一式を追加してください。

```sh
moon add Luna-Flow/linear-algebra@0.4.4
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推奨する `moon.pkg` インポート:

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/algebra",
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

役割分担は明確です。`@algebra` は線形代数の構造 trait、`@la_arithmetic` は線形代数向けの操作 trait、`@lf_alg` は共有の上流代数抽象、`@lf_arith` は共有の上流算術型を扱います。

## 小さなケース: バックエンド非依存の Gram ステップを組み立てる

```moonbit check
///|
fn[M : @algebra.MatMulMatrix] gram_step(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "algebra tutorial uses linear-algebra traits with a real backend" {
  let features : @default.ImmutableDenseMatrix[Int] = @default.ImmutableDenseMatrix::from_2d_array([
      [1, 2],
      [3, 4],
    ],
  )
  let gram = gram_step(features)
  let (rows, cols) = @algebra.MatrixShape::shape(gram)

  inspect(rows, content="2")
  inspect(cols, content="2")
  inspect(gram.inner(), content="|10, 14|\n|14, 20|")
}
```

この例は、このパッケージ自身が持つ線形代数 trait だけで、
バックエンド非依存の処理を書けることを示しています。

1. `MatMulMatrix` で、行列らしい乗算が必要だと表現する。
2. `MatMulMatrix` 系列から使える `TransposeMatrix` で転置を呼び出し、密実装 API に直結しない。
3. `MatrixShape` で結果形状を読み出し、保存形式に依存しない。
4. 最後に既定バックエンドの実装型へそのまま適用し、抽象 trait が実運用の能力につながっていることを確かめる。

こうしておくと、線形代数の意味を保ったままアルゴリズムを汎用化できます。

## 推奨フロー

1. アルゴリズムが「どのバックエンドか」より「どんな構造が必要か」を重視するなら、まず `algebra` から考えます。
2. `AdditiveVector`、`MatrixShape`、`TransposeMatrix`、`MatMulMatrix` などの trait で必要な構造を表します。
3. 本当に特定の計算操作が必要なときだけ、より狭い arithmetic 制約を追加します。

## 実践ガイド

- アルゴリズムの意味を表せる最小の構造制約を選びます。
- 内積、ノルム、求解のようなバックエンド特化の振る舞いは、安易にコア構造層へ入れないようにします。
