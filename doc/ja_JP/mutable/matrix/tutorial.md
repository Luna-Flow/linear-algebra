# mutable/matrix チュートリアル

## 小さなケース: 密行列を校正する

```moonbit check
///|
fn calibrate_dense_matrix(matrix : @mutable.Matrix[Double]) -> Double {
  let first_row = matrix.row_view(0)
  first_row[1] = 9.0
  let first_col = matrix.col_view(0)
  first_col[1] = 5.0
  matrix.determinant().unwrap()
}

///|
test "mutable matrix tutorial case" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
  let det = calibrate_dense_matrix(matrix)

  inspect(matrix, content="|1, 9|\n|5, 4|")
  inspect(det, content="-41")
  inspect(matrix.inverse() is Ok(_), content="true")
}
```

この形は、行列をライブな作業バッファとして扱うときに使いやすい流れです。

1. 具体的な行列を一度だけ構築する。
2. `row_view` と `col_view` でホットな領域を直接更新する。
3. 編集後に `determinant()` や `inverse()` のような検査付き数値 API を呼ぶ。

行列が履歴値ではなく実行対象そのものなら、この流れが最も素直です。

## 推奨フロー

1. `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new`、`Matrix::from_array` で行列を作ります。
2. 直接の要素アクセスには `get` と `set` を使い、特定の行や列を繰り返し扱う場合は `row_view` / `col_view` を使います。
3. 入力が実行時に失敗し得る場合は、検査付きの `trace`、`determinant`、`inverse`、`mul_vec`、`pow` を使います。

## 実践ガイド

- 基底行列に接続された転置ビューが必要なら `to_transpose()`、物理的な転置行列が必要なら `transpose()` を使います。
- 形状、非空、非特異などの前提条件をすでに保証している場合だけ `unchecked_*` を使います。
- 特定の行や列を繰り返し読み書きするなら、毎回添字計算を繰り返すよりビューを使うほうが扱いやすいです。
