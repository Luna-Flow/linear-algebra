# immut/vector Tutorial

## Small Case: Rebuild A Published Feature Vector

```moonbit check
///|
fn rebuild_release_vector(
  base : @immut.Vector[Int],
  manual_override : Int,
) -> @immut.Matrix[Int] {
  let corrected = base.set(1, manual_override)
  let expanded = @immut.lin_comb(
    2,
    corrected,
    1,
    @immut.Vector::from_array([1, 0, 1]),
  )
  expanded.tensor_product(@immut.Vector::from_array([1, 0]))
}

///|
test "immut vector tutorial case" {
  let base = @immut.Vector::from_array([2, 4, 6])
  let result = rebuild_release_vector(base, 9)

  inspect(base, content="|2, 4, 6|")
  inspect(result, content="|5, 0|\n|18, 0|\n|13, 0|")
}
```

This case reads like a tiny release-preparation pipeline:

1. Start from a published feature vector.
2. Apply one explicit correction with `set`.
3. Build a new weighted vector with `lin_comb`.
4. Expand it into a matrix-shaped artifact with `tensor_product`.

At no point is the original vector mutated, so earlier states remain usable.

## Suggested Flow

1. Create vectors with `Vector::from_array`, `Vector::make`, or `Vector::makei`.
2. Use `set`, `map`, `left_scale`, and `right_scale` when you want a new vector.
3. Use `tensor_product`, `scaled_matrix`, `to_row_matrix`, and `to_col_matrix` for matrix-facing conversions.

## Practical Guidance

- Choose `@immut.Vector` when downstream code benefits from explicit value semantics.
- Use `@mutable.Vector` instead when repeated in-place updates or a public `dot()` helper are part of the workload.
- Use the immutable path when every structural change should produce a fresh
  value that can be passed onward safely.
