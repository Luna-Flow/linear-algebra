# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.7 - Native Performance Breakthrough

With **v0.2.7**, we have pushed the limits of the Native backend performance.

### High-Performance Design
- **Native Transpose Optimization**: Matrix multiplication on Native backend now utilizes a transposition-based strategy, achieving **>200% speedup** for large matrices compared to naive methods.
- **Zero-Overhead Construction**: `Matrix::make` and `Matrix::new` rewritten to eliminate all division and modulo operations during initialization.
- **Hybrid Matrix Multiplication**: Automatically switches between `i-j-k` (register-optimized) and `i-k-j` (cache-friendly) strategies on other backends.
- **Secondary Utility Acceleration**: Audited functions like `mapi` and `each_row_col` to eliminate division/modulo overhead (up to 60% faster).
- **Backend-Specific Optimization**: Internal implementations are tailored for different targets (Wasm/JS vs. Native) to leverage specific engine strengths.
- **Zero-Copy Transpose**: Optimized identity-based multiplication and materialization.

### API Guidance & Performance
- **Consistent API**: No matter which backend you target, the high-level API remains the same.
- **Random Access**: For high-performance scenarios requiring frequent random access, we **strongly recommend** using the `.get(i, j)` and `.set(i, j, val)` methods directly. These avoid the overhead of `Lens` allocation and are the fastest way to interact with elements.
- **Bulk Operations**: Prefer built-in tools like `.each_row_col()` or `.map_inplace()` over manual loops with indexing for maximum optimization.

### Key Features
- **Mutable & Immutable Support**: Full suites for both `Matrix` and `Vector` types.
- **Advanced Operations**: Includes determinant, inverse, rank, eigenvalues, and more.
- **Zero-Cost Abstractions**: Efficient `Transpose` views and `Lens`-based row access.
- **Correctness First**: Rigorous testing including edge cases (empty matrices, etc.).

### Documentation
Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

We provide documentation in multiple languages:
- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

## Recent Changes

- **Native Optimization (0.2.7)**:
  - 🚀 **Matrix Multiplication**: Implemented transposition + dot-product strategy for Native, outperforming naive implementations by >2x.
  - 🚀 **Matrix Construction**: Optimized `make`, `new`, `transpose` to use direct loop unrolling and Array ops, removing expensive integer division.
  - 📝 **Docs**: Clarified `Lens` vs `get/set` usage for performance-critical code.
- **Performance Overhaul (0.2.4)**:
  - 🚀 Optimized secondary utilities (`mapi`, `each_row_col`, etc.).
  - 🚀 Hybrid Matrix multiplication (register and cache aware).
  - 🚀 Accelerated Vector dot product and linear combinations.
- **Renaming**: 
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
- **Fixes**:
  - Corrected determinant for 0x0 matrices.
  - Fixed copy-on-conversion behavior between vectors and matrices.
