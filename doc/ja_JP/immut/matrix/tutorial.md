# immut/matrix チュートリアル

## 小さなケース: レイアウト行列を修正して再出力する

```moonbit check
///|
fn rebuild_layout(matrix : @immut.Matrix[Int]) -> @immut.Matrix[Int] {
  matrix.set(0, 1, 9).swap_rows(0, 1).transpose()
}

///|
test "immut matrix tutorial case" {
  let original = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let exported = rebuild_layout(original)

  inspect(original, content="|1, 2|\n|3, 4|")
  inspect(exported, content="|3, 1|\n|4, 9|")
  inspect(exported.determinant().unwrap(), content="23")
}
```

このケースは、値セマンティクスの行列処理をそのまま表しています。

1. `set` で 1 セルを修正する。
2. `swap_rows` で表示順を入れ替える。
3. `transpose` で最終出力を作る。
4. 仕上がった行列に対して `determinant()` のような検査付き数値 API を使う。

各段階が新しい行列を返すため、元のレイアウトは保持されます。

## 推奨フロー

1. `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new`、`Matrix::from_array` で行列を作ります。
2. `set`、`swap_rows`、`swap_cols`、`map`、`transpose` は新しい行列を返す操作として扱います。
3. 形状や入力領域の失敗が実行時データから来る場合は、検査付きの `matmul`、`trace`、`determinant`、`pow` を優先します。

## 実践ガイド

- 周辺ロジックで前提条件をすでに保証している場合だけ `unchecked_*` を使います。
- 遅延された関数的な行列表現が物理保存より適している場合は `MatrixFn` を使います。
- 更新を明示的な値変換として扱い、以前の行列値も後続処理で保持したいなら、不変行列の流れが向いています。
