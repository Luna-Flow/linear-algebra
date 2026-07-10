# Changelog

All notable repository-release changes are tracked here. The main
[`README.md`](./README.md) stays focused on the current baseline and entry
points; older release history lives in this file.

## 0.4.7 - 2026-07-11

Current repository release.

### Added

- Added storage-independent vector and matrix read, build, persistent-edit,
  and mutable-edit operation dictionaries in the new `container` layer.
- Added backend-independent vector/matrix map, conversion, and matrix transpose
  algorithms with adapters for immutable, mutable, default dense, view, and
  natural OpenBLAS read/build capabilities.
- Documented capability-by-capability ecosystem adoption, adapter ownership,
  and the boundaries between structural, editing, mathematical, and future
  kernel integration.
- Added algebra integration levels covering shape, additive, transpose,
  Hadamard, and matrix-multiplication traits, including operator and ownership
  boundaries for external type authors.

### Changed

- Expanded the default test gate to cover `container`, `container/adapters`,
  and `backends/default` across Wasm GC, JavaScript, native, and Wasm targets.

## 0.4.6 - 2026-07-09

Current repository release.

### Highlights

- `backends/default` now exposes backend-local vector and matrix-vector helpers:
  `scale`, `dot`, `axpy`, and `matvec` on the dense wrapper types.
- `backends/openblas` now adds the owned `BlasVector[T]` wrapper alongside
  `BlasMatrix[T]`, with OpenBLAS-backed `dot`, `scal`, `axpy`, and `gemv`
  paths for `Float` and `Double`.
- The OpenBLAS backend remains explicit and native-only, but now covers the
  core vector and matrix-vector interaction surface instead of GEMM alone.
- Root and multilingual backend documentation now describe the live backend API
  surface, including the backend-method nature of scalar-valued vector
  operations.

## 0.4.5 - 2026-07-09

Previous release baseline.

### Highlights

- The old runtime backend-selection surface was removed from `immut`, together
  with its related tests and generated interfaces.
- `backends/openblas` is now the explicit native backend surface. It introduces
  the owned `BlasMatrix[T]` wrapper, the backend-local `BLASInnerType`
  abstraction for `Float` and `Double`, and OpenBLAS-backed matrix
  multiplication through GEMM.
- Stale backend-only public errors were pruned so the shared checked error API
  matches the live code paths again.
- The multilingual documentation baseline now matches the code: the three
  localized README entry pages, API baselines, OpenBLAS docs, and doc exposure
  symlinks all describe the same explicit-backend model.
- CI and publish workflows now install Ubuntu OpenBLAS development packages,
  and the native package configuration searches both Homebrew macOS paths and
  the default Ubuntu OpenBLAS include/library layout.

## 0.4.4 - 2026-07-09

Previous release baseline.

### Highlights

- Package metadata was aligned around the repository positioning:
  `moon.mod` kept the Apache 2.0 SPDX license field and described the package
  as trait-oriented linear algebra foundations for MoonBit.
- The repository metadata and README license presentation were aligned with the
  Apache 2.0 project baseline.
- The multilingual documentation baseline was lifted to `0.4.4`, so the
  release number stayed consistent across README files, API baselines,
  tutorials, and contributor-facing guidance.

## 0.4.3 - 2026-07-09

Previous release baseline.

### Highlights

- The README and localized READMEs now focus on the current release baseline,
  reader guidance, and package entry points, while `CHANGELOG.md` owns the
  historical release timeline.
- The documentation standard now records the README/CHANGELOG division,
  cross-language file alignment, section-order alignment, and localization
  expectations for English, Chinese, and Japanese docs.
- The Chinese and Japanese README files now follow the English structure more
  closely, and the localized `backends/default` API pages now expose the same
  section granularity as the English reference.
- The `immut/matrix` tutorial now uses the ASCII blur workflow consistently
  across languages, and several localized tutorials and design pages now use
  more natural technical wording.

## 0.4.2 - 2026-07-09

Previous release baseline.

### Highlights

- `mutable.Matrix::unchecked_matmul` now switches between the existing
  unrolled kernel and a packed-right-hand-side kernel, depending on matrix
  shape and total work.
- The packed kernel is available on Native, JS, Wasm, and Wasm GC, so larger
  dense matrix products can reuse right-hand-side columns with fewer repeated
  cache-unfriendly reads.
- Checked `mutable.Matrix` multiplication still validates dimensions first and
  then delegates to `unchecked_matmul`, so the optimized hot path stays in one
  place.
