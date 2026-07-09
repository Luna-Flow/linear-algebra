# mutable/vector チュートリアル

## 小さなケース: 作業コピーで候補を採点する

```moonbit check
///|
fn score_candidate(
  raw_features : @mutable.Vector[Int],
  weights : @mutable.Vector[Int],
) -> Int {
  let working = raw_features.copy()
  working.map_inplace(fn(x) { x + 1 })
  working.left_scale_inplace(2)
  working.dot(weights)
}

///|
test "mutable vector tutorial case" {
  let raw = @mutable.Vector::from_array([1, 2, 3])
  let weights = @mutable.Vector::from_array([3, 4, 5])
  let score = score_candidate(raw, weights)

  inspect(raw, content="|1, 2, 3|")
  inspect(score, content="76")
}
```

これは可変ベクトルでよく使う形です。

1. 呼び出し元が渡した元のベクトルは残す。
2. `copy()` で作業用バッファを作る。
3. `map_inplace` と `left_scale_inplace` で前処理する。
4. 最後に `dot` で採点する。

## 推奨フロー

1. `Vector::from_array`、`Vector::make`、`Vector::makei` でベクトルを作ります。
2. `v[i]` と `v[i] = x` で要素を直接読み書きします。
3. 元の値を変更する意図がある場合は `map_inplace`、`left_scale_inplace`、`right_scale_inplace` を使います。
4. 帰着、線形結合、行列変換には `dot`、`lin_comb`、`tensor_product`、`to_row_matrix`、`to_col_matrix` を使います。

## 実践ガイド

- 元のベクトルを残したい場合は、`inplace` 接尾辞を持たないヘルパーを使います。
- 変更前の値も後で使うなら、先に `copy()` を取ってからインプレース操作に入ります。
- ベクトルがより大きな数値処理に入ったら、`dot`、`lin_comb`、行列変換ヘルパーへ進むと流れがつかみやすいです。
