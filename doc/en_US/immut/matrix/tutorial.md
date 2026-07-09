# immut/matrix Tutorial

## Small Case: Blur A Tiny ASCII Sprite With A 3x3 Kernel

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

This case shows a value-oriented matrix workflow that feels close to a real
image-processing toy:

1. Store a tiny sprite as an intensity matrix.
2. Rebuild a new matrix with `Matrix::make`, one blurred output cell at a time.
3. Sample a 3x3 neighborhood with index reads such as `source[row][col]`.
4. Render the result back into visible ASCII output for a quick correctness check.

Because the blur returns a new matrix, the original sprite stays available for
comparison. That is often the nicest property of the immutable path when you
want to inspect intermediate transforms.

## Suggested Flow

1. Build matrices with `Matrix::from_2d_array`, `Matrix::make`, `Matrix::new`, or `Matrix::from_array`.
2. Use `Matrix::make` when every output cell depends on a neighborhood or stencil from the source matrix.
3. Prefer checked `matmul`, `trace`, `determinant`, and `pow` when shape or domain failures can come from runtime data.

## Practical Guidance

- Use `unchecked_*` only when surrounding code has already enforced the required preconditions.
- Use `MatrixFn` when a lazy functional matrix representation is more appropriate than materialized storage.
- Clamp or otherwise define your border policy explicitly when you write kernel-style transforms.
- Prefer the immutable path when updates should remain explicit and old matrix
  values still need to be preserved for later steps.
