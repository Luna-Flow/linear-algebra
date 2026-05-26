# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.10 - Unified Storage & API Alignment

With **v0.2.10**, the repository documentation and release metadata stay aligned to the current package manifest.

### Package Positioning

- **`immut`**: Immutable, value-oriented `Matrix`, `Vector`, and `MatrixFn` types for persistent data and explicit copy-on-update semantics.
- **`mutable`**: Execution-oriented `Matrix` and `Vector` types with in-place updates, `Transpose` views, `RowView` / `ColView`, and backend-specific implementations for `js`, `wasm`, `wasm-gc`, and `native`.
- **Shared Core, Different Execution Model**: Constructors and core algebraic operators remain aligned across packages, but mutation and access semantics are intentionally different.

### What Defines v0.2.10

- **Matrix Views**: `mutable` now exposes `RowView` and `ColView` for repeated structured row/column work without materializing copies.
- **Unified Flattened Storage**: `mutable.Matrix` now uses a shared flat `Array[T]` storage model across backends, instead of documenting backend-specific layout differences.
- **Cross-Package Consistency Checks**: Added dedicated consistency tests to keep shared `immut` / `mutable` algebraic behavior aligned.
- **Numerical Fixes**: Hardened mutable LU-based routines, including pivot-permutation handling and broader numerical corner-case behavior.
- **Immutable Core Alignment**: `immut.Vector` continues to build on the optimized core immutable vector implementation, which makes the flattened storage direction practical across the library.
- **Dedicated Wasm GC Backend**: `mutable` now includes a dedicated `wasm-gc` backend rather than treating it as a thin variation of earlier backend code paths.
- **Numeric Trait Cleanup**: Mutable numerical APIs now align more directly with `Field` / `Num` / `Tolerance` style constraints, while immutable determinant constraints were simplified.
- **Symmetric Eigen Performance**: The symmetric real eigenpath has been accelerated as part of the current release line.
- **Dependency Upgrade**: The current repository depends on `Luna-Flow/luna-generic` `0.3.0` and `moonbitlang/quickcheck` `0.14.0`.
- **Modern Moon Package Metadata**: The repository now carries `moon.mod` as the canonical package manifest format for the current toolchain generation.
- **Release Workflow Confirmation**: The publish workflow requires an explicit version input that must match `moon.mod`, keeping release metadata aligned with the canonical manifest.
- **Benchmark Harness & Dashboard**: The repository now ships a fixture-driven benchmark harness, a local web dashboard, an optional Rust baseline, and a scheduled GitHub Actions benchmark workflow.

### API Guidance & Performance

- **Core Algebraic API**: Shared operations such as `make`, `transpose`, `+`, `-`, `*`, `trace`, and matrix/vector conversions are intended to stay semantically aligned across `immut` and `mutable`.
- **Random Access**: In `mutable`, for high-performance random access, prefer `.get(i, j)` and `.set(i, j, val)` directly.
- **Structured Views**: For repeated row or column work in `mutable`, prefer `row_view()` / `col_view()` instead of relying on `matrix[row]` convenience syntax.
- **Public Surface**: Internal decomposition helpers remain implementation details. Package users should rely on the documented public matrix methods instead.

### Key Features

- **Mutable & Immutable Support**: Full `Matrix` and `Vector` suites with distinct semantics for value-oriented and execution-oriented workloads.
- **Advanced Operations**: Includes determinant, inverse, rank, Cholesky decomposition, eigen-related routines, row elimination, transpose views, and matrix/vector conversions.
- **Shared Data Model, Backend-Tuned Kernels**: `mutable` still ships backend-tuned execution paths for Native, Wasm, JS, and Wasm GC targets, but the core matrix storage model is now unified.
- **Benchmark Infrastructure**: `bench/`, `src/perf_support`, and `src/perf_runner` now form a full steady-state benchmarking subsystem for backend comparison and diagnostic replay.
- **Correctness First**: Coverage now includes immutable laws, cross-package consistency checks, determinant/rank/inverse alignment, and regression tests for numerical behavior.

### Quick Start

```moonbit
let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let imm_updated = imm.set(0, 1, 9)

let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant()
let maybe_inv = m.inverse()
let row0 = m.row_view(0).to_array()
```

### Documentation

Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

We provide documentation in multiple languages:

- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

Localized README files:

- 🇺🇸 [README.md](./README.md)
- 🇨🇳 [README.md](./doc/zh_CN/README.md)
- 🇯🇵 [README.md](./doc/ja_JP/README.md)

## Version History

| Version | Date | Status | Notes |
| --- | --- | --- | --- |
| `0.2.10` | 2026-05-27 | current package baseline | Unified flattened mutable storage, matrix views, consistency coverage, benchmark coverage, and release-process alignment |
| `0.2.9` | 2026-02-03 | published on mooncakes | Published from the earlier `3328195` release state |
| `0.2.8` | 2026-02-03 | historical baseline | Algorithms and stability milestone used as the comparison baseline for later work |

## Current Repository Highlights

- **Current Release Narrative (0.2.10)**:
  - `mutable.Matrix` is now documented around a shared flat storage model across backends.
  - `RowView` / `ColView`, cross-package consistency coverage, dedicated `wasm-gc` support, and numerical fixes are part of the current mainline story.
  - Symmetric eigen performance, trait-bound cleanup, and the full benchmark harness/dashboard workflow are part of the current repository baseline.
  - The documentation, release checklist, dependency story, benchmark workflow, and canonical `moon.mod` metadata flow are aligned to the current implementation state.

- **Algorithms & Stability (0.2.8)**:
  - Added LU- and QR-related decomposition support used by determinant, inverse, rank, and eigen routines.
  - Shifted determinant and rank behavior toward more stable elimination-based implementations.

- **Native Optimization (0.2.7)**:
  - Implemented transposition + dot-product strategy for Native matrix multiplication, outperforming naive implementations by more than 2x.
  - Optimized `make`, `new`, and `transpose` to remove expensive integer division in hot loops.

- **Performance Overhaul (0.2.4)**:
  - Optimized secondary utilities such as `mapi` and `each_row_col`.
  - Improved hybrid matrix multiplication and vector linear-combination performance.

- **Other Fixes & Renames**:
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
  - Corrected determinant behavior for `0x0` matrices.
  - Fixed copy-on-conversion behavior between vectors and matrices.

## Development

Useful local commands:

```bash
moon fmt
moon check
moon test --enable-coverage
./run_test.sh
```

`run_test.sh` exercises the `mutable` package on `wasm-gc`, `js`, `native`, and `wasm`.

## Release Checklist

Before triggering the publish workflow:

1. Bump `moon.mod` to the intended next release version before publishing.
2. Update `README.md` so the release notes and version history match the package contents.
3. Run `moon check` and `./run_test.sh`.
4. Trigger `publish-package` and enter the exact version from `moon.mod` in the workflow input.

If the workflow reports a duplicate version, the package manager already contains that version and a new version bump is required.

Contribution guidance is available in [CONTRIBUTING.md](./CONTRIBUTING.md).
