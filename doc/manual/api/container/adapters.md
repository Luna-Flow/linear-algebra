# container/adapters API

`Luna-Flow/linear-algebra/container/adapters` provides ready-made
[`container`](../container.md) operation dictionaries for every vector and
matrix type of this repository: the `@immut` and `@mutable` types, the mutable
row, column and transpose views, and the four `backends/default` wrappers. Each
factory is a generic function that returns a fresh dictionary; it has no state.

Source: [`src/container/adapters`](../../../../src/container/adapters/vector_adapters.mbt).
Why the adapters live in a package of their own is explained in the
[adapters design](../../design/container/adapters.md).

> [!WARNING]
> Like `container`, this package is experimental.

## Import

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/container",
  "Luna-Flow/linear-algebra/container/adapters" @container_adapters,
}
```

## Capability matrix

| Type | read | build | persistent edit | mutable edit |
| --- | --- | --- | --- | --- |
| `@immut.Vector[T]` | yes | yes | yes | no |
| `@immut.Matrix[T]` | yes | yes | yes | no |
| `@mutable.Vector[T]` | yes | yes | no | yes |
| `@mutable.Matrix[T]` | yes | yes | no | yes |
| `@mutable.RowView[T]`, `@mutable.ColView[T]` | yes | no | no | yes |
| `@mutable.Transpose[T]` | yes | no | no | yes |
| `@default.DenseVector[T]`, `@default.DenseMatrix[T]` | yes | yes | no | yes |
| `@default.ImmutableDenseVector[T]`, `@default.ImmutableDenseMatrix[T]` | yes | yes | yes | no |

Every dictionary follows the shared contract of the `container` API: reads and
edits check indices first and return `IndexOutOfBounds` without touching
storage; builders return `NegativeDimension` for a negative shape without
calling the initializer. No factory places a constraint on `T`.

## `@immut.Vector`

### `immutable_vector_read_ops`

`immutable_vector_read_ops` returns the read dictionary for `@immut.Vector`.

```mbti
pub fn[T] immutable_vector_read_ops() -> @container.VectorReadOps[@immut.Vector[T], T]
```

`get` reads `v[i]` after a bounds check.

### `immutable_vector_build_ops`

`immutable_vector_build_ops` returns the build dictionary for `@immut.Vector`.

```mbti
pub fn[T] immutable_vector_build_ops() -> @container.VectorBuildOps[@immut.Vector[T], T]
```

`tabulate(n, f)` is `@immut.Vector::makei(n, f)`.

### `immutable_vector_persistent_edit_ops`

`immutable_vector_persistent_edit_ops` returns the persistent-edit dictionary for `@immut.Vector`.

```mbti
pub fn[T] immutable_vector_persistent_edit_ops() -> @container.VectorPersistentEditOps[@immut.Vector[T], T]
```

`set` returns `v.set(i, x)`; `v` is unchanged.

## `@immut.Matrix`

### `immutable_matrix_read_ops`

`immutable_matrix_read_ops` returns the read dictionary for `@immut.Matrix`.

```mbti
pub fn[T] immutable_matrix_read_ops() -> @container.MatrixReadOps[@immut.Matrix[T], T]
```

`shape` is `(m.row(), m.col())`; `get` reads `m[r][c]` after a bounds check.

### `immutable_matrix_build_ops`

`immutable_matrix_build_ops` returns the build dictionary for `@immut.Matrix`.

```mbti
pub fn[T] immutable_matrix_build_ops() -> @container.MatrixBuildOps[@immut.Matrix[T], T]
```

`tabulate(r, c, f)` is `@immut.Matrix::make(r, c, f)`.

### `immutable_matrix_persistent_edit_ops`

`immutable_matrix_persistent_edit_ops` returns the persistent-edit dictionary for `@immut.Matrix`.

```mbti
pub fn[T] immutable_matrix_persistent_edit_ops() -> @container.MatrixPersistentEditOps[@immut.Matrix[T], T]
```

`set` returns `m.set(r, c, x)`; `m` is unchanged.

## `@mutable.Vector`

### `mutable_vector_read_ops`

`mutable_vector_read_ops` returns the read dictionary for `@mutable.Vector`.

```mbti
pub fn[T] mutable_vector_read_ops() -> @container.VectorReadOps[@mutable.Vector[T], T]
```

`get` reads `v[i]` after a bounds check.

### `mutable_vector_build_ops`

`mutable_vector_build_ops` returns the build dictionary for `@mutable.Vector`.

```mbti
pub fn[T] mutable_vector_build_ops() -> @container.VectorBuildOps[@mutable.Vector[T], T]
```

`tabulate(n, f)` is `@mutable.Vector::makei(n, f)`.

### `mutable_vector_mutable_edit_ops`

`mutable_vector_mutable_edit_ops` returns the mutable-edit dictionary for `@mutable.Vector`.

```mbti
pub fn[T] mutable_vector_mutable_edit_ops() -> @container.VectorMutableEditOps[@mutable.Vector[T], T]
```

`set` writes `v[i] = x` after a bounds check.

## `@mutable.Matrix`

### `mutable_matrix_read_ops`

`mutable_matrix_read_ops` returns the read dictionary for `@mutable.Matrix`.

```mbti
pub fn[T] mutable_matrix_read_ops() -> @container.MatrixReadOps[@mutable.Matrix[T], T]
```

`get` is `m.get(r, c)` after a bounds check.

### `mutable_matrix_build_ops`

`mutable_matrix_build_ops` returns the build dictionary for `@mutable.Matrix`.

```mbti
pub fn[T] mutable_matrix_build_ops() -> @container.MatrixBuildOps[@mutable.Matrix[T], T]
```

`tabulate` fills a fresh row-major array, calling the initializer in row-major order.

### `mutable_matrix_mutable_edit_ops`

`mutable_matrix_mutable_edit_ops` returns the mutable-edit dictionary for `@mutable.Matrix`.

```mbti
pub fn[T] mutable_matrix_mutable_edit_ops() -> @container.MatrixMutableEditOps[@mutable.Matrix[T], T]
```

`set` is `m.set(r, c, x)` after a bounds check.

## `@mutable.RowView`

### `mutable_row_view_read_ops`

`mutable_row_view_read_ops` returns the read dictionary for `@mutable.RowView`.

```mbti
pub fn[T] mutable_row_view_read_ops() -> @container.VectorReadOps[@mutable.RowView[T], T]
```

`length` is the column count of the underlying matrix; `get(i)` reads entry `(row, i)`.

### `mutable_row_view_mutable_edit_ops`

`mutable_row_view_mutable_edit_ops` returns the mutable-edit dictionary for `@mutable.RowView`.

```mbti
pub fn[T] mutable_row_view_mutable_edit_ops() -> @container.VectorMutableEditOps[@mutable.RowView[T], T]
```

`set(i, x)` writes entry `(row, i)` of the underlying matrix.

## `@mutable.ColView`

### `mutable_col_view_read_ops`

`mutable_col_view_read_ops` returns the read dictionary for `@mutable.ColView`.

```mbti
pub fn[T] mutable_col_view_read_ops() -> @container.VectorReadOps[@mutable.ColView[T], T]
```

`length` is the row count of the underlying matrix; `get(i)` reads entry `(i, col)`.

### `mutable_col_view_mutable_edit_ops`

`mutable_col_view_mutable_edit_ops` returns the mutable-edit dictionary for `@mutable.ColView`.

```mbti
pub fn[T] mutable_col_view_mutable_edit_ops() -> @container.VectorMutableEditOps[@mutable.ColView[T], T]
```

`set(i, x)` writes entry `(i, col)` of the underlying matrix.

## `@mutable.Transpose`

### `mutable_transpose_read_ops`

`mutable_transpose_read_ops` returns the read dictionary for `@mutable.Transpose`.

```mbti
pub fn[T] mutable_transpose_read_ops() -> @container.MatrixReadOps[@mutable.Transpose[T], T]
```

`shape` is the transposed shape; `get(r, c)` reads entry `(c, r)` of the underlying matrix.

### `mutable_transpose_mutable_edit_ops`

`mutable_transpose_mutable_edit_ops` returns the mutable-edit dictionary for `@mutable.Transpose`.

```mbti
pub fn[T] mutable_transpose_mutable_edit_ops() -> @container.MatrixMutableEditOps[@mutable.Transpose[T], T]
```

`set(r, c, x)` writes entry `(c, r)` of the underlying matrix.

## `@default.DenseVector`

### `dense_vector_read_ops`

`dense_vector_read_ops` returns the read dictionary for `@default.DenseVector`.

```mbti
pub fn[T] dense_vector_read_ops() -> @container.VectorReadOps[@default.DenseVector[T], T]
```

`get` reads the wrapped `@mutable.Vector`.

### `dense_vector_build_ops`

`dense_vector_build_ops` returns the build dictionary for `@default.DenseVector`.

```mbti
pub fn[T] dense_vector_build_ops() -> @container.VectorBuildOps[@default.DenseVector[T], T]
```

`tabulate` builds a new `@mutable.Vector` and wraps it.

### `dense_vector_mutable_edit_ops`

`dense_vector_mutable_edit_ops` returns the mutable-edit dictionary for `@default.DenseVector`.

```mbti
pub fn[T] dense_vector_mutable_edit_ops() -> @container.VectorMutableEditOps[@default.DenseVector[T], T]
```

`set` writes into the wrapped vector, which is shared with every copy of the wrapper.

## `@default.DenseMatrix`

### `dense_matrix_read_ops`

`dense_matrix_read_ops` returns the read dictionary for `@default.DenseMatrix`.

```mbti
pub fn[T] dense_matrix_read_ops() -> @container.MatrixReadOps[@default.DenseMatrix[T], T]
```

`get` reads the wrapped `@mutable.Matrix`.

### `dense_matrix_build_ops`

`dense_matrix_build_ops` returns the build dictionary for `@default.DenseMatrix`.

```mbti
pub fn[T] dense_matrix_build_ops() -> @container.MatrixBuildOps[@default.DenseMatrix[T], T]
```

`tabulate` builds a new row-major `@mutable.Matrix` and wraps it.

### `dense_matrix_mutable_edit_ops`

`dense_matrix_mutable_edit_ops` returns the mutable-edit dictionary for `@default.DenseMatrix`.

```mbti
pub fn[T] dense_matrix_mutable_edit_ops() -> @container.MatrixMutableEditOps[@default.DenseMatrix[T], T]
```

`set` writes into the wrapped matrix.

## `@default.ImmutableDenseVector`

### `immutable_dense_vector_read_ops`

`immutable_dense_vector_read_ops` returns the read dictionary for `@default.ImmutableDenseVector`.

```mbti
pub fn[T] immutable_dense_vector_read_ops() -> @container.VectorReadOps[@default.ImmutableDenseVector[T], T]
```

`get` reads the wrapped `@immut.Vector`.

### `immutable_dense_vector_build_ops`

`immutable_dense_vector_build_ops` returns the build dictionary for `@default.ImmutableDenseVector`.

```mbti
pub fn[T] immutable_dense_vector_build_ops() -> @container.VectorBuildOps[@default.ImmutableDenseVector[T], T]
```

`tabulate` builds a new `@immut.Vector` and wraps it.

### `immutable_dense_vector_persistent_edit_ops`

`immutable_dense_vector_persistent_edit_ops` returns the persistent-edit dictionary for `@default.ImmutableDenseVector`.

```mbti
pub fn[T] immutable_dense_vector_persistent_edit_ops() -> @container.VectorPersistentEditOps[@default.ImmutableDenseVector[T], T]
```

`set` returns a new wrapper around `inner.set(i, x)`.

## `@default.ImmutableDenseMatrix`

### `immutable_dense_matrix_read_ops`

`immutable_dense_matrix_read_ops` returns the read dictionary for `@default.ImmutableDenseMatrix`.

```mbti
pub fn[T] immutable_dense_matrix_read_ops() -> @container.MatrixReadOps[@default.ImmutableDenseMatrix[T], T]
```

`get` reads the wrapped `@immut.Matrix`.

### `immutable_dense_matrix_build_ops`

`immutable_dense_matrix_build_ops` returns the build dictionary for `@default.ImmutableDenseMatrix`.

```mbti
pub fn[T] immutable_dense_matrix_build_ops() -> @container.MatrixBuildOps[@default.ImmutableDenseMatrix[T], T]
```

`tabulate` builds a new `@immut.Matrix` and wraps it.

### `immutable_dense_matrix_persistent_edit_ops`

`immutable_dense_matrix_persistent_edit_ops` returns the persistent-edit dictionary for `@default.ImmutableDenseMatrix`.

```mbti
pub fn[T] immutable_dense_matrix_persistent_edit_ops() -> @container.MatrixPersistentEditOps[@default.ImmutableDenseMatrix[T], T]
```

`set` returns a new wrapper around `inner.set(r, c, x)`.

## Example

One source, three targets, and a checked edit through a view:

```moonbit check
///|
test "adapters connect every representation" {
  let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  let read = @container_adapters.mutable_matrix_read_ops()
  let dense : @default.DenseMatrix[Int] = @container.matrix_convert(
    m,
    read,
    @container_adapters.dense_matrix_build_ops(),
  ).unwrap()
  let frozen : @default.ImmutableDenseMatrix[Int] = @container.matrix_convert(
    m,
    read,
    @container_adapters.immutable_dense_matrix_build_ops(),
  ).unwrap()
  debug_inspect(@algebra.MatrixShape::shape(dense), content="(2, 2)")
  inspect(frozen.inner(), content="|1, 2|\n|3, 4|")
  let t = m.to_transpose()
  let t_read = @container_adapters.mutable_transpose_read_ops()
  inspect((t_read.get)(t, 0, 1).unwrap(), content="3")
  let col = m.col_view(1)
  (@container_adapters.mutable_col_view_mutable_edit_ops().set)(col, 0, 20).unwrap()
  inspect(m, content="|1, 20|\n|3, 4|")
}
```
