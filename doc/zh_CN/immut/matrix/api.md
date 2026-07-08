# `@immut.Matrix`

本页描述当前 `0.4.1` 仓库实现的实际行为。

## 概览

- `@immut.Matrix` 采用值语义。
- `set`、`swap_rows`、`swap_cols` 等操作都会返回新矩阵。
- 行列式数据按行优先顺序存储，底层使用 immutable vector 实现。
- 公开索引访问采用严格边界检查。`m[row][col]` 和 `set(row, col, value)` 在越界时都会中止，包括 `0xN` 和 `Nx0` 边界形状。
- `swap_rows(i, i)` 与 `swap_cols(i, i)` 不改变矩阵，直接返回原值。

## 核心 API

- `Matrix::make(row, col, f)`
  用生成函数创建矩阵。负维度会中止。
- `Matrix::new(row, col, elem)`
  创建所有元素都为 `elem` 的矩阵。负维度会中止。
- `Matrix::from_2d_array(arr)`
  从矩形二维数组构造矩阵。行长不一致的输入会中止。
- `Matrix::from_array(row, col, data)`
  从按行优先排列的不可变向量构造矩阵。负维度或元素数量不匹配会中止。
- `row()` / `col()`
  返回保存的形状。
- `m[row][col]`
  只读便捷索引语法。会显式检查行和列边界。
- `set(row, col, elem)`
  返回只替换一个元素的新矩阵。边界会显式检查。
- `map`, `mapi`
  返回转换后的新矩阵，不修改原值。
- `transpose()`
  返回实化后的转置矩阵。
- `horizontal_combine`, `vertical_combine`
  拼接形状兼容的矩阵。
- `iter`, `iter_row`, `iter_col`, `to_array`, `to_2d_array`
  提供行优先迭代与物化转换。行/列迭代器在非法索引下会中止。

## 代数操作

- `+`, `-`, `*`
  加法、减法和矩阵乘法。形状不匹配会中止。
- `matmul(rhs)`, `trace()`, `determinant()`, `pow(power)`
  这些带检查的 API 会在形状或指数错误时返回 `Result[..., LinearAlgebraError]`。
- `unchecked_matmul(rhs)`, `unchecked_trace()`, `unchecked_determinant()`, `unchecked_pow(power)`
  保留旧的直接 abort 行为，供明确需要 unchecked 操作的调用方使用。
- `scale(cst)`, `add_constant(cst)`, 单目 `-`
  逐元素的标量变换。
- `identity(size)`
  创建单位矩阵。负 `size` 会中止。
- `trace()`
  带检查的对角线求和，要求方阵。
- `determinant()`
  带检查的方阵行列式。当前实现对小尺寸使用特化，对更大输入使用消元路径。
- `pow(power)`
  带检查的方阵非负整数幂。
- `null()`, `is_square()`
  零矩阵与形状判断辅助。
- `adjoint()`
  对实现了 `Conjugate` 的元素类型返回共轭转置。
- `swap_rows(r1, r2)`, `swap_cols(c1, c2)`
  返回交换指定行或列后的新矩阵。越界会中止；相同索引不改变矩阵。

## `MatrixFn`

- `MatrixFn` 是 `Matrix` 的惰性函数式版本。
- 它与 `Matrix` 共享非负维度规则。
- `MatrixFn::from_2d_array([])` 返回 `0x0`。
- `MatrixFn::from_2d_array([[], ...])` 保留零列形状。
- 行长不一致的输入会被及早拒绝。
- 行访问会立即校验行索引，元素访问则通过函数式后端契约校验列索引。

主要方法：

- `MatrixFn::make`, `new`, `from_2d_array`
- `map`, `fold`, `zip_with`
- `transpose`, `horizontal_combine`, `vertical_combine`
- `swap_rows`, `swap_cols`
- `identity`, `pow`, `determinant`, `adjoint`

## 正确性说明

- 对共享代数行为来说，仓库中的 consistency tests 仍然把 `@immut.Matrix` 作为语义参考点。
- mutable 包会额外暴露视图和原地更新等执行导向 API，不应把这些能力反向投射到 `immut` 上。
