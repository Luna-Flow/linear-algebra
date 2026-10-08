# linear-algebra

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache--2.0-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

`Luna-Flow/linear-algebra` is the linear-algebra layer of Luna Flow for
MoonBit. It provides dense matrices and vectors in two execution models
(immutable values and in-place buffers), numerical routines for floating-point
matrices, exact algorithms for integer matrices, and small capability layers so
that generic algorithms run on any matrix type that implements them. Every
operation that can fail at runtime has a checked form returning a structured
`LinearAlgebraError`.

## Install

```sh
moon add Luna-Flow/linear-algebra@0.5.0
```

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/immut",
  "Luna-Flow/linear-algebra/mutable",
}
```

## Example

```moonbit check
///|
test "linear-algebra in a few lines" {
  let a = @immut.Matrix::from_2d_array([[1, 1], [1, 0]])
  inspect(a.pow(10).unwrap(), content="|89, 55|\n|55, 34|")
  let m = @mutable.Matrix::from_2d_array([[4.0, 2.0], [2.0, 3.0]])
  inspect(m.determinant().unwrap(), content="8")
  inspect(m.inverse().unwrap(), content="|0.375, -0.25|\n|-0.25, 0.5|")
  inspect(m.cholesky_decomposition().unwrap(), content="|2, 0|\n|1, 1.4142135623730951|")
}
```

## Packages

| Package | Purpose |
| --- | --- |
| `immut` | immutable `Matrix`, `Vector` and lazy `MatrixFn`; exact (Bareiss) determinants and powers |
| `mutable` | in-place `Matrix` and `Vector`, row/column/transpose views; LU, inverse, rank, Cholesky, symmetric eigenvalues, power method, statistics |
| `error` | `LinearAlgebraError` and `LinearAlgebraErrorKind` for every checked API |
| `arithmetic` | scalar operation traits (`Abs`, `ApproxEq`, checked division, square root and comparison) and upstream re-exports |
| `algebra` | structure traits for whole vectors and matrices, from `MatrixShape` to `MatMulMatrix` (experimental) |
| `backends/default` | dense wrappers implementing the `algebra` traits over `immut` and `mutable` |
| `container` | storage-independent read/build/edit dictionaries and generic map, convert and transpose (experimental) |
| `container/adapters` | dictionaries for every vector and matrix type of this repository |
| `internal`, `consistency` | shared shape guards and cross-package agreement tests |
| `perf`, `perf_runner`, `perf_support` | benchmark subsystem (see `bench/README.md`) |

The native OpenBLAS backend is not part of this release: its upstream binding
does not compile with MoonBit 0.10. The source and re-enable steps are kept in
[`contrib/openblas_backend`](./contrib/openblas_backend/README.md).

## Toolchain

MoonBit with `moonc` 0.10 or newer. The module builds without warnings with
`moon check --target all` and is tested on `wasm-gc`, `js`, `wasm` and
`native`. It depends on `Luna-Flow/luna-generic` `0.3.3` and
`Luna-Flow/arithmetic` `0.2.2`.

## Documentation

The manual (API, tutorials and design notes for every package, in English,
Chinese and Japanese) is published at <https://lunaflow.cn/en/linear-algebra/>.
Its English source is [`doc/manual`](./doc/manual/index.md); every example in
it is compiled and run as a test by `src/doc_en_us`. Release history is in
[CHANGELOG.md](./CHANGELOG.md).

## Development

```sh
moon check --target all
./run_test.sh                               # default gate on all targets
LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh   # also the benchmark packages
just bench                                  # full benchmark report
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Commits follow Conventional
Commits.

## License

Apache-2.0. See [LICENSE](./LICENSE).
