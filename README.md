# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

Linear algebra support for MoonBit, maintained as part of LunaFlow.

Current package version: `0.2.9`

## Overview

This repository provides two matrix/vector packages with intentionally different execution models:

- `Luna-Flow/linear-algebra/immut`: immutable, value-oriented matrices and vectors.
- `Luna-Flow/linear-algebra/mutable`: mutation-oriented matrices and vectors with backend-specific implementations.

They share the same core algebraic direction for constructors and basic operators, but they do not promise identical access semantics or the same performance profile.

## Package Split

### `immut`

Use `immut` when you want persistent values and explicit copy-on-update behavior.

- Dense immutable `Matrix` and `Vector`
- Functional `MatrixFn`
- Core algebraic operations such as `map`, `transpose`, `scale`, `pow`, `trace`, `determinant`, `swap_rows`, and `swap_cols`
- Conversions between arrays, vectors, row matrices, column matrices, and scaled matrices

### `mutable`

Use `mutable` when you want in-place updates and higher-performance execution paths.

- Mutable `Matrix` and `Vector`
- `Transpose` views
- `RowView` and `ColView` for repeated structured row/column access
- Advanced numerical routines such as `determinant`, `inverse`, `rank`, `cholesky_decomposition`, `eigen`, and `power_method`
- Backend-specific implementations for `js`, `wasm`, `wasm-gc`, and `native`

## API Guidance

- Shared operations such as `make`, `transpose`, `+`, `-`, `*`, `trace`, and matrix/vector conversions are intended to stay semantically aligned across `immut` and `mutable`.
- `immut` keeps updates explicit: methods like `set`, `swap_rows`, and `swap_cols` return new values.
- `mutable` is optimized around direct element access and structural views. For hot paths, prefer `.get(i, j)` and `.set(i, j, value)`.
- In `mutable`, prefer `row_view()` / `col_view()` when you repeatedly work on one row or column. Treat `matrix[row]` as convenience syntax rather than the primary performance API.
- Internal decomposition helpers are intentionally not part of the public API. Public matrix methods expose the supported numerical operations directly.

## Installation

```bash
moon add Luna-Flow/linear-algebra
```

## Quick Start

### Immutable package

```moonbit
let a = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let b : @immut.Matrix[Int] = @immut.Matrix::identity(2)
let c = a * b
let d = a.set(0, 1, 9)
let column = @immut.Vector::from_array([1, 1]).to_col_matrix()
let product = c * column
```

### Mutable package

```moonbit
let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant()
let maybe_inv = m.inverse()
let row0 = m.row_view(0).to_array()
```

## Documentation

API documentation is published on [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

Repository docs are maintained in:

- `doc/en_US`
- `doc/zh_CN`
- `doc/ja_JP`

## What Changed Since 0.2.8

The `0.2.9` line includes the following real changes after the `0.2.8` baseline:

- `mutable.Matrix` construction and backend-specialized execution paths were further optimized, including follow-up decomposition cleanup.
- `mutable` gained `RowView` and `ColView`, making repeated row/column work explicit without materializing copies.
- Cross-package consistency tests were added to keep shared `immut`/`mutable` algebraic behavior aligned.
- Immutable matrix semantics were corrected in edge cases, and immutable vector storage contracts were tightened.
- Mutable LU-based numerical routines were fixed to preserve pivot permutations correctly and to behave more robustly around numerical corner cases.
- Property-based and regression coverage expanded substantially for immutable behavior, determinant/rank/inverse laws, and cross-package invariants.
- Public docs were rewritten to match the real API contracts and package semantics more closely.
- MoonBit dependencies were upgraded:
  - `Luna-Flow/luna-generic`: `0.2.2` -> `0.2.3`
  - `moonbitlang/quickcheck`: `0.9.10` -> `0.14.0`
- The old in-repo benchmark package and helper scripts were removed from the maintained surface.

## Development

Useful local commands:

```bash
moon fmt
moon check
moon test --enable-coverage
./run_test.sh
```

`run_test.sh` exercises the `mutable` package on `wasm-gc`, `js`, `native`, and `wasm`.

Contribution guidance is available in [CONTRIBUTING.md](./CONTRIBUTING.md).
