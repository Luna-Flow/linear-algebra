# backends/default design

## Responsibilities

- Present `immut` and `mutable` as default dense backends through owned wrapper
  types.
- Implement capability traits for the default dense matrix and vector types.
- Provide small generic helpers that exercise trait-based dispatch.

## Non-responsibilities

- Do not redefine scalar algebra or arithmetic laws.
- Do not require all future backends to become dense or contiguous.
- Do not make scalar-valued maps part of the core linear algebra trait surface.

## Extension model

Future sparse, lazy, static-size, GPU, or external-library backends should
implement the same structural traits directly. They should not need to convert
into `DenseMatrix` or `DenseVector` before generic algorithms can use them.
