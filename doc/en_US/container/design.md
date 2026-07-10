# Container Capability Design

## Mathematical and Structural Capabilities

The `algebra` package describes mathematical behavior such as addition,
transpose, and multiplication. The `container` package describes structural
behavior: shape observation, checked element access, construction, and the two
distinct editing models. A type may implement either layer without claiming
the other.

Explicit operation dictionaries represent the relationship between container
type, element type, and operation. This is clearer than forcing the
multi-parameter relationship into a global trait and lets one external type
publish several scalar-specific or policy-specific dictionaries.

The [ecosystem integration guide](./integration.md) defines the supported
adoption levels and adapter ownership rules for external libraries.

## Ownership and Editing

Persistent editing returns a new value and must preserve the source even when
the implementation uses shared backing storage. Mutable editing changes the
supplied container and returns `Unit` inside the checked result. Keeping these
records separate prevents generic code from confusing copying with mutation.

Generic `insert`, `delete`, `create`, and `remove` are absent. Removing a sparse
entry, setting a value to zero, deleting a row, and resizing a matrix are
different operations and must remain separate optional capabilities.

## Dependency Direction

`container` depends only on `error`. `container/adapters` depends on the core
capability package and the dense implementations. OpenBLAS depends on the core
package directly and remains native-only. Neither `algebra` nor the concrete
dense implementations depend on the adapter package.

## Future Kernels

A future `MatrixKernelOps[M, T]` may group checked read/write, row swap, row
scale, and scaled-row addition for elimination algorithms. It should be an
optional dictionary layered beside read/build, not a requirement added to
them.

Sparse matrices can provide read/build dictionaries that interpret absent
entries according to their own representation. Views can provide read/edit
without construction.
