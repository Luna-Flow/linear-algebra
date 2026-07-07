# mutable/vector Tutorial

## Suggested Flow

1. Create vectors with `Vector::from_array`, `Vector::make`, or `Vector::makei`.
2. Use `v[i]` and `v[i] = x` for direct element access.
3. Use `map_inplace`, `left_scale_inplace`, and `right_scale_inplace` when mutation is intended.

## Practical Guidance

- Use non-`inplace` helpers when you need a fresh vector instead of modifying the original.
- Use `dot`, `tensor_product`, `to_row_matrix`, and `to_col_matrix` for algebraic conversions.
