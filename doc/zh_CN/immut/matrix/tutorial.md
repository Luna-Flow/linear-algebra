# immut/matrix 教程

## 小案例：用 `3x3` 卷积核给微型 ASCII 字符画做模糊

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

这个案例展示了一个更接近真实用途的值语义矩阵流程：

1. 先把一张很小的字符画写成亮度矩阵。
2. 用 `Matrix::make` 一格一格重建输出矩阵。
3. 用 `source[row][col]` 这样的索引读取 `3x3` 邻域。
4. 最后再把结果渲染回字符画，直接检查模糊效果是否符合预期。

因为模糊操作会返回一份新矩阵，所以原始字符画仍然保留下来，方便你对照输入和输出。这正是不可变矩阵在调试中间变换时很省心的一点。

## 建议流程

1. 使用 `Matrix::from_2d_array`、`Matrix::make`、`Matrix::new` 或 `Matrix::from_array` 构造矩阵。
2. 当每个输出单元都依赖源矩阵里的一个邻域或 stencil 时，优先用 `Matrix::make`。
3. 当形状或输入域可能来自运行时数据时，优先使用带检查的 `matmul`、`trace`、`determinant` 和 `pow`。

## 实践建议

- 只有在外层逻辑已经保证前置条件时，才使用 `unchecked_*`。
- 当惰性的函数式矩阵表示比物化存储更合适时，使用 `MatrixFn`。
- 写卷积核风格的变换时，边界处理一定要显式写清楚；这里使用的是 edge clamp。
- 当更新需要保持显式、而旧矩阵值还要在后续步骤中保留时，优先采用不可变矩阵路径。
