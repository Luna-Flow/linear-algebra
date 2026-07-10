# Container Capability API

The `container` package describes how generic code observes, constructs, and
edits linear containers. It does not define mathematical laws or require a
dense layout.

## Experimental Status

`container` is an experimental feature. Its read/build model is available for
real interoperability trials, while operation-record fields, edit
capabilities, error contracts, and generic algorithm signatures may still
change incompatibly. Use it as a checked data-interchange and structural
transformation layer, not as a compatibility-stable public boundary or a
high-performance numerical kernel API.

External library authors should use the capability-level guidance in the
[ecosystem integration guide](./integration.md) before selecting adapters.

## Capability Records

- `VectorReadOps[V, T]`: `length` and checked `get`.
- `MatrixReadOps[M, T]`: `shape` and checked `get`.
- `VectorBuildOps[V, T]`: checked `tabulate` construction.
- `MatrixBuildOps[M, T]`: checked row/column `tabulate` construction.
- `VectorPersistentEditOps[V, T]` and `MatrixPersistentEditOps[M, T]`:
  checked replacement returning a new value.
- `VectorMutableEditOps[V, T]` and `MatrixMutableEditOps[M, T]`: checked
  in-place replacement returning `Result[Unit, LinearAlgebraError]`.

Each record has a `new` constructor. Read and edit operations must return
`IndexOutOfBounds` for invalid coordinates. Builders must return
`NegativeDimension` rather than calling an initializer for an invalid shape.

## Generic Algorithms

- `vector_map` and `matrix_map` may change the container and scalar types.
- `vector_convert` and `matrix_convert` preserve the scalar type while changing
  storage backends.
- `matrix_transpose` may produce a different target matrix type.

The algorithms retain exact degenerate shapes such as `0xN` and `Nx0`. They
read into a temporary linear buffer before construction, so a checked read
failure cannot leave a partially constructed target.

## Repository Adapters

The `container/adapters` package provides factories for `immut.Vector`,
`immut.Matrix`, `mutable.Vector`, `mutable.Matrix`, the four default dense
wrappers, mutable row/column views, and mutable transpose views. Views provide
read and mutable-edit capabilities but no build capability.

The native-only OpenBLAS package provides `blas_vector_read_ops`,
`blas_vector_build_ops`, `blas_matrix_read_ops`, and `blas_matrix_build_ops`.
It intentionally does not advertise persistent editing.
