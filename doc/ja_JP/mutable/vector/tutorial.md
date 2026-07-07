# mutable/vector チュートリアル

## 推奨フロー

1. `Vector::from_array`、`Vector::make`、`Vector::makei` でベクトルを作ります。
2. `v[i]` と `v[i] = x` で要素を直接読み書きします。
3. 元の値を変更する意図がある場合は `map_inplace`、`left_scale_inplace`、`right_scale_inplace` を使います。

## 実践ガイド

- 元のベクトルを残したい場合は、非 `inplace` のヘルパーを使います。
- 代数的な変換には `dot`、`tensor_product`、`to_row_matrix`、`to_col_matrix` を使います。
