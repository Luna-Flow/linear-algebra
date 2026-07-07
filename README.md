# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.0 - Checked Matrix APIs and Layered Capabilities

This documentation tracks the **v0.4.0** repository state. This release makes
matrix failure modes explicit with checked `Result` APIs and adds the first
layered capability packages for backend-independent linear algebra code.

### Breaking Changes

The latest version on mooncakes is `0.3.0`, so these source-incompatible API
changes are released as `0.4.0`.

- `immut.Matrix::{matmul, trace, determinant, pow}` now return
  `Result[..., @error.LinearAlgebraError]`.
- `mutable.Matrix::{trace, determinant, inverse, is_invertible, mul_vec, pow,
  matrix_power, mean, variance, std_dev, max_element, min_element}` now return
  `Result[..., @error.LinearAlgebraError]`.
- The old aborting or `Option`-returning behavior remains available through the
  matching `unchecked_*` methods for callers that intentionally want the legacy
  contract.
- New code should handle `Ok` / `Err`; migration code can usually replace
  direct value calls with `.unwrap()` or the corresponding `unchecked_*` method
  where the old preconditions are already guaranteed.

### Layered Architecture

- **`arithmetic`**: Linear-algebra-facing operation capabilities. It reuses
  scalar operation traits from `Luna-Flow/luna-generic` and
  `Luna-Flow/arithmetic`, and adds small operation-only traits such as
  `ApproxEq`, `Abs`, `CheckedDiv`, `CheckedSqrt`, and `CheckedCompare`.
- **`algebra`**: Semantic mathematical structure capabilities. It re-exports
  existing Luna Flow algebraic structures and adds linear-algebra-facing
  traits such as `MatrixShape`, `AdditiveVector`, `TransposeMatrix`, and `FloatingScalarOps`.
- **`backends/default`**: The reference dense backend layer. It exposes wrapper
  types `DenseVector` / `DenseMatrix` over `mutable`, and
  `ImmutableDenseVector` / `ImmutableDenseMatrix` over `immut`.
- **Trait-driven algorithms**: New backend-independent algorithms should depend
  on the smallest capability they need, such as `MatrixShape`, `AdditiveVector`,
  `VecMulVector`, `TransposeMatrix`, or `MatMulMatrix`, not directly on one
  concrete matrix or vector type.

The default dense implementation is a backend, not the center of the ecosystem.
Algorithms should depend on minimal linear algebra traits, not concrete dense
matrix/vector types.

### Package Positioning

- **`immut`**: Immutable, value-oriented `Matrix`, `Vector`, and `MatrixFn` types for persistent data and explicit copy-on-update semantics.
- **`mutable`**: Execution-oriented `Matrix` and `Vector` types with in-place updates, `Transpose` views, `RowView` / `ColView`, and backend-specific implementations for `js`, `wasm`, `wasm-gc`, and `native`.
- **Shared Core, Different Execution Model**: Constructors and core algebraic operators remain aligned across packages, but mutation and access semantics are intentionally different.

### What Defines v0.4.0

- **Checked Matrix Contracts**: Shape, exponent, empty-matrix, and singular
  matrix failures are now represented by `LinearAlgebraError` on the checked
  matrix APIs.
- **Legacy Behavior Is Explicit**: `unchecked_*` methods preserve the previous
  aborting behavior, and `unchecked_inverse` preserves the previous
  `Option`-returning inverse contract.
- **Public Error Package**: `linear-algebra/error` exposes
  `LinearAlgebraError`, `LinearAlgebraErrorKind`, constructors, and `is_*`
  predicates for callers that need structured error handling.
- **Shared Square-Root Capability**: Numerical matrix APIs now use `Luna-Flow/arithmetic.Sqrt` instead of a package-local trait. `mutable` re-exports the shared trait for source-level discoverability.
- **Target-Side Integral Embedding**: Generic integer conversions use `IntegralHomomorphism::from_integral`, matching the current `Luna-Flow/luna-generic` algebraic model.
- **Ecosystem-Oriented Constraints**: Custom scalar types can implement the shared Luna Flow traits once and use them across compatible ecosystem packages.
- **Backend Consistency**: Native, JS, Wasm, and Wasm GC matrix implementations use the same arithmetic capability identity and explicit trait invocation.
- **Compatibility Boundary**: `Tolerance` remains a `mutable` package trait in this release; it has not yet moved to `arithmetic`.

### API Guidance & Performance

- **Core Algebraic API**: Shared operations such as `make`, `transpose`, `+`, `-`, `*`, `trace`, and matrix/vector conversions are intended to stay semantically aligned across `immut` and `mutable`.
- **Checked vs. Unchecked**: Prefer checked methods in user-facing code. Use
  `unchecked_*` only when shape and domain preconditions are already enforced by
  surrounding logic.
- **Random Access**: In `mutable`, for high-performance random access, prefer `.get(i, j)` and `.set(i, j, val)` directly.
- **Structured Views**: For repeated row or column work in `mutable`, prefer `row_view()` / `col_view()` instead of relying on `matrix[row]` convenience syntax.
- **Strict Bounds**: Public matrix, view, and transpose accessors consistently reject out-of-bounds indices, including `0xN` and `Nx0` edge cases.
- **MatrixFn Alignment**: `immut.MatrixFn` now shares the same non-negative dimension and empty-matrix semantics as the concrete matrix implementations.
- **Public Surface**: Internal decomposition helpers remain implementation details. Package users should rely on the documented public matrix methods instead.

