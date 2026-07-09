# mutable/vector Tutorial

## Small Case: Score A Candidate With A Working Copy

```moonbit check
///|
fn score_candidate(
  raw_features : @mutable.Vector[Int],
  weights : @mutable.Vector[Int],
) -> Int {
  let working = raw_features.copy()
  working.map_inplace(fn(x) { x + 1 })
  working.left_scale_inplace(2)
  working.dot(weights)
}

///|
test "mutable vector tutorial case" {
  let raw = @mutable.Vector::from_array([1, 2, 3])
  let weights = @mutable.Vector::from_array([3, 4, 5])
  let score = score_candidate(raw, weights)

  inspect(raw, content="|1, 2, 3|")
  inspect(score, content="76")
}
```

This is a solid mutation-oriented pattern:

1. Keep the caller-facing vector unchanged.
2. Take a `copy()` as a working buffer.
3. Perform normalization and scaling with `map_inplace` and
   `left_scale_inplace`.
4. Finish with `dot` once the vector is ready for scoring.

## Suggested Flow

1. Create vectors with `Vector::from_array`, `Vector::make`, or `Vector::makei`.
2. Use `v[i]` and `v[i] = x` for direct element access.
3. Use `map_inplace`, `left_scale_inplace`, and `right_scale_inplace` when mutation is intended.
4. Use `dot`, `lin_comb`, `tensor_product`, `to_row_matrix`, and `to_col_matrix` when the vector participates in larger algebraic or matrix-building work.

## Practical Guidance

- Use non-`inplace` helpers when you need a fresh vector instead of modifying the original.
- Call `copy()` before mutating when a caller still needs the previous value.
- Reach for `dot`, `lin_comb`, and matrix-conversion helpers once the vector is
  participating in a larger numerical workflow.
