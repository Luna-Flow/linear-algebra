# immut/vector チュートリアル

## 小さなケース: 公開済み特徴ベクトルを作り直す

```moonbit check
///|
fn rebuild_release_vector(
  base : @immut.Vector[Int],
  manual_override : Int,
) -> @immut.Matrix[Int] {
  let corrected = base.set(1, manual_override)
  let expanded = @immut.lin_comb(
    2,
    corrected,
    1,
    @immut.Vector::from_array([1, 0, 1]),
  )
  expanded.tensor_product(@immut.Vector::from_array([1, 0]))
}

///|
test "immut vector tutorial case" {
  let base = @immut.Vector::from_array([2, 4, 6])
  let result = rebuild_release_vector(base, 9)

  inspect(base, content="|2, 4, 6|")
  inspect(result, content="|5, 0|\n|18, 0|\n|13, 0|")
}
```

このケースは、小さなリリース前パイプラインとして捉えられます。

1. 既に公開されているベースベクトルを用意する。
2. `set` で 1 箇所だけ明示的に補正する。
3. `lin_comb` で新しい重み付きベクトルを組み立てる。
4. `tensor_product` で行列状の成果物へ広げる。

元のベクトルは一切変更されないため、前の状態もそのまま再利用できます。

## 推奨フロー

1. `Vector::from_array`、`Vector::make`、`Vector::makei` でベクトルを作ります。
2. 新しいベクトルが必要な場合は `set`、`map`、`left_scale`、`right_scale` を使います。
3. 行列へつなぐ変換には `tensor_product`、`scaled_matrix`、`to_row_matrix`、`to_col_matrix` を使います。

## 実践ガイド

- 下流コードで明示的な値セマンティクスが必要な場合は `@immut.Vector` を選びます。
- 繰り返しインプレース更新したい場合や公開 `dot()` ヘルパーが必要な場合は `@mutable.Vector` を選びます。
- 構造変更のたびに新しい値を返し、古い値もそのまま保持したいなら、この不変ベクトル側から始めてください。
