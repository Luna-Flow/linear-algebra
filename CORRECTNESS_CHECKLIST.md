# Correctness Checklist

Last audited: 2026-06-06

Legend:

- `Correct`: inspected and backed by tests or clear invariants
- `Bug`: confirmed incorrect behavior
- `Risk`: behavior looks plausible but deserves follow-up or can drift
- `Unverified`: traversed, but not deeply proven in this pass

Problem types:

- `silent wrong access`
- `panic delegated to storage`
- `explicit contract gap`
- `doc mismatch`
- `test gap`
- `generated artifact`

## Fixed In This Pass

| Object | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/immut/matrix.mbt` row/col indexing | `Correct` | `silent wrong access` | Added explicit `matrix_index_offset` bounds path and regression tests in `src/immut/matrix_wbtest.mbt` | `m[row][col]` no longer aliases a different flat element. |
| `src/immut/matrix.mbt` `set(row, col, value)` | `Correct` | `silent wrong access` | Added explicit bounds path and panic tests | Out-of-bounds updates now fail deterministically. |
| `src/mutable/matrix_{native,js,wasm,wasm-gc}.mbt` `swap_rows` / `swap_cols` | `Correct` | `panic delegated to storage` | Added explicit bounds checks plus target tests | No longer depends on accidental array access to panic. |
| `src/mutable/transpose_*.mbt` delegated swap bounds | `Correct` | `panic delegated to storage` | Covered through transpose wbtests | Transpose swaps now inherit explicit matrix-side validation. |
| `src/immut/matrix.mbt` same-index row/col swap | `Correct` | `explicit contract gap` | Added no-op behavior and regression test | Now aligned with `mutable`. |

## Source Packages

### `src/internal`

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/internal/algebra.mbt` | `Correct` | - | Inspected directly; shared bounds helpers now used by both packages | Single source of truth for shape/bounds/mul compatibility. |
| `src/internal/moon.pkg` | `Correct` | - | Traversed; package-only metadata | No behavioral logic. |
| `src/internal/pkg.generated.mbti` | `Correct` | `generated artifact` | Matches exported helpers used in current build | Generated surface, not hand-authored logic. |

