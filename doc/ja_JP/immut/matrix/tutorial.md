# immut/matrix チュートリアル

## 推奨フロー

1. `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new`、`Matrix::from_array` で行列を作ります。
2. `set`、`swap_rows`、`swap_cols`、`map`、`transpose` は新しい行列を返す操作として扱います。
3. 形状や入力領域の失敗が実行時データから来る場合は、検査付きの `matmul`、`trace`、`determinant`、`pow` を優先します。

## 実践ガイド

- 周辺ロジックで前提条件をすでに保証している場合だけ `unchecked_*` を使います。
- 遅延された関数的な行列表現が物理保存より適している場合は `MatrixFn` を使います。
