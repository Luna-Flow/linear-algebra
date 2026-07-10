# `linear-algebra/backends/openblas`

API baseline for `Luna-Flow/linear-algebra/backends/openblas` in the current
`0.4.7` repository state.

## Purpose

`backends/openblas` provides owned native-only matrix and vector backend
wrappers. Matrix multiplication delegates to OpenBLAS GEMM, while vector and
matrix-vector helpers delegate to the matching BLAS kernels.

This package is separate from `@immut.Matrix`. There is no runtime backend
selector in `immut`; backend choice is now expressed by the concrete matrix type
you use and the compilation target you build for.

## Platform Constraint

- Supported target: `native`
- Unsupported targets: `js`, `wasm`, `wasm-gc`
- Current repository link configuration searches both
  `/opt/homebrew/opt/openblas/include` and `/opt/homebrew/opt/openblas/lib`
  for Homebrew on macOS, and
  `/usr/include/x86_64-linux-gnu/openblas-pthread`,
  `/usr/include/openblas`,
  `/usr/lib/x86_64-linux-gnu/openblas-pthread`, and
  `/usr/lib/x86_64-linux-gnu`
  for the default Ubuntu OpenBLAS package layout

## `BLASInnerType`

`BLASInnerType` is a backend-local trait implemented only for `Float` and
`Double`.

It owns the scalar-specific pieces required by the backend:

- `tolerance()`
  returns the comparison tolerance used by backend tests and result checks.
- `dot(length, left, right)`
  dispatches to `cblas_sdot` or `cblas_ddot`.
- `scal(length, alpha, data)`
  dispatches to `cblas_sscal` or `cblas_dscal`.
- `axpy(length, alpha, x, y)`
  dispatches to `cblas_saxpy` or `cblas_daxpy`.
- `gemm(m, n, k, left, right)`
  dispatches matrix multiplication to the matching OpenBLAS kernel:
  `cblas_sgemm` for `Float` and `cblas_dgemm` for `Double`.
- `gemv(row, col, matrix, vector)`
  dispatches matrix-vector multiplication to `cblas_sgemv` or `cblas_dgemv`.

`BlasMatrix[T]` and `BlasVector[T]` public construction and conversion APIs require
`T : BLASInnerType`, so the backend does not expose a half-open “constructible
for any `T` but only operable for some `T`” surface.

## `BlasVector[T]`

Owned native vector wrapper for the OpenBLAS backend.

### Constructors, Conversions, And Accessors

- `BlasVector::from_immut(inner : @immut.Vector[T]) -> BlasVector[T]`
- `BlasVector::from_default(inner : @default.ImmutableDenseVector[T]) -> BlasVector[T]`
- `BlasVector::from_array(data : Array[T]) -> BlasVector[T]`
- `BlasVector::make(length : Int, value : T) -> BlasVector[T]`
- `to_immut(self) -> @immut.Vector[T]`
- `to_default(self) -> @default.ImmutableDenseVector[T]`
- `to_array(self) -> Array[T]`
- `length(self) -> Int`
- `op_get(self, index : Int) -> T`

### Trait Coverage

`BlasVector[T]` currently implements:

- `@algebra.VectorShape`
- `@algebra.AdditiveVector`
- `Add`, `Neg`, `Sub`
- `Show`

It does **not** implement `@algebra.VecMulVector`. BLAS-style `scale`, `dot`,
and `axpy` are exposed as backend methods rather than new structure traits.

### Backend Methods

- `BlasVector::scale(self, scalar : T) -> BlasVector[T]`
- `BlasVector::dot(self, other : BlasVector[T]) -> T`
- `BlasVector::axpy(self, alpha : T, other : BlasVector[T]) -> BlasVector[T]`

## `BlasMatrix[T]`

```moonbit check
///|
test "BlasMatrix stores shape and values" {
  let matrix = @openblas.BlasMatrix::from_2d_array([[1.0F, 2.0F], [3.0F, 4.0F]])
  inspect(matrix.row(), content="2")
  inspect(matrix.col(), content="2")
}
```

`BlasMatrix[T]` is the owned concrete backend matrix type for this package.
Internally it stores:

- `row : Int`
- `col : Int`
- a contiguous `FixedArray[T]` buffer

The public mental model stays row-major. Layout details needed by OpenBLAS stay
inside the backend implementation.

### Constructors And Conversions

- `BlasMatrix::from_immut(inner : @immut.Matrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_default(inner : @default.ImmutableDenseMatrix[T]) -> BlasMatrix[T]`
- `BlasMatrix::from_2d_array(data : Array[Array[T]]) -> BlasMatrix[T]`
- `BlasMatrix::new(row : Int, col : Int, value : T) -> BlasMatrix[T]`
- `to_immut(self) -> @immut.Matrix[T]`
- `to_default(self) -> @default.ImmutableDenseMatrix[T]`
- `to_2d_array(self) -> Array[Array[T]]`

### Accessors

- `row(self) -> Int`
- `col(self) -> Int`
- `to_array(self) -> Array[T]`

### Backend Methods

- `BlasMatrix::matvec(self, vector : BlasVector[T]) -> BlasVector[T]`
  multiplies the matrix by an OpenBLAS backend vector through GEMV.

## Trait Implementations

`BlasMatrix[T]` currently implements:

- `@algebra.MatrixShape`
- `@algebra.TransposeMatrix`
- `@algebra.AdditiveMatrix`
- `@algebra.MatMulMatrix`
- `Add`, `Neg`, `Sub`, `Mul`
- `Show`

Behavior is split intentionally:

- `Mul` uses OpenBLAS GEMM through `BLASInnerType::gemm`.
- `matvec` uses OpenBLAS GEMV through `BLASInnerType::gemv`.
- `shape`, `transpose`, `+`, `-`, and unary `-` are implemented locally in
  MoonBit inside this backend package.

## Boundary

This package exposes an owned trait-compatible backend wrapper. It does not:

- add a runtime backend enum
- retrofit traits directly onto third-party OpenBLAS binding types
- expose raw OpenBLAS handle types in the public API
