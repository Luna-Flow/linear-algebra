# `@immut.Vector`

本页记录 `@immut.Vector` 在当前 `0.4.7` 仓库状态下的 API 基线。

## 概览

- `@immut.Vector` 是仓库里的值语义向量类型。
- 这个公开类型同时以包别名 `VecLib[T]` 导出。
- 底层存储使用不可变核心向量别名 `VecCore[T]`。
- `set`、`map`、`left_scale`、`right_scale` 等操作始终返回新向量。
- 本包不提供原地更新，也不提供公开的 `dot()` 辅助函数。

## 核心 API

- `Vector::from_array(arr)`
  从可变 `Array[T]` 构造向量。
- `Vector::make(n, elem)` / `Vector::makei(n, f)`
  创建常量向量，或按索引生成向量。
- `length()`
  返回向量长度。
- `v[i]`
  读取单个元素。边界行为遵循底层不可变向量契约。
- `set(i, x)`
  返回一个在指定位置替换过元素的新向量。
- `iter()`
  按顺序遍历向量元素。

## 值变换

- `map(f)` / `zip_with(other, f)`
  返回变换后的新向量，不修改原值。
- `add_constant(cst)`
  给每个元素加上同一个标量。
- `left_scale(scalar)` / `right_scale(scalar)`
  返回缩放后的新向量。
- `lerp(other, alpha)`
  计算 `(1 - alpha) * self + alpha * other`。
- `+`、`*`、一元 `-`
  分别表示按元素加法、Hadamard 乘法和取负。
- `lin_comb(scalar_a, self, scalar_b, other)`
  顶层辅助函数，用于两个向量的线性组合。

共享的按元素操作如果长度不一致，会按底层向量契约直接中止。

## 矩阵转换

- `to_col_matrix()` / `to_row_matrix()`
  把向量物化为 `n x 1` 或 `1 x n` 矩阵。
- `scaled_matrix()`
  创建以该向量为主对角线的对角矩阵。
- `tensor_product(other)`
  计算外积并返回矩阵。

## 使用建议

- 当下游代码需要明确的值语义时，优先使用 `@immut.Vector`。
- 如果你需要原地更新或公开的 `dot()` 辅助函数，请改用 `@mutable.Vector`。
- `backends/default.ImmutableDenseVector` 包装的就是这个 concrete 实现。
  如果你要从 trait 导向的默认后端入口进入，请看
  [backends/default API](../../backends/default/api.md)。
