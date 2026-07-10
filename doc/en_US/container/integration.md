# Luna-Flow Ecosystem Integration

External libraries should adopt only the capabilities that match their real
semantics. Integration is not an all-or-nothing conformance level, and no
library needs to expose its storage representation.

## Choose the Structural Boundary

| Level | Capability supplied | The type can participate as |
|---|---|---|
| 0 | None | A standalone type using its own API |
| 1 | `VectorReadOps` or `MatrixReadOps` | A source for map, conversion, or transpose |
| 2 | `VectorBuildOps` or `MatrixBuildOps` | A target for map, conversion, or transpose |
| 3 | Matching read and build dictionaries | Both source and target in generic transformations |
| 4P | Persistent edit dictionary | A checked copy-on-replacement value |
| 4M | Mutable edit dictionary | A checked in-place update target |

Levels 4P and 4M are alternatives determined by ownership semantics, not a
progression where every backend should implement both. Views commonly provide
read plus mutable edit but no build. An append-only or generated container may
provide build without read. A foreign handle may intentionally provide read
only.

## Algorithm Requirements

| Algorithm | Source requirement | Target requirement | Scalar relationship |
|---|---|---|---|
| `vector_map` | `VectorReadOps[V1, A]` | `VectorBuildOps[V2, B]` | May change `A` to `B` |
| `matrix_map` | `MatrixReadOps[M1, A]` | `MatrixBuildOps[M2, B]` | May change `A` to `B` |
| `vector_convert` | `VectorReadOps[V1, T]` | `VectorBuildOps[V2, T]` | Preserves `T` |
| `matrix_convert` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | Preserves `T` |
| `matrix_transpose` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | Preserves `T` |

A read dictionary does not imply construction, editing, arithmetic, contiguous
memory, or cheap random access. A build dictionary does not imply that the
result can be read back. Edit dictionaries do not imply resizing, insertion,
deletion, or sparse-entry removal.

## Mathematical Capabilities Are Independent

The `algebra` package describes operations such as addition, transpose, and
matrix multiplication. The `container` package describes observation and
construction. An external type may choose either axis independently:

- Container-only integration supports data movement and structural algorithms
  without claiming algebraic laws for the scalar or container.
- Algebra-only integration supports closed mathematical operations without
  exposing individual elements.
- Supplying both enables both families of generic algorithms, but one does not
  automatically satisfy the other.

Do not add broad scalar trait implementations merely to obtain container
interoperability. Add mathematical traits only when the type actually provides
the documented operation and laws.

## Who Owns the Adapter

Prefer the following ownership order:

1. The library that owns the container type publishes its operation-dictionary
   factories when depending on `Luna-Flow/linear-algebra/container` is natural.
2. A small bridge package owns the adapters when neither project should depend
   directly on the other.
3. `Luna-Flow/linear-algebra` should contain adapters only for implementations
   maintained in this repository.

This direction prevents the core package from accumulating optional backend
dependencies. Factory names should identify the container and capability, and
the factory may carry scalar constraints that are genuinely required by the
backend.

## Complete External Adapter

This example owns a row-major array, but only the operation dictionaries expose
its semantics. The generic transpose targets Luna's immutable matrix type, so
the example exercises a real cross-implementation boundary.

```moonbit check
///|
struct EcosystemOwnedMatrix[T] {
  rows : Int
  cols : Int
  data : Array[T]
}

///|
fn[T] ecosystem_owned_matrix_read_ops() -> @container.MatrixReadOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixReadOps::new(matrix => (matrix.rows, matrix.cols), (
    matrix,
    row,
    col,
  ) => {
    guard row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds(
          "Matrix index out of bounds",
        ),
      )
    }
    Ok(matrix.data[row * matrix.cols + col])
  })
}

///|
fn[T] ecosystem_owned_matrix_build_ops() -> @container.MatrixBuildOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new((rows, cols, initializer) => {
    guard rows >= 0 && cols >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension(
          "Matrix dimensions must be non-negative",
        ),
      )
    }
    Ok({
      rows,
      cols,
      data: Array::makei(rows * cols, index => {
        initializer(index / cols, index % cols)
      }),
    })
  })
}

///|
test "external container adapters preserve actual matrix semantics" {
  let source : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    2,
    3,
    (row, col) => row * 10 + col,
  ).unwrap()
  let target : @immut.Matrix[Int] = @container.matrix_transpose(
    source,
    ecosystem_owned_matrix_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(target, content="|0, 10|\n|1, 11|\n|2, 12|")
  match (ecosystem_owned_matrix_read_ops().get)(source, -1, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("negative row must fail")
  }
  let degenerate : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    0,
    3,
    (_, _) => 0,
  ).unwrap()
  debug_inspect((degenerate.rows, degenerate.cols), content="(0, 3)")
}
```

The backend remains responsible for validating negative dimensions, preserving
`0xN` and `Nx0`, reporting invalid coordinates with `LinearAlgebraError`, and
honoring its documented ownership behavior.

## Integration Checklist

- Select only the dictionaries supported by the real storage and ownership
  model.
- Keep checked access and construction panic-free.
- Test first/last and invalid indices, empty and degenerate shapes, and
  initializer coordinate ordering.
- For persistent editing, prove that the source remains unchanged.
- For mutable editing, prove that failure performs no partial mutation.
- Test at least one generic map or conversion in both supported directions.
- Document performance characteristics such as remote access, decompression,
  or sparse materialization costs without changing the semantic contract.

Future optimized kernel dictionaries should be additional opt-in capabilities.
They must not become prerequisites for read/build interoperability.
