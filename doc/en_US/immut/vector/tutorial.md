# immut/vector Tutorial

## Suggested Flow

1. Create vectors with `Vector::from_array`, `Vector::make`, or `Vector::makei`.
2. Use `set`, `map`, `left_scale`, and `right_scale` when you want a new vector.
3. Use `dot`, `tensor_product`, `to_row_matrix`, and `to_col_matrix` for algebraic conversions.

## Practical Guidance

- Choose `@immut.Vector` when downstream code benefits from explicit value semantics.
- Use `@mutable.Vector` instead when repeated in-place updates are part of the workload.
