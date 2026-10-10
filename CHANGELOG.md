# Changelog

All notable repository-release changes are tracked here. The main
[`README.md`](./README.md) stays focused on the current baseline and entry
points; older release history lives in this file.

## Unreleased

## 0.5.0 - 2026-10-10

Current repository release. MoonBit 0.10 migration and temporary withdrawal of
the OpenBLAS backend. This is a breaking release in the `0.x` line.

### Breaking Changes

- **Requires the MoonBit 0.10 toolchain** (`moonc` `0.10.x` or newer). The
  module uses `moon.mod` / `moon.pkg` manifests and current syntax; older
  toolchains cannot build it.
- **`backends/openblas` is temporarily withdrawn.** Its upstream binding,
  `Kaida-Amethyst/openblas` `0.1.3`, still uses the `typealias` syntax removed
  in MoonBit 0.10 (`cblas/cblas.mbt`, around lines 86, 97, and 220) and has no
  fixed release, so it no longer compiles. The `Kaida-Amethyst/openblas`
  dependency is removed from `moon.mod`, and `BlasMatrix[T]`, `BlasVector[T]`,
  and the `blas_*_ops` container adapters are no longer published. Users of
  `Luna-Flow/linear-algebra/backends/openblas` should stay on `0.4.7` or switch
  to `backends/default`. The migrated source, its documentation, and a patch
  for the upstream binding are preserved in
  [`contrib/openblas_backend`](./contrib/openblas_backend/README.md), with
  re-enable steps. The backend may come back here or be hosted by the
  `openblas.mbt` project.
- **`op_get` / `op_set` method names are gone.** Indexing is now provided by
  ordinary methods `at` / `set` (or `get` / `set` on `RowView` / `ColView`)
  annotated with `#alias("_[_]")` / `#alias("_[_]=_")`. The `x[i]` and
  `x[i] = v` syntax is unchanged; call sites that wrote `x.op_get(i)` or
  `x.op_set(i, v)` should use `x[i]` / `x.at(i)` and `x[i] = v` / `x.set(i, v)`.
- **Trait methods are promoted explicitly.** Only trait methods listed in each
  package's `extends.mbt` (`pub extend T with Trait::{m}`) remain callable with
  method syntax: operators (`add`, `sub`, `mul`, `neg`), `equal`,
  `to_string`, and `shape` on the `immut` / `mutable` matrix and vector types,
  `shape` / `transpose` on the `backends/default` matrix wrappers, and `equal`
  on the `error` types. The method forms of `not_equal`, `output`, `to_repr`,
  and `arbitrary` are **deprecated** (kept as documentation-hidden
  promotions); use `!=`, string interpolation or `Show::output`,
  `Repr(x)` / `@debug.Debug::to_repr`, and the quickcheck
  `Arbitrary::arbitrary` trait call instead. Other trait methods must be called through
  the trait (`Trait::method(x)`) or the corresponding operator.
- **`perf_support` fixture types are private.** `CaseFixtureFile`,
  `CaseFixtureInputs`, and `CaseFixtureShape` are no longer exported from
  `Luna-Flow/linear-algebra/perf_support`; use the public `Case` /
  `PreparedCase` APIs and the fixture loaders instead.

- Immutable determinant entry points (`Matrix::determinant`,
  `Matrix::unchecked_determinant`, `MatrixFn::determinant`) now require
  `DeterminantScalar` instead of `Compare + Num + Div`. Built-in `Int`,
  `Int16`, `Int64`, `BigInt`, `Float` and `Double` remain supported. Generic
  callers must add the bound; custom scalar types must select `Bareiss` or
  `PivotedLU` through the open trait.

### Added

