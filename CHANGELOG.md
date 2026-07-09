# Changelog

All notable repository-release changes are tracked here. The main
[`README.md`](./README.md) stays focused on the current baseline and entry
points; older release history lives in this file.

## 0.4.3 - 2026-07-09

Current repository release.

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
