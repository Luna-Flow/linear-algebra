# backends/openblas Design

## Responsibilities

- Provide a concrete native-only matrix backend that can participate in the
  public `@algebra` trait ecosystem.
- Keep the backend's owned public type local to this repository as
  `BlasMatrix[T]`.
- Use OpenBLAS GEMM for matrix multiplication while keeping the rest of the
  first-pass matrix surface implemented locally in MoonBit.
- Hide OpenBLAS layout and binding details behind a repository-owned API.

## Why This Is A Wrapper Backend

This package is a trait-compatible backend wrapper.

It is not:

- a runtime backend selector
- a global backend enum
- a direct trait implementation on the foreign OpenBLAS binding types

The wrapper exists so the package owns the concrete matrix type and can attach
`@algebra` trait implementations without running into MoonBit's foreign trait /
foreign type restriction.

## Type And Target Decide Behavior

Backend choice is now determined by two things:

- type choice
  `@immut.Matrix[T]` and `@default.ImmutableDenseMatrix[T]` use the repository's
  existing dense implementations, while `@openblas.BlasMatrix[T]` uses the
  OpenBLAS-backed multiplication path
- target choice
  `backends/openblas` only participates in `native` builds

There is no runtime API for asking `@immut.Matrix` to switch to a different
backend.

## Scalar Strategy

`BLASInnerType` is intentionally backend-local. It captures the scalar-specific
pieces this wrapper needs:

- dispatch to the correct GEMM kernel
- provide a tolerance value for backend validation

The repository currently implements this trait only for `Float` and `Double`.
That matches the current OpenBLAS-backed matrix surface and avoids exposing a
misleading generic type story.

## Operation Split

- `Mul`
  delegates to OpenBLAS GEMM
- `shape`, `transpose`, `+`, `-`, `neg`
  stay as local MoonBit implementations for the first version

This split keeps the API complete enough for trait-oriented generic code without
pretending that every matrix operation must already be backed by a BLAS routine.
