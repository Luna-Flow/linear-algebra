# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## Stable Beta Release

We are excited to announce that `linear-algebra` has reached a **Stable Beta** state. This version is designed for reliability and is suitable for industrial use and testing. 

We have conducted a thorough audit of the codebase, ensuring high test coverage (106 tests across both mutable and immutable modules) and correcting inconsistencies between documentation and implementation.

### Key Features
- **Mutable & Immutable Support**: Full suites for both `Matrix` and `Vector` types.
- **Advanced Operations**: Includes determinant, inverse, rank, eigenvalues (QR algorithm), and more.
- **Zero-Cost Abstractions**: Efficient `Transpose` views that allow operations without deep copying.
- **Correctness First**: Rigorous testing including edge cases (empty matrices, single-element vectors, etc.).

### Documentation
Comprehensive API documentation is available and up-to-date with the latest implementation. You can access it at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra) or browse the `doc/` directory in this repository.

We provide documentation in multiple languages to support our global community:
- 🇺🇸 **English** (`doc/en_US`)
- 🇨🇳 **简体中文** (`doc/zh_CN`)
- 🇯🇵 **日本語** (`doc/ja_JP`)

## Recent Changes & Breaking Updates

- **Renaming**: 
  - `map_row()` / `map_col()` -> `map_row_inplace()` / `map_col_inplace()` for clarity.
  - `eachij()` -> `each_row_col()`
- **New Features**:
  - `Vector::dot` added for dot product calculations.
  - `Transpose` view now supports direct indexing (`t[row][col]`).
- **Fixes**:
  - Corrected edge case behavior for 0x0 matrices (determinant is now 1).