### Key Features

- **Mutable & Immutable Support**: Full `Matrix` and `Vector` suites with distinct semantics for value-oriented and execution-oriented workloads.
- **Advanced Operations**: Includes determinant, inverse, rank, Cholesky decomposition, eigen-related routines, row elimination, transpose views, and matrix/vector conversions.
- **Shared Data Model, Backend-Tuned Kernels**: `mutable` still ships backend-tuned execution paths for Native, Wasm, JS, and Wasm GC targets, but the core matrix storage model is now unified.
- **Benchmark Infrastructure**: `bench/`, `src/perf_support`, and `src/perf_runner` now form a full steady-state benchmarking subsystem for backend comparison and diagnostic replay.
- **Correctness First**: Coverage now includes immutable laws, cross-package consistency checks, determinant/rank/inverse alignment, and regression tests for numerical behavior.
- **Auditable Public Contracts**: Bounds behavior, swap semantics, benchmark fixtures, and documentation are now tracked more explicitly as part of the repository’s correctness story.

### Benchmark Packages

- **`perf`**: Benchmark entry package used by `moon bench` for the steady-state matrix suite.
- **`perf_support`**: Public fixture metadata, case registry, runtime loaders, and checksum-oriented execution helpers for benchmark cases.
- **`perf_runner`**: Single-case diagnostic and sampling runner used for replay, local investigation, and richer benchmark artifact generation.

### Quick Start

```moonbit
let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
let imm_updated = imm.set(0, 1, 9)

let m = @mutable.Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
m.set(0, 1, 9.0)

let det = m.determinant().unwrap()
let inv = m.inverse().unwrap()
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
| `0.4.0` | 2026-07-07 | current repository release | Introduced checked matrix APIs, structured linear-algebra errors, layered capability packages, and default backend wrappers |
| `0.3.0` | 2026-06-14 | published on mooncakes | Adopted shared `arithmetic.Sqrt`, current `luna-generic` homomorphisms, and ecosystem-wide numeric capability identities |
| `0.2.12` | 2026-06-06 | published on mooncakes | Strict bounds unification, semantic correctness fixes, benchmark diagnostics expansion, and documentation/audit refresh |
| `0.2.11` | 2026-05-27 | previous release baseline | Performance-tuned mutable kernels, dedicated wasm-gc backend, benchmark/reporting expansion, and API/doc alignment |
| `0.2.10` | 2026-05-27 | previous release baseline | Unified flattened mutable storage, matrix views, consistency coverage, benchmark coverage, and release-process alignment |
| `0.2.9` | 2026-02-03 | published on mooncakes | Published from the earlier `3328195` release state |
| `0.2.8` | 2026-02-03 | historical baseline | Algorithms and stability milestone used as the comparison baseline for later work |

## Current Repository Highlights

- **Current Release Narrative (0.4.0)**:
  - Matrix operations with runtime failure modes now return `Result[..., LinearAlgebraError]`.
  - Legacy matrix behavior is available through explicit `unchecked_*` methods.
  - `linear-algebra/error` documents the shared error vocabulary for checked APIs.
  - `arithmetic`, `algebra`, and `backends/default` provide the new trait-oriented layering for generic algorithms.

- **Previous Release Narrative (0.3.0)**:
  - Square-root-dependent matrix algorithms now require the shared `arithmetic.Sqrt` capability.
  - `mutable.Sqrt` is a public re-export of `arithmetic.Sqrt`; the old package-local trait and scalar implementations were removed.
  - Integral test fixtures and conversion helpers now use target-side `IntegralHomomorphism::from_integral`.
  - Custom numeric types should implement capabilities in `luna-generic` and `arithmetic` rather than package-specific linear-algebra traits.

- **Earlier Release Narrative (0.2.12)**:
  - Public matrix, view, and transpose accessors enforce explicit bounds contracts, including zero-row and zero-column edge shapes.
  - `immut.Matrix` and `mutable.Matrix` are aligned on shared correctness semantics while preserving their value-vs-mutation execution split.
  - Benchmark diagnostics and the tracked correctness audit reflect the exported `0.2.12` surface.

- **Earlier Release Narrative (0.2.11)**:
  - `mutable.Matrix` now combines the shared flat storage model from `0.2.10` with follow-up backend kernel optimizations and a dedicated `wasm-gc` implementation.
  - Public numerical signatures are aligned around `Field` / `Num` / `Tolerance`, and immutable determinant documentation matches the simplified post-`0.2.10` constraint set.
  - The benchmark stack now includes runtime-loaded fixtures, expanded case metadata, richer summary reporting, a local dashboard, optional Rust comparison runs, and diagnostic replay via `perf_runner`.
  - The release checklist, benchmark docs, package overview, and localized READMEs are aligned to the `0.2.11` release story.

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

`run_test.sh` runs the repository test suite: `immut`, `consistency`, `perf_support`, and `perf_runner`, plus `mutable` on `wasm-gc`, `js`, `native`, and `wasm`.

## Release Checklist

Before triggering the publish workflow:

1. Bump `moon.mod` to the intended next release version before publishing.
2. Update `README.md` so the release notes and version history match the package contents.
3. Run `moon check` and `./run_test.sh`; both are required before publishing.
4. Trigger `publish-package`; it will publish the version currently declared in `moon.mod`.

If the workflow reports a duplicate version, the package manager already contains that version and a new version bump is required.

Contribution guidance is available in [CONTRIBUTING.md](./CONTRIBUTING.md).