- `@mutable.Matrix::matmul` returns a `DimensionMismatch` error for
  incompatible shapes; the unchecked kernel and the aborting `*` are unchanged
  ([#87](https://github.com/Luna-Flow/linear-algebra/issues/87)).

### Changed

- Migrated to MoonBit 0.10 (`moon.mod` / `moon.pkg` manifests, current
  syntax, zero warnings under `moon check --target all`).
- Generic code calls trait methods in trait-qualified form (`Zero::zero()`,
  `One::one()`, `@algebra.TransposeMatrix::transpose(m)`, ...).
- Contract-breach `guard` statements now abort with explicit
  `"Type::fn: reason"` messages.
- The `src/doc_en_us` documentation package no longer depends on OpenBLAS, so
  the compiled manual examples build and run on `wasm-gc`, `js`, `native`, and
  `wasm`; `run_test.sh` now includes it on all four targets. CI and publish
  workflows no longer install `libopenblas-dev`.

- Bumped `Luna-Flow/luna-generic` from `0.3.3` to `0.4.0` and
  `Luna-Flow/arithmetic` from `0.2.2` to `0.5.0`. The public interface is
  unchanged. Under luna-generic `0.4.0`, `Float::inv` and `Double::inv` abort
  with an explicit message on zero instead of a bare abort.
- The white-box tests of `mutable` convert integer fixtures with
  `@lf_alg.lift_to` instead of the deprecated
  `IntegralHomomorphism::from_integral`.

### Fixed

- Immutable `Float` and `Double` determinants now use LU with partial
  pivoting, avoiding Bareiss minor-product overflow on large triangular and
  dense inputs whose determinant is representable
  ([#93](https://github.com/Luna-Flow/linear-algebra/issues/93)). Integer
  determinants keep the Bareiss path; floating-point rounding, elimination
  growth, and pivot-product overflow or underflow remain possible.

- `@mutable.Transpose::mul` now evaluates each scalar product in the order
  required by matrix multiplication, including for non-commutative scalar
  types ([#88](https://github.com/Luna-Flow/linear-algebra/issues/88)).
- `@mutable.Matrix::eigen` for `2 x 2` input no longer aborts with "complex
  eigenvalues" on symmetric matrices with large entries, no longer merges
  eigenvalues closer than about `6e-6`, never returns a singular eigenvector
  matrix, and pairs eigenvectors with the right eigenvalues on every target
  ([#90](https://github.com/Luna-Flow/linear-algebra/issues/90)).
- `@mutable.Matrix::eigen` for `n >= 3` deflates relative to the diagonal
  instead of below an absolute `1e-11`, so matrices with small entries get
  correct eigenvalues ([#91](https://github.com/Luna-Flow/linear-algebra/issues/91)).
- The structural shortcuts of `inverse`, `cholesky_decomposition`,
  `determinant` (and, on `js`, `rank` and `eigen`) are taken only for matrices
  that have the structure exactly
  ([#92](https://github.com/Luna-Flow/linear-algebra/issues/92)).

### Documentation

- Documentation rewritten (API, tutorial and design pages) with zh_CN/ja_JP
  translations. Every package now has one page per chapter, including
  `container/adapters`, `internal`, `consistency`, `perf`, `perf_runner` and
  `perf_support`; the former per-type pages of `immut` and `mutable` are merged
  into `api/immut.md`, `api/mutable.md` and their tutorial and design
  counterparts. The design pages derive the implemented algorithms (Bareiss
  elimination, LU with partial pivoting, Cholesky, Householder tridiagonalization
  with implicit QL, the power method) with their stability and complexity, and
  a Typst attachment proves the exactness of the fraction-free determinant.
- A new `architecture.md` guide describes the package layers and dependencies.
- All manual examples use current idioms and compile as tests of
  `src/doc_en_us`.

- Brought the manual to the Luna Flow documentation standard: every API page
  opens with Purpose and Importing sections, every tutorial with an
  "I want to / Use" table, every design page has a constraints section and
  the order goal, constraints, decisions, mathematics, invariants,
  alternatives, boundaries. The overview lists the pages per package, the
  exported items, numerical caveats, reading paths and validation commands.
- Reviewed the mathematics against the code. The `mutable` design page now
  derives `PA = LU`, the growth bound, the closed-form determinant error,
  Cholesky and Sylvester's criterion, Householder reflectors, the Wilkinson
  shift and the power-method residual bound; the `immut` design page derives
  Bareiss elimination from Sylvester's identity. Corrected claims: the LU
  backward error carries a factor `n^2`, not `n`; the `eigen` backward error
  includes the absolute thresholds; `power_method` does two matrix-vector
  products per iteration; `pow` performs `floor(log2 k) + popcount(k)`
  products; a lazy `MatrixFn` power costs `(2n)^d` reads per entry;
  `checked_div` reports every zero divisor and `approx_eq` is not reflexive
  on infinities.
- Documented open defects with warnings: the `MatMulMatrix` instances of
  `backends/default` exist for scalar types that
  break the product laws
  ([#94](https://github.com/Luna-Flow/linear-algebra/issues/94)).
- Translated the revised manual into Chinese and Japanese.

## 0.4.7 - 2026-07-11

Previous release baseline. Last release that ships `backends/openblas`.

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
- Clarified that scalar-valued vector products and BLAS-style linear
  combinations (`dot`, `scale` / `scal`, `axpy`, `matvec` / `gemv`) remain
  backend methods on `backends/default` and `backends/openblas`; they were not
  promoted into new `@algebra` traits in this release.

### Changed

- Expanded the default test gate to cover `container`, `container/adapters`,
  and `backends/default` across Wasm GC, JavaScript, native, and Wasm targets.

## 0.4.6 - 2026-07-09

Previous release baseline.

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
