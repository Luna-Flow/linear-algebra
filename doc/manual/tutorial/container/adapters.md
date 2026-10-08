# container/adapters tutorial

This tutorial shows how to pick the right ready-made dictionary for each of
the repository's types and use it with the `container` algorithms, including
the live views of `@mutable.Matrix`. If you want to write dictionaries for a
type of your own, read the [container tutorial](../container.md) instead.

| I want to | Use |
| --- | --- |
| copy a row out of a matrix | `mutable_row_view_read_ops` with `vector_convert` |
| materialize a transpose view | `mutable_transpose_read_ops` with `matrix_convert` |
| write through a column view | `mutable_col_view_mutable_edit_ops` |
| move between the backend wrappers | the `dense_*` and `immutable_dense_*` dictionaries |
| find the dictionary for a type | the capability matrix of the [API page](../../api/container/adapters.md) |

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/container",
  "Luna-Flow/linear-algebra/container/adapters" @container_adapters,
  "Luna-Flow/linear-algebra/immut",
  "Luna-Flow/linear-algebra/mutable",
}
```

The factory name tells you the type and the capability:

```moonbit check
///|
test "read one entry through an adapter" {
  let v = @immut.Vector::from_array([10, 20, 30])
  let ops = @container_adapters.immutable_vector_read_ops()
  inspect((ops.length)(v), content="3")
  inspect((ops.get)(v, 2).unwrap(), content="30")
}
```

## Everyday tasks

### Copy a row out of a matrix

A row view is a vector source, so any vector target can receive it:

```moonbit check
///|
test "copy a row view into an immutable vector" {
  let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let row : @immut.Vector[Int] = @container.vector_convert(
    m.row_view(1),
    @container_adapters.mutable_row_view_read_ops(),
    @container_adapters.immutable_vector_build_ops(),
  ).unwrap()
  m.set(1, 0, 40)
  inspect(row, content="|4, 5, 6|")
}
```

### Materialize a transpose view

The transpose view of `@mutable.Matrix` is a matrix source, so
`matrix_convert` materializes it in any representation:

```moonbit check
///|
test "materialize a transpose view" {
  let m = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let t : @immut.Matrix[Int] = @container.matrix_convert(
    m.to_transpose(),
    @container_adapters.mutable_transpose_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(t, content="|1, 4|\n|2, 5|\n|3, 6|")
}
```

### Write through a column view

```moonbit check
///|
test "clear a column through its view" {
  let m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4], [5, 6]])
  let col = m.col_view(0)
  let edit = @container_adapters.mutable_col_view_mutable_edit_ops()
  for i in 0..<col.length() {
    (edit.set)(col, i, 0).unwrap()
  }
  inspect(m, content="|0, 2|\n|0, 4|\n|0, 6|")
}
```

### Move between the default backend wrappers

```moonbit check
///|
test "mutable dense wrapper to immutable dense wrapper" {
  let source = @default.DenseVector::from_array([1.5, 2.5])
  let target : @default.ImmutableDenseVector[Double] = @container.vector_convert(
    source,
    @container_adapters.dense_vector_read_ops(),
    @container_adapters.immutable_dense_vector_build_ops(),
  ).unwrap()
  inspect(target[1], content="2.5")
}
```

## Going further

**Choosing the edit form.** Types with value semantics (`@immut`, the
`Immutable*` wrappers) only have `*_persistent_edit_ops`; types with in-place
semantics (`@mutable`, views, `DenseVector`, `DenseMatrix`) only have
`*_mutable_edit_ops`. Generic code that edits should take the record that
matches the ownership model it expects.

**Views as targets.** Views have no build dictionary. To fill a row of an
existing matrix from another vector, read the source and write through
`mutable_row_view_mutable_edit_ops` in a loop.

## Common pitfalls

- **Expecting a conversion to stay linked.** Converting a view copies; later
  writes to the matrix do not reach the copy, as the row example shows.
- **Using `immutable_*` for the default wrappers.** `immutable_matrix_*`
  adapts `@immut.Matrix`; the wrapper `@default.ImmutableDenseMatrix` has its
  own `immutable_dense_matrix_*` factories.

## Next steps

- [adapters API](../../api/container/adapters.md) for the full list.
- [container tutorial](../container.md) for writing your own dictionaries.
- [adapters design](../../design/container/adapters.md) for the dependency
  structure.
