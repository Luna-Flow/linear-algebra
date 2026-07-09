# error チュートリアル

## 小さなケース: 失敗した逆行列要求を分類する

```moonbit check
///|
fn classify_inverse_request(matrix : @mutable.Matrix[Double]) -> String {
  match matrix.inverse() {
    Ok(_) => "ok"
    Err(err) =>
      if err.is_non_square_matrix() {
        "non-square"
      } else if err.is_singular_matrix() {
        "singular"
      } else {
        err.message
      }
  }
}

///|
test "inverse handling branches on error kind" {
  let matrix = @mutable.Matrix::from_2d_array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
  inspect(classify_inverse_request(matrix), content="non-square")
}
```

この例は、呼び出し側が失敗理由ごとに回復方法を変えたい場面を想定しています。

1. `Result[..., LinearAlgebraError]` を返す検査付き API を呼ぶ。
2. メッセージ文字列を推測に使わず、エラー判定メソッドで分岐する。
3. 既知の回復経路に当てはまらない場合だけ、一般的な診断メッセージへ戻る。

こうしておくと、人間向けメッセージが将来調整されても制御フローは安定したままです。

## 推奨フロー

1. ユーザー入力や実行時データを扱うコードでは、検査付き行列 API を優先します。
2. 回復判断が必要な場所の近くで `Ok` / `Err` を処理します。
3. `is_dimension_mismatch`、`is_negative_exponent`、`is_empty_matrix`、`is_non_square_matrix` などの判定メソッドで制御フローを組み立てます。

## 実践ガイド

- `message` は診断、ログ、最後のフォールバック表示に使い、制御フロー判定には使いません。
- `ArithmeticFailure` は下位の算術パッケージから来る境界エラーとして扱います。
- 周囲のロジックで前提条件を保証済みの場合だけ `unchecked_*` へ戻ります。
