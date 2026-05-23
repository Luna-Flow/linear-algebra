# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.8 - Algorithms & Stability

With **v0.2.8**, we have introduced robust numerical methods including LU and QR decompositions, Eigenvalue computations, and improved error handling for linear algebra operations.

### New Algorithms
- **LU Decomposition**: Implemented Gaussian elimination with partial pivoting for numerically stable `determinant`, `inverse`, and `rank` calculations.
- **QR Decomposition**: Added `qr_decomposition` for QR decomposition.
- **Eigenvalues**: Implemented `eigen` for symmetric real matrices and `power_method` for best-effort dominant real eigenpair approximation on general square matrices.
- **Row Operations**: Added `reduce_row_elimination` for Gaussian elimination.

### High-Performance Design
- **Native Transpose Optimization**: Matrix multiplication on Native backend now utilizes a transposition-based strategy, achieving **>200% speedup** for large matrices compared to naive methods.
- **Zero-Overhead Construction**: `Matrix::make` and `Matrix::new` rewritten to eliminate all division and modulo operations during initialization.
- **Hybrid Matrix Multiplication**: Automatically switches between `i-j-k` (register-optimized) and `i-k-j` (cache-friendly) strategies on other backends.
- **Secondary Utility Acceleration**: Audited functions like `mapi` and `each_row_col` to eliminate division/modulo overhead (up to 60% faster).
- **Backend-Specific Optimization**: Internal implementations are tailored for different targets (Wasm/JS vs. Native) to leverage specific engine strengths.
- **Zero-Copy Transpose**: Optimized identity-based multiplication and materialization.

### Package Positioning
- **`immut`**: Value semantics, immutable updates, and predictable materialized results. This package is the baseline for shared algebraic behavior.
- **`mutable`**: Execution-oriented matrices with in-place operations, transpose views, and backend-specific optimization paths. This package is intended for performance-sensitive workloads.
- **Shared Core, Different Execution Model**: The two packages aim to keep core algebraic operations aligned, but they do not expose identical mutation or access semantics.

### API Guidance & Performance
- **Core Algebraic API**: Constructors and core operations such as `make`, `map`, `transpose`, `+`, `-`, `*`, `trace`, and matrix/vector conversions are intended to behave consistently across the two packages.
- **Random Access**: In `mutable`, for high-performance scenarios requiring frequent random access, we **strongly recommend** using `.get(i, j)` and `.set(i, j, val)` directly. These avoid row-accessor overhead and are the fastest way to interact with elements.
- **Bulk Operations**: In `mutable`, prefer built-in tools like `.each_row_col()` or `.map_inplace()` over manual loops with indexing for maximum optimization.
- **Structured Views**: In `mutable`, prefer `row_view()` / `col_view()` when you need repeated row or column work with explicit semantics. Treat `m[row]` / `Lens` as convenience syntax rather than the primary performance API.
- **Accessor Semantics**: `immut` uses read-only row accessors, while `mutable` exposes backend-specific row access paths, structured row/column views, and transpose views. Performance-sensitive code should rely on the documented package-specific access APIs instead of assuming identical indexing internals.

### Key Features
- **Mutable & Immutable Support**: Full suites for both `Matrix` and `Vector` types with distinct semantics.
- **Advanced Operations**: Includes LU/QR decomposition, determinant, inverse, rank, eigenvalues, and more.
- **Execution Specialization**: `mutable` provides efficient `Transpose` views and in-place update APIs for performance-oriented code.
- **Correctness First**: Rigorous testing including edge cases and cross-package consistency checks for shared operations.

### Documentation
Comprehensive API documentation is available at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra).

We provide documentation in multiple languages:
- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

## Recent Changes

- **Algorithms (0.2.8)**:
  - ✨ **Decompositions**: Added LU (internal for Det/Rank), QR, and Eigenvalue decompositions.
  - ✨ **Stability**: Shifted `determinant` and `rank` to use partial pivoting LU for better numerical stability.
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
