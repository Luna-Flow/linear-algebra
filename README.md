# LINEAR-ALGEBRA

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Luna-Flow/linear-algebra/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## Important Info: Docs will be rewritten soon

Due to the aim to publish a stable beta version for industrial use, we decided to design a standardized, effective and easy-to-read doc standard. Existing docs are outdated. We will publish some breaking changes here temporarily. Docs in code is still correct, you can read it easier at [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/linear-algebra)

This repo has been published as a stable beta version now.

Documentation will be completed soon.

## Breaking Changes

- `map_row()` and `map_col()` in `@mutable.Matrix` is renamed to `map_row_inplace()` and `map_col_inplace()`

- `eachij()` in `@mutable.Matrix` is renamed to `each_row_col()`

- `@mutable.Transpose` has been rewritten (for better performance and standardized), operation is same as `@mutable.Matrix`. You can use `materialize()` to turn virtual transpose into a transposed `@mutable.Matrix`
