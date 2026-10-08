# OpenBLAS backend (temporarily withdrawn)

[简体中文](./README.zh_CN.md) | [日本語](./README.ja_JP.md)

This directory preserves the former `Luna-Flow/linear-algebra/backends/openblas`
package: the native-only OpenBLAS backend that exposed `BlasMatrix[T]` and
`BlasVector[T]` for `Float` and `Double`, using OpenBLAS GEMM for matrix
multiplication and BLAS `dot` / `scal` / `axpy` / `gemv` kernels for backend
methods, plus natural `container` read/build adapters.

It lives outside `src/`, so it is **not built, tested, or published** with the
module. Everything else in `Luna-Flow/linear-algebra` is unaffected.

## Why it was withdrawn

The backend depends on `Kaida-Amethyst/openblas` `0.1.3` (the latest published
version). That package still uses the `typealias` declaration syntax that
MoonBit 0.10 removed, so it no longer parses. The failing declarations are in
`cblas/cblas.mbt`:

| Line | Declaration |
| --- | --- |
| ~86 | `pub typealias FuncRef[(Int, VoidPtr, Int) -> Unit] as Openblas_dojob_callback` |
| ~97 | `pub typealias FuncRef[(Int, Openblas_dojob_callback, Int, Int, VoidPtr, Int) -> Unit] as Openblas_threads_callback` |
| ~220 | `pub typealias CBLAS_ORDER as CBLAS_LAYOUT` |

Because a parse error in a dependency fails the whole native build, keeping the
dependency in `moon.mod` broke `moon check --target all` for the entire module,
and it forced the `src/doc_*` documentation packages (which imported the
backend for the OpenBLAS doc pages) to be native-only. Withdrawing the backend
lets every remaining package, including the doc packages, build and test on
`wasm-gc`, `js`, `native`, and `wasm`.

No upstream release fixes this yet.

## Contents

- `src/` — the package sources as of the MoonBit 0.10 migration
  (`types.mbt`, `impl_openblas.mbt`, `container_adapters.mbt`,
  `extends.mbt` with the explicit method promotions, `openblas_wbtest.mbt`,
  and `moon.pkg` with the native link flags).
- `doc/{en_US,zh_CN,ja_JP}/{api,design,tutorial}.md` — the former
  `doc/<locale>/backends/openblas/*` pages, marked as withdrawn.
- `openblas_0.1.3_typealias.patch` — a patch for `cblas/cblas.mbt` of
  `Kaida-Amethyst/openblas` `0.1.3` that rewrites the three declarations to
  `pub type Alias = Target`.

The migrated sources were verified against a locally patched copy of
`Kaida-Amethyst/openblas` `0.1.3`: `moon check --target native` reported no
warnings for the backend, its 15 native tests passed, and the 12 compiled
examples in the doc pages passed.

## How to re-enable

Once an `openblas` binding that compiles with MoonBit 0.10 is available (for
example an upstream release containing the patch above):

1. Move the package back: `mv contrib/openblas_backend/src src/backends/openblas`.
2. Re-add the dependency to `moon.mod`, for example
   `"Kaida-Amethyst/openblas@<fixed version>"`, and run `moon update`.
3. Restore the docs to `doc/<locale>/backends/openblas/` (drop the "withdrawn"
   banner). To keep the general `src/doc_*` packages buildable on every target,
   expose the OpenBLAS pages through a separate native-only doc package
   (`supported_targets = "native"` plus the link options from `src/moon.pkg`)
   instead of re-adding `backends/openblas` to `src/doc_en_us`,
   `src/doc_zh_cn`, and `src/doc_ja_jp`.
4. Restore the CI steps in `.github/workflows/ci.yml` and `publish.yml`:
   `sudo apt-get install -y libopenblas-dev` and
   `moon test src/backends/openblas --target native`.
5. Update `README.md`, `doc/*/README.md`, `doc/*/container/{api,design}.md`,
   and `CHANGELOG.md` to advertise the backend again.

To try it locally before an upstream fix exists, re-enable as above, run
`moon check` once so the dependency is fetched, then patch the downloaded
copy (local experiments only; never publish against a patched `.mooncakes`):

```sh
patch .mooncakes/Kaida-Amethyst/openblas/cblas/cblas.mbt \
  < contrib/openblas_backend/openblas_0.1.3_typealias.patch
```

The backend also needs a system OpenBLAS (`brew install openblas` on macOS,
`libopenblas-dev` on Debian/Ubuntu).

## Hosting it elsewhere

An alternative is to hand the backend over to the `openblas.mbt` project
itself, so that the binding and its `linear-algebra` integration are released
together. In that layout the OpenBLAS package would depend on
`Luna-Flow/linear-algebra` (`algebra`, `container`, `backends/default`), and
this repository would only link to it.
