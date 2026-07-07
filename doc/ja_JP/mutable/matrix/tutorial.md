# mutable/matrix チュートリアル

## 推奨フロー

1. `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new`、`Matrix::from_array` で行列を作ります。
2. 直接の要素アクセスには `get` と `set` を使い、特定の行や列を繰り返し扱う場合は `row_view` / `col_view` を使います。
3. 入力が実行時に失敗し得る場合は、検査付きの `trace`、`determinant`、`inverse`、`mul_vec`、`pow` を使います。

## 実践ガイド

- 基底行列に接続された転置ビューが必要なら `to_transpose()`、物理的な転置行列が必要なら `transpose()` を使います。
- 形状、非空、非特異などの前提条件をすでに保証している場合だけ `unchecked_*` を使います。
