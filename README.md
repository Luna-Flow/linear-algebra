# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.6 - High-Performance Update

We are proud to announce the **v0.2.6** update, which focuses on extreme performance optimization. `linear-algebra` now competes with native array implementations in raw speed.

### High-Performance Design
- **Hybrid Matrix Multiplication**: Automatically switches between `i-j-k` (register-optimized) and `i-k-j` (cache-friendly) strategies.
- **Secondary Utility Acceleration**: Audited functions like `mapi` and `each_row_col` to eliminate division/modulo overhead (up to 60% faster).
- **Backend-Specific Optimization**: Internal implementations are tailored for different targets (Wasm/JS vs. Native) to leverage specific engine strengths, while maintaining a **strictly identical public API**.
- **Zero-Copy Transpose**: Optimized identity-based multiplication and materialization.
- **BCE-Friendly Indexing**: Loops structured for optimal Bounds-Check Elimination.

### API Guidance & Performance
- **Consistent API**: No matter which backend you target, the high-level API remains the same.
- **Random Access**: For high-performance scenarios requiring frequent random access, we strongly recommend using the `.get(i, j)` and `.set(i, j, val)` methods directly. These are designed to be the fastest path for individual element interaction.
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

- **Performance Overhaul (0.2.4)**:
  - 🚀 Optimized secondary utilities (`mapi`, `each_row_col`, etc.).
  - 🚀 Hybrid Matrix multiplication (register and cache aware).
  - 🚀 Accelerated Vector dot product and linear combinations.
- **API Guidance**: Added `Performance Note` to docstrings for `Lens` and `op_get`.
- **Renaming**: 
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()`
  - `eachij()` -> `each_row_col()`
- **Fixes**:
  - Corrected determinant for 0x0 matrices.
  - Fixed copy-on-conversion behavior between vectors and matrices.