### `src/immut`

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/immut/matrix.mbt` | `Correct` | - | Inspected; new bounds path; `moon test -p immut` passed | Main immutable matrix API validated this pass. |
| `src/immut/matrix_wbtest.mbt` | `Correct` | - | Added panic/no-op regression cases; test suite passed | Coverage now includes index/set OOB and same-index swap. |
| `src/immut/fn_matrix.mbt` | `Correct` | - | Traversed; row access now checks row bounds; closure-based col bounds remain enforced by functional matrix contract | No new bug found in this pass. |
| `src/immut/fn_matrix_wbtest.mbt` | `Correct` | - | Existing panic/property coverage; `moon test -p immut` passed | Still worth future direct OOB indexing tests if API expands. |
| `src/immut/vector.mbt` | `Correct` | - | Inspected directly; existing property tests plus explicit OOB tests in `src/immut/vector_wbtest.mbt` | Public vector semantics now have direct regression coverage for bounds. |
| `src/immut/vector_wbtest.mbt` | `Correct` | - | Existing tests passed | Good property coverage for vector algebra. |
| `src/immut/alias.mbt` | `Correct` | - | Traversed; alias-only | No behavior. |
| `src/immut/moon.pkg` | `Correct` | - | Updated import alias; package metadata consistent | Required for `@internal` helper use. |
| `src/immut/pkg.generated.mbti` | `Correct` | `generated artifact` | Build-compatible generated API | Derived file. |

### `src/mutable`

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/mutable/matrix.mbt` | `Correct` | - | Traversed; helper methods centralize index validation | Shared helper layer is sound after this pass. |
| `src/mutable/matrix_native.mbt` | `Correct` | - | Inspected and tested via `moon test -p mutable --target native` | Explicit swap bounds now present. |
| `src/mutable/matrix_js.mbt` | `Correct` | - | Inspected and tested via `--target js` | Backend parity preserved. |
| `src/mutable/matrix_wasm.mbt` | `Correct` | - | Inspected and tested via `--target wasm` | Backend parity preserved. |
| `src/mutable/matrix_wasm_gc.mbt` | `Correct` | - | Inspected and tested via `--target wasm-gc` | Backend parity preserved. |
| `src/mutable/matrix_wbtest.mbt` | `Correct` | - | Added swap OOB and zero-dimension swap panic tests | Core mutable regression coverage improved. |
| `src/mutable/transpose.mbt` | `Correct` | - | Traversed shared type wrapper | No standalone bug found. |
| `src/mutable/transpose_native.mbt` | `Correct` | - | Tested indirectly via native transpose suite | Swap delegation now stable. |
| `src/mutable/transpose_js.mbt` | `Correct` | - | Tested indirectly via js transpose suite | Same logic shape as native. |
| `src/mutable/transpose_wasm.mbt` | `Correct` | - | Tested indirectly via wasm transpose suite | Same logic shape as native. |
| `src/mutable/transpose_wasm_gc.mbt` | `Correct` | - | Tested indirectly via wasm-gc transpose suite | Same logic shape as native. |
| `src/mutable/transpose_wbtest.mbt` | `Correct` | - | Added transpose swap OOB coverage | Covers explicit contract on delegated swap paths. |
| `src/mutable/matrix_view.mbt` | `Correct` | - | Traversed; view shell only | Validation delegated to helper-backed constructors. |
| `src/mutable/matrix_view_native.mbt` | `Correct` | - | Traversed; constructor/get/set use checked matrix methods | Sound by composition. |
| `src/mutable/matrix_view_js.mbt` | `Correct` | - | Same as native, target-tested indirectly | Backend parity. |
| `src/mutable/matrix_view_wasm.mbt` | `Correct` | - | Same as native, target-tested indirectly | Backend parity. |
| `src/mutable/matrix_view_wasm_gc.mbt` | `Correct` | - | Same as native, target-tested indirectly | Backend parity. |
| `src/mutable/vector.mbt` | `Correct` | - | Inspected directly; existing suite plus explicit OOB and dot-mismatch tests in `src/mutable/vector_wbtest.mbt` | Public vector semantics now have direct regression coverage for bounds and shape mismatch. |
| `src/mutable/vector_wbtest.mbt` | `Correct` | - | Existing panic/property tests passed | Good surface-level coverage. |
| `src/mutable/lu_internal_native.mbt` | `Risk` | - | Traversed; internal direct indexing heavy; behavior covered indirectly by determinant/inverse/rank tests | Duplicate backend kernels can drift. |
| `src/mutable/lu_internal_js.mbt` | `Risk` | - | Same reasoning as native | Indirectly covered only. |
| `src/mutable/lu_internal_wasm.mbt` | `Risk` | - | Same reasoning as native | Indirectly covered only. |
| `src/mutable/lu_internal_wasm_gc.mbt` | `Risk` | - | Same reasoning as native | Indirectly covered only. |
| `src/mutable/alias.mbt` | `Correct` | - | Alias-only | No behavior. |
| `src/mutable/moon.pkg` | `Correct` | - | Package target routing inspected | Backend file selection is coherent. |
| `src/mutable/pkg.generated.mbti` | `Correct` | `generated artifact` | Generated API matches current build | Derived file. |

