# Architecture

This guide shows how the packages of `linear-algebra` depend on each other,
which layer owns which decision, and how tests and documentation are wired.
Each package's own design page explains its internals.

## Dependency graph

The table lists what each package imports (test-only imports omitted).
`luna-generic` and `arithmetic` without a prefix are the upstream modules
`Luna-Flow/luna-generic` and `Luna-Flow/arithmetic`.

| Package | Imports |
| --- | --- |
| `algebra` | nothing |
| `arithmetic` | upstream `arithmetic`, `luna-generic` |
| `error` | upstream `arithmetic` |
| `internal` | `error` |
| `immut` | `error`, `internal`, `luna-generic`, core `immut/vector` |
| `mutable` | `error`, `internal`, `luna-generic`, upstream `arithmetic` |
| `backends/default` | `algebra`, `immut`, `mutable`, `luna-generic` |
| `container` | `error` |
| `container/adapters` | `container`, `error`, `immut`, `mutable`, `backends/default` |
| `consistency` | `immut`, `mutable` (tests only) |
| `perf_support` | `mutable`, `luna-generic`, `moonbitlang/x/fs` |
| `perf` | `perf_support` |
| `perf_runner` | `perf_support`, `moonbitlang/x/fs` |

Three rules follow from it:

1. **Concrete packages do not depend on the experimental layers.** `immut` and
   `mutable` import only `error`, `internal` and the upstream scalar packages.
   They do not know `algebra` or `container`, so changes to those layers cannot
   break the concrete APIs.
2. **Bridges are leaves.** `backends/default` connects `algebra` with the
   concrete types, and `container/adapters` connects `container` with them.
   No other package imports these bridges.
3. **Capabilities are defined below implementations.** `algebra` and
   `container` define traits and records without importing any concrete type,
   so external libraries can implement them without depending on `immut` or
   `mutable`.

## Layers

| Layer | Packages | Owns |
| --- | --- | --- |
| scalar operations | `arithmetic` | names for scalar operations; no laws |
| errors | `error` | the failure vocabulary of checked APIs |
| concrete storage | `immut`, `mutable`, `internal` | representation, algorithms, bounds behaviour |
| structure | `algebra` | which whole-object operations a type supports, with laws |
| bridges | `backends/default`, `container/adapters` | evidence that the concrete types satisfy the capabilities |
| interchange | `container` | element-level read, build and edit, generic conversions |
| tooling | `consistency`, `perf`, `perf_runner`, `perf_support` | tests and benchmarks |

Backend choice is a choice of type: a program that wants the dense mutable
backend uses `@default.DenseMatrix` or `@mutable.Matrix`; there is no runtime
selector inside a matrix type.

## Targets

`mutable` keeps one source file per target for its matrix, LU, view and
transpose code (`*_native.mbt`, `*_js.mbt`, `*_wasm.mbt`, `*_wasm_gc.mbt`),
selected by `options(targets: ...)` in its `moon.pkg`. The files implement the
same specification with different loop structures; the test gate runs the
`mutable`, `container`, `backends/default` and documentation packages on all
four targets.

## Documentation and tests

- Every page of this manual is linked from `src/doc_en_us` as a `.mbt.md`
  file. Code blocks fenced as `moonbit check` compile and run as tests of that
  package; blocks fenced `moonbit nocheck` are illustrations.
- Translations are gettext catalogs in `doc/locale`, generated from the English
  pages with `lunadoc`.
- `run_test.sh` runs the default gate: `immut`, `consistency`, and on every
  target `container`, `container/adapters`, `backends/default`, `mutable` and
  `doc_en_us`. `LINEAR_ALGEBRA_TEST_BENCH=1` adds the benchmark packages.
- `CORRECTNESS_CHECKLIST.md` records the audited status of the numerical
  routines.

## Outside the module

`contrib/openblas_backend` preserves the withdrawn native OpenBLAS backend with
its own documentation and re-enable steps. It is not a package of the module,
is not built, and is not part of this manual.

Downstream libraries build on these layers; for example,
[geometry3d](https://lunaflow.cn/en/geometry3d/) uses `linear-algebra`.