- `perf_support` and `perf_runner` now recreate missing
  `bench/datasets/cases/*.json` fixtures on demand from the tracked dataset
  registry, which keeps direct local tests and runner commands working on a
  clean checkout.
- Bulk benchmark generation still flows through
  `bench/generate_fixtures.py`, so tracked metadata and generated registries
  remain aligned.

## 0.4.1 - 2026-07-07

Previous release baseline.

### Highlights

- Mutable matrix multiplication exposes `unchecked_matmul` for validated call
  sites and benchmark hot paths.
- Matrix multiplication, LU trailing updates, and Cholesky accumulation have
  backend-aligned loop unrolling.
- Benchmark fixture documentation now makes per-case JSON generation an
  on-demand local artifact.
- Publishing uses the version in `moon.mod` directly.

## 0.4.0 - 2026-07-07

Previous release baseline. This release established the checked `0.4.x` line.

### Breaking Changes

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

### Release Narrative

- Matrix operations with runtime failure modes now return
  `Result[..., LinearAlgebraError]`.
- Legacy matrix behavior is available through explicit `unchecked_*` methods.
- `linear-algebra/error` documents the shared error vocabulary for checked
  APIs.
- `arithmetic`, `algebra`, and `backends/default` provide the new
  trait-oriented layering for generic algorithms.

## 0.3.0 - 2026-06-14

Published on mooncakes.

### Highlights

- Adopted shared `arithmetic.Sqrt`, current `luna-generic` homomorphisms, and
  ecosystem-wide numeric capability identities.
- Square-root-dependent matrix algorithms now require the shared
  `arithmetic.Sqrt` capability.
- `mutable.Sqrt` is a public re-export of `arithmetic.Sqrt`; the old
  package-local trait and scalar implementations were removed.
- Integral test fixtures and conversion helpers now use target-side
  `IntegralHomomorphism::from_integral`.
- Custom numeric types should implement capabilities in `luna-generic` and
  `arithmetic` rather than package-specific linear-algebra traits.

## 0.2.12 - 2026-06-06

Published on mooncakes.

### Highlights

- Strict bounds unification, semantic correctness fixes, benchmark diagnostics
  expansion, and documentation/audit refresh.
- Public matrix, view, and transpose accessors enforce explicit bounds
  contracts, including zero-row and zero-column edge shapes.
- `immut.Matrix` and `mutable.Matrix` are aligned on shared correctness
  semantics while preserving their value-vs-mutation execution split.
- Benchmark diagnostics and the tracked correctness audit reflect the exported
  `0.2.12` surface.

## 0.2.11 - 2026-05-27

Previous release baseline.

### Highlights

- Performance-tuned mutable kernels, dedicated wasm-gc backend,
  benchmark/reporting expansion, and API/doc alignment.
- `mutable.Matrix` now combines the shared flat storage model from `0.2.10`
  with follow-up backend kernel optimizations and a dedicated `wasm-gc`
  implementation.
- Public numerical signatures are aligned around `Field` / `Num` /
  `Tolerance`, and immutable determinant documentation matches the simplified
  post-`0.2.10` constraint set.
- The benchmark stack now includes runtime-loaded fixtures, expanded case
  metadata, richer summary reporting, a local dashboard, optional Rust
  comparison runs, and diagnostic replay via `perf_runner`.
- The release checklist, benchmark docs, package overview, and localized
  READMEs are aligned to the `0.2.11` release story.

## 0.2.10 - 2026-05-27

Previous release baseline.

### Highlights

- Unified flattened mutable storage, matrix views, consistency coverage,
  benchmark coverage, and release-process alignment.

## 0.2.9 - 2026-02-03

Published on mooncakes.

### Highlights

- Published from the earlier `3328195` release state.

## 0.2.8 - 2026-02-03

Historical baseline.

### Highlights

- Algorithms and stability milestone used as the comparison baseline for later
  work.
- Added LU- and QR-related decomposition support used by determinant, inverse,
  rank, and eigen routines.
- Shifted determinant and rank behavior toward more stable elimination-based
  implementations.

## Earlier Historical Notes

### 0.2.7

- Implemented transposition + dot-product strategy for Native matrix
  multiplication, outperforming naive implementations by more than 2x.
- Optimized `make`, `new`, and `transpose` to remove expensive integer
  division in hot loops.

### 0.2.4

- Optimized secondary utilities such as `mapi` and `each_row_col`.
- Improved hybrid matrix multiplication and vector linear-combination
  performance.

### Other Fixes And Renames

- `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
- `eachij()` -> `each_row_col()`
- Corrected determinant behavior for `0x0` matrices.
- Fixed copy-on-conversion behavior between vectors and matrices.
