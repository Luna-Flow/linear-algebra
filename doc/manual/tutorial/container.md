# container tutorial

This tutorial shows how to move matrices and vectors between representations
with the `container` algorithms, how to change the element type on the way, and
how to make your own container type take part by writing two small operation
dictionaries. The model behind it is in the [container design](../design/container.md).

| I want to | Use |
| --- | --- |
| copy a matrix into another representation | `@container.matrix_convert` |
| convert and change the element type | `@container.matrix_map`, `@container.vector_map` |
| transpose into another representation | `@container.matrix_transpose` |
| edit an entry without knowing the type | a `VectorPersistentEditOps` or `MatrixMutableEditOps` dictionary |
| let my own type take part | build `VectorReadOps` / `MatrixBuildOps` with `new` |

## Quick start

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/container",
  "Luna-Flow/linear-algebra/container/adapters" @container_adapters,
  "Luna-Flow/linear-algebra/error" @la_error,
  "Luna-Flow/linear-algebra/immut",
  "Luna-Flow/linear-algebra/mutable",
}
```

Freeze a mutable working matrix into an immutable value:

```moonbit check
///|
test "freeze a mutable matrix" {
  let work = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  let frozen : @immut.Matrix[Int] = @container.matrix_convert(
    work,
    @container_adapters.mutable_matrix_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  work.set(0, 0, 99)
  inspect(frozen, content="|1, 2|\n|3, 4|")
}
```

The later write to `work` does not reach `frozen`: the conversion copies.

## Everyday tasks

### Convert and change the element type

`matrix_map` converts and transforms in one pass; the element type may change:

```moonbit check
///|
test "integer pixels to normalized doubles" {
  let pixels = @immut.Matrix::from_2d_array([[0, 128], [255, 64]])
  let normalized : @mutable.Matrix[Double] = @container.matrix_map(
    pixels,
    @container_adapters.immutable_matrix_read_ops(),
    @container_adapters.mutable_matrix_build_ops(),
    p => p.to_double() / 255.0,
  ).unwrap()
  inspect(normalized.get(1, 0), content="1")
  inspect(normalized.get(0, 0), content="0")
}
```

### Transpose into a different representation

```moonbit check
///|
test "transpose a dense wrapper into an immutable matrix" {
  let source = @default.DenseMatrix::from_2d_array([[1, 2, 3]])
  let column : @immut.Matrix[Int] = @container.matrix_transpose(
    source,
    @container_adapters.dense_matrix_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(column, content="|1|\n|2|\n|3|")
}
```

### Edit through a dictionary

Edit dictionaries are checked: a bad index is an error value, and nothing is
changed.

```moonbit check
///|
test "checked edits" {
  let m = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let edit = @container_adapters.immutable_matrix_persistent_edit_ops()
  let m2 = (edit.set)(m, 1, 1, 40).unwrap()
  inspect(m2, content="|1, 2|\n|3, 40|")
  inspect(m, content="|1, 2|\n|3, 4|")
  match (edit.set)(m, 2, 0, 0) {
    Err(e) => inspect(e.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("row 2 does not exist")
  }
  let row = @mutable.Matrix::from_2d_array([[5, 6, 7]]).row_view(0)
  let view_edit = @container_adapters.mutable_row_view_mutable_edit_ops()
  (view_edit.set)(row, 2, 70).unwrap()
  inspect(row, content="|5, 6, 70|")
}
```

### Publish dictionaries for your own type

A sparse vector stored as index-value pairs can be read and built. Write the
two dictionaries once; every generic algorithm then accepts the type:

```moonbit check
///|
struct ContTutSparse {
  len : Int
  entries : Array[(Int, Double)]
}

///|
fn cont_tut_sparse_read() -> @container.VectorReadOps[ContTutSparse, Double] {
  @container.VectorReadOps::new(v => v.len, (v, i) => {
    guard i >= 0 && i < v.len else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds("index \{i}"),
      )
    }
    for entry in v.entries {
      if entry.0 == i {
        return Ok(entry.1)
      }
    }
    Ok(0.0)
  })
}

///|
fn cont_tut_sparse_build() -> @container.VectorBuildOps[ContTutSparse, Double] {
  @container.VectorBuildOps::new((n, f) => {
    guard n >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension("length \{n}"),
      )
    }
    let entries = []
    for i in 0..<n {
      let x = f(i)
      if x != 0.0 {
        entries.push((i, x))
      }
    }
    Ok({ len: n, entries, })
  })
}

///|
test "a sparse vector joins the generic algorithms" {
  let sparse : ContTutSparse = { len: 5, entries: [(1, 2.0), (4, -1.0)], }
  let dense : @immut.Vector[Double] = @container.vector_convert(
    sparse,
    cont_tut_sparse_read(),
    @container_adapters.immutable_vector_build_ops(),
  ).unwrap()
  inspect(dense, content="|0, 2, 0, 0, -1|")
  let back : ContTutSparse = @container.vector_convert(
    dense,
    @container_adapters.immutable_vector_read_ops(),
    cont_tut_sparse_build(),
  ).unwrap()
  inspect(back.entries.length(), content="2")
}
```

## Going further

**Which dictionaries to publish.** Provide read for any type that can be
observed, build for any type that can be constructed from a function, and
exactly one of the two edit forms according to ownership: persistent for value
types, mutable for in-place types and views. The
[integration guide](../integration/container.md) lists adoption levels and
who should own the adapter code.

**Laws to test.** For your dictionaries, test that `tabulate` then `get`
returns the initializer's values, that invalid indices give
`IndexOutOfBounds`, that negative shapes give `NegativeDimension`, and that a
persistent `set` leaves its argument unchanged. The design page states these as
equations.

**Performance.** The algorithms copy through closures and buffer the whole
source. They are meant for conversion at boundaries, not for inner loops of
numerical code; use the concrete types' own methods there.

## Common pitfalls

- **Forgetting the parentheses around a field call.** Write
  `(ops.get)(v, i)`, not `ops.get(v, i)`; the fields are closures, not methods.
- **Assuming a view can be a target.** Row, column and transpose views have
  read and mutable-edit dictionaries but no build dictionary.
- **Treating $0 \times 3$ as $0 \times 0$.** Degenerate shapes are preserved;
  check both dimensions.
- **Expecting sharing.** Every algorithm builds a new target; edits to the
  source afterwards are not reflected.

## Next steps

- [container API](../api/container.md) and the
  [adapters API](../api/container/adapters.md).
- [container design](../design/container.md) for the read/build and lens laws.
- [Container integration guide](../integration/container.md) for publishing
  dictionaries from another library.
