# immut/matrix チュートリアル

## 小さなケース: `3x3` カーネルで ASCII スプライトをぼかす

```moonbit check
///|
fn glyph_for_intensity(value : Int) -> String {
  match value {
    0 => "."
    1 => ":"
    2 => "-"
    3 => "="
    4 => "+"
    5 => "*"
    6 => "#"
    7 => "%"
    _ => "@"
  }
}

///|
fn render_ascii(matrix : @immut.Matrix[Int]) -> String {
  let logger = StringBuilder::new()
  for row in 0..<matrix.row() {
    for col in 0..<matrix.col() {
      logger.write_string(glyph_for_intensity(matrix[row][col]))
    }
    if row < matrix.row() - 1 {
      logger.write_char('\n')
    }
  }
  logger.to_string()
}

///|
fn clamp_index(value : Int, upper : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper {
    upper - 1
  } else {
    value
  }
}

///|
fn box_blur_3x3(source : @immut.Matrix[Int]) -> @immut.Matrix[Int] {
  @immut.Matrix::make(source.row(), source.col(), fn(row, col) {
    let mut sum = 0
    for row_offset in 0..<3 {
      for col_offset in 0..<3 {
        let sample_row = clamp_index(row + row_offset - 1, source.row())
        let sample_col = clamp_index(col + col_offset - 1, source.col())
        sum = sum + source[sample_row][sample_col]
      }
    }
    sum / 9
  })
}

///|
test "immut matrix tutorial case" {
  let sprite = @immut.Matrix::from_2d_array([
    [0, 0, 0, 0, 0],
    [0, 0, 9, 0, 0],
    [0, 9, 9, 9, 0],
    [0, 0, 9, 0, 0],
    [0, 0, 0, 0, 0],
  ])
  let blurred = box_blur_3x3(sprite)

  inspect(render_ascii(sprite), content=".....\n..@..\n.@@@.\n..@..\n.....")
  inspect(render_ascii(blurred), content=".:::.\n:=+=:\n:+*+:\n:=+=:\n.:::.")
  inspect(sprite[1][2], content="9")
  inspect(blurred[1][2], content="4")
}
```

このケースは、実際の小さな用途に寄せた値セマンティクスの行列処理です。

1. 小さな ASCII スプライトを輝度行列として持つ。
2. `Matrix::make` で出力行列を 1 セルずつ作り直す。
3. `source[row][col]` の索引アクセスで `3x3` 近傍を読む。
4. 最後に文字列へ戻して、ぼかし結果を目で確認する。

ぼかし結果は新しい行列として返るため、元のスプライトは比較用にそのまま残ります。途中結果を見比べたいときに、不変行列はとても扱いやすいです。

## 推奨フロー

1. `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new`、`Matrix::from_array` で行列を作ります。
2. 出力セルごとに元行列の近傍や stencil を参照する処理では、`Matrix::make` を優先します。
3. 形状や入力領域の失敗が実行時データから来る場合は、検査付きの `matmul`、`trace`、`determinant`、`pow` を優先します。

## 実践ガイド

- 周辺ロジックで前提条件をすでに保証している場合だけ `unchecked_*` を使います。
- 遅延された関数的な行列表現が物理保存より適している場合は `MatrixFn` を使います。
- カーネル系の変換では、境界をどう扱うかを明示してください。この例では edge clamp を使っています。
- 更新を明示的な値変換として扱い、以前の行列値も後続処理で保持したいなら、不変行列の流れが向いています。
