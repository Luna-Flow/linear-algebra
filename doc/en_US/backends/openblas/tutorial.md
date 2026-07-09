# backends/openblas Tutorial

## Before You Start

`backends/openblas` is `native` only. The current repository configuration
searches OpenBLAS from:

- `/opt/homebrew/opt/openblas/include`
- `/opt/homebrew/opt/openblas/lib`
- `/usr/include/x86_64-linux-gnu/openblas-pthread`
- `/usr/include/openblas`
- `/usr/lib/x86_64-linux-gnu/openblas-pthread`
- `/usr/lib/x86_64-linux-gnu`

This covers the default Homebrew layout on macOS and the default Ubuntu
OpenBLAS package layout. If OpenBLAS is not installed in one of those places,
native build and test commands for this package will fail at compile or link
time.

## Construct A `BlasMatrix`

```moonbit check
///|
test "construct BlasMatrix from a 2D array" {
  let matrix = @openblas.BlasMatrix::from_2d_array([
    [1.0F, 2.0F, 3.0F],
    [4.0F, 5.0F, 6.0F],
  ])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="3")
}
```

Use `Float` or `Double`. Those are the only scalar types that currently
implement `BLASInnerType`.

## Multiply Matrices Through OpenBLAS

```moonbit check
///|
test "BlasMatrix multiplication uses the backend matmul path" {
  let left = @openblas.BlasMatrix::from_2d_array([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
  ])
  let right = @openblas.BlasMatrix::from_2d_array([
    [7.0, 8.0],
    [9.0, 10.0],
    [11.0, 12.0],
  ])
  let product = left * right
  debug_inspect(product.to_2d_array(), content="[[58, 64], [139, 154]]")
}
```

`Mul` is the operation that goes through OpenBLAS GEMM. Dimension mismatch keeps
the same semantics as the repository's other unchecked matrix multiplication
paths: it aborts.

## Convert Between `BlasMatrix` And The Default Immutable Dense Backend

```moonbit check
///|
test "convert between OpenBLAS and default immutable dense backend" {
  let base = @default.ImmutableDenseMatrix::from_2d_array([
    [1.0F, 2.0F],
    [3.0F, 4.0F],
  ])
  let blas = @openblas.BlasMatrix::from_default(base)
  let round_trip = blas.to_default()
  debug_inspect(round_trip.inner().to_2d_array(), content="[[1, 2], [3, 4]]")
}
```

Equivalent conversion APIs also exist for the concrete immutable matrix type:

- `BlasMatrix::from_immut`
- `BlasMatrix::to_immut`

## Minimal Native Test Flow

Use native commands when exercising this backend:

```sh
moon test src/backends/openblas --target native
moon test --target native
```

If you want to depend on this package from another MoonBit package, keep the
same rule in mind: choose `BlasMatrix` explicitly and build for `native`.
