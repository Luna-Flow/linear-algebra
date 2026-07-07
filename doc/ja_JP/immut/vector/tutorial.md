# immut/vector チュートリアル

## 推奨フロー

1. `Vector::from_array`、`Vector::make`、`Vector::makei` でベクトルを作ります。
2. 新しいベクトルが必要な場合は `set`、`map`、`left_scale`、`right_scale` を使います。
3. 代数的な変換には `dot`、`tensor_product`、`to_row_matrix`、`to_col_matrix` を使います。

## 実践ガイド

- 下流コードで明示的な値セマンティクスが必要な場合は `@immut.Vector` を選びます。
- 繰り返し原地更新するワークロードでは `@mutable.Vector` を選びます。