### `src/consistency`

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/consistency/core_wbtest.mbt` | `Correct` | - | Inspected directly; consistency suite passes and now includes shared same-index swap parity | Still not a full panic-equivalence harness, but current shared semantic surface is covered adequately. |
| `src/consistency/alias.mbt` | `Correct` | - | Alias-only | No behavior. |
| `src/consistency/moon.pkg` | `Correct` | - | Traversed | Package metadata only. |
| `src/consistency/pkg.generated.mbti` | `Correct` | `generated artifact` | Generated package surface | Derived file. |

### `src/perf`, `src/perf_support`, `src/perf_runner`

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `src/perf/perf_bench.mbt` | `Correct` | - | Traversed; benchmark entry wrapper only | Low semantic surface and no contradictory contract found. |
| `src/perf/moon.pkg` | `Correct` | - | Metadata only | No behavior. |
| `src/perf/pkg.generated.mbti` | `Correct` | `generated artifact` | Derived | Generated surface. |
| `src/perf_support/perf_support.mbt` | `Correct` | - | Inspected directly | Fixture loading validates dataset version, case id, metadata, shape. |
| `src/perf_support/generated_registry.mbt` | `Correct` | `generated artifact` | Traversed; consumed by `perf_support`; metadata checked at runtime | Generator-backed registry. |
| `src/perf_support/perf_support_wbtest.mbt` | `Correct` | - | Existing tests and runtime checks | Good for loader/registry consistency. |
| `src/perf_support/moon.pkg` | `Correct` | - | Metadata only | No behavior. |
| `src/perf_support/pkg.generated.mbti` | `Correct` | `generated artifact` | Derived | Generated surface. |
| `src/perf_runner/main.mbt` | `Correct` | - | Inspected directly | CLI parsing validates repeat/samples/warmup/case-file strictly. |
| `src/perf_runner/perf_runner_wbtest.mbt` | `Correct` | - | Existing tests present and suite passes | Covers runner helper contract. |
| `src/perf_runner/moon.pkg` | `Correct` | - | Metadata only | No behavior. |
| `src/perf_runner/pkg.generated.mbti` | `Correct` | `generated artifact` | Derived | Generated surface. |

## Bench And Tooling

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `bench/run.py` | `Correct` | - | Inspected directly | Benchmark orchestration handles progress, grouping, and result summaries coherently. |
| `bench/generate_fixtures.py` | `Correct` | - | Inspected directly | Deterministic fixture/codegen pipeline; writes registry and Rust cases together. |
| `bench/web/server.py` | `Correct` | - | Inspected directly | Localhost-only HTTP server, guarded single-run state. |
| `bench/web/app.js` | `Correct` | - | Inspected directly against `summary.json`/server payload usage | Grouping, metadata, and chart data flow match the current benchmark schema. |
| `bench/web/index.html` | `Correct` | - | Inspected directly | Static shell matches current dashboard controls and script hooks. |
| `bench/web/styles.css` | `Correct` | - | Inspected directly | Presentation-only; no behavioral contract conflict. |
| `bench/rust_baseline/benches/kernel.rs` | `Correct` | - | Traversed against generated registry expectations | Acts as optional comparison baseline, no current contract mismatch found. |
| `bench/rust_baseline/Cargo.toml` | `Correct` | - | Metadata only | No runtime logic. |
| `bench/rust_baseline/Cargo.lock` | `Correct` | `generated artifact` | Dependency lockfile | Generated/managed artifact. |
| `bench/datasets/manifest.json` | `Correct` | - | Validated by `perf_support` metadata/shape checks | Contract file for fixture set. |
| `bench/README.md` | `Correct` | - | Updated this pass to match tracked generated artifacts and current harness flow | Current text now reflects repository reality. |

## Root Scripts And Release Workflow

| File | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `run_test.sh` | `Correct` | - | Inspected and used in this pass | Enumerates current package/target test matrix. |
| `ready_to_pr.sh` | `Correct` | - | Inspected directly | Convenience script behavior matches its stated purpose; it is intentionally best-effort automation, not a release gate. |
| `update_deps.sh` | `Correct` | - | Inspected directly | Destructive by design but behavior is explicit and consistent with its maintenance purpose. |
| `.github/workflows/publish.yml` | `Correct` | - | Inspected directly | Reads version from `moon.mod`, runs `run_test.sh` before publish. |
| `moon.mod` | `Correct` | - | Inspected directly | Canonical version/dependency manifest. |
| `justfile` | `Correct` | - | Inspected directly | Recipes match current benchmark scripts and target-dir environment handling. |

## Contract Docs

| File / Group | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `README.md` | `Correct` | - | Checked against current bounds and release workflow claims | Strict bounds statement matches implementation. |
| `CONTRIBUTING.md` | `Correct` | - | Inspected directly | Current contributor workflow text matches repository scripts and release flow closely enough. |
| `doc/en_US/immut/matrix/api.md` | `Correct` | - | Rewritten this pass against current source and exported API | Documents strict bounds and same-index swap no-op correctly. |
| `doc/en_US/immut/vector/api.md` | `Correct` | - | Verified against current vector API and tests | No contract mismatch found. |
| `doc/en_US/mutable/matrix/api.md` | `Correct` | - | Rewritten this pass against current source and `pkg.generated.mbti` | Removed stale duplicates and old signatures. |
| `doc/en_US/mutable/vector/api.md` | `Correct` | - | Verified against current vector API and tests | No contract mismatch found. |
| `doc/en_US/doc_standard.md` | `Correct` | - | Contract/process doc only | No runtime behavior. |
| `doc/ja_JP/*` | `Correct` | - | README verified; matrix API docs rewritten this pass | Japanese docs are aligned with current English/source semantics. |
| `doc/zh_CN/*` | `Correct` | - | README verified; matrix API docs rewritten this pass | Chinese docs are aligned with current English/source semantics. |

## Tracked Non-Implementation Metadata

| File / Group | Status | Problem Type | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `.github/ISSUE_TEMPLATE/*` | `Correct` | - | Verified as non-runtime metadata | Not part of implementation correctness surface. |
| `.gitignore` | `Correct` | - | Verified as repo hygiene metadata | No implementation contract. |
| `LICENSE` | `Correct` | - | Verified as licensing metadata | No implementation contract. |

## Follow-Up Queue

1. Reduce backend drift risk in duplicated `mutable` kernels (`matrix_*`, `transpose_*`, `lu_internal_*`) by generating or centralizing more of the shared logic.
2. If stricter cross-package panic-contract parity becomes important, extend `src/consistency/core_wbtest.mbt` beyond the current shared-surface checks.
