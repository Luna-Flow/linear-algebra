# `@mutable.Matrix`

本页记录 `@mutable.Matrix` 在当前 `0.4.2` 仓库状态下的 API 基线。依赖平方根的 API 使用 `Luna-Flow/arithmetic.Sqrt`；`Tolerance` 仍由 `mutable` 定义。

## 概览

- `@mutable.Matrix` 是仓库里的执行导向矩阵类型。
- `set`、`swap_rows`、`swap_cols`、`map_inplace`、行/列视图更新以及转置视图更新，都会直接修改底层矩阵。
- 公开存储模型在所有后端上都是按行优先的扁平 `Array[T]`。后端文件之间的差异主要是执行优化，而不是公开矩阵模型。
- 公开访问采用严格边界检查。`get`、`set`、`m[row][col]`、`row_view`、`col_view`、提取辅助函数、迭代器和转置视图访问，都会一致地拒绝越界索引，包括 `0xN` 和 `Nx0` 边界形状。
- `swap_rows(i, i)` 与 `swap_cols(i, i)` 不改变矩阵。越界索引会显式中止，而不是依赖底层存储“恰好访问出错”。

## 核心 API

- `Matrix::make(row, col, f)`
  用生成函数构造矩阵。负维度会中止。
- `Matrix::new(row, col, elem)`
  构造所有元素都为 `elem` 的矩阵。负维度会中止。
- `Matrix::from_2d_array(arr)`
  从矩形二维数组构造矩阵。行长不一致的输入会中止。
- `Matrix::from_array(row, col, data)`
  将按行优先排列的一维数组按指定形状作为矩阵。负维度或元素数量不匹配会中止。
- `row()` / `col()`
  返回保存的形状。
- `get(row, col)` / `set(row, col, elem)`
  带显式边界检查的快速随机访问。
- `m[row][col]`
  基于 `Lens[T]` 的便捷语法。可以读写，但在重复批量操作时应优先使用 `row_view`、`col_view` 或专用辅助函数。
- `copy()`
  深拷贝矩阵。
- `map`, `mapi`
  返回转换后的新矩阵。
- `map_inplace`, `map_row_inplace`, `map_col_inplace`
  原地变换。
- `each`, `eachi`, `each_row_col`, `each_row`, `each_col`, `eachi_row`, `eachi_col`
  遍历辅助函数。
- `iter`, `iter_row`, `iter_col`
  带边界检查的迭代器。
- `row_to_array`, `col_to_array`, `row_to_vector`, `col_to_vector`, `to_array`, `to_2d_array`, `to_vector`
  物化辅助函数；需要索引时会做校验。
- `transpose()`
  返回物化后的转置矩阵。
- `to_transpose()`
  返回一个与底层矩阵保持连接的转置视图。
- `horizontal_combine`, `vertical_combine`
  拼接形状兼容的矩阵。

## 视图与转置

- `row_view(row)` / `col_view(col)`
  返回与底层矩阵保持连接的视图。
- `RowView` 与 `ColView`
  暴露 `get`、`set`、`iter`、`each`、`eachi`、`map_inplace`、`to_array`、`to_vector`。
- `Transpose`
  在转置视图上提供接近矩阵的 API 表面。
- `Transpose::swap_rows` / `Transpose::swap_cols`
  委托到底层矩阵，并共享同样严格的边界语义。

## 代数与数值 API

- `+`, `-`, `*`
  矩阵加法、减法和乘法。
- `scale(cst)`, `add_constant(cst)`, 单目 `-`
  逐元素标量变换。
- `identity(size)`
  单位矩阵构造器。负 `size` 会中止。
- `pow(power)`
  带检查的方阵非负整数幂。
- `matrix_power(n)`
  `pow(n)` 的带检查公开别名。
- `trace()`
  带检查的对角线求和。要求方阵，并返回 `Result[..., LinearAlgebraError]`。
- `determinant()`
  带检查的方阵行列式。
- `inverse()`, `is_invertible()`
  带检查的逆矩阵相关辅助函数。奇异矩阵求逆返回 `Err`。
- `mul_vec(vector)`
  带检查的矩阵向量乘法。形状不匹配时返回 `Err`。
- `mean()`, `variance()`, `std_dev()`, `max_element()`, `min_element()`
  带检查的聚合辅助函数。空矩阵返回 `Err`。
- `unchecked_trace()`, `unchecked_determinant()`, `unchecked_inverse()`, `unchecked_is_invertible()`, `unchecked_pow()`, `unchecked_matrix_power()`, `unchecked_mul_vec()`, `unchecked_mean()`, `unchecked_variance()`, `unchecked_std_dev()`, `unchecked_max_element()`, `unchecked_min_element()`
  保留旧的 abort 或 `Option` 返回行为。
- `rank()`
  按当前仓库算法计算矩阵的秩。
- `reduce_row_elimination()`
  在可变矩阵值上执行行消元。
- `cholesky_decomposition()`
  对支持的数值输入执行 Cholesky 分解。
- `eigen()`, `power_method()`
  当前公开的特征值相关 API。实现内部使用的 2x2 特化辅助函数不是公开接口。
- `is_square()`, `null()`, `is_symmetric()`, `is_positive_definite()`
  结构与数值判定辅助。
- `frobenius_norm()`
  面向支持元素类型的非检查式聚合辅助函数。

## 使用建议

- 各后端应暴露相同的公开语义。当前仓库仍保留 `native`、`js`、`wasm`、`wasm-gc` 四套内核文件，但除非特别说明，文档与测试都按后端无关的公开行为来理解。
- 当你编写同时适用于 `immut` 和 `mutable` 的代码时，应依赖它们共享的代数 API，而不是假设修改语义也完全相同。
- `backends/default.DenseMatrix` 包装的就是这个 concrete 实现。
  如果你要从 trait 导向的默认后端入口进入，请看
  [backends/default API](../../backends/default/api.md)。
