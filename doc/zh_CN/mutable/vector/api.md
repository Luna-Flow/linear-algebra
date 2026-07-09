# `@mutable.Vector`

本页记录 `@mutable.Vector` 在当前 `0.4.6` 仓库状态下的 API 基线。

## 概览

- `@mutable.Vector` 是仓库里的可变向量类型。
- 底层存储是包装后的 `Array[T]`，因此索引写入会直接更新内部缓冲区。
- 即使在这个包里，很多代数辅助函数仍然会返回新向量，便于调用方在“原地修改”和“返回新值”之间显式选择。

## 核心 API

- `Vector::from_array(arr)` / `Vector::make(n, elem)` / `Vector::makei(n, f)`
  分别用于从现有数据、重复值或索引函数构造向量。
- `length()`
  返回向量长度。
- `v[i]` / `v[i] = x`
  读取或写入单个元素。边界行为遵循 `Array[T]`。
- `copy()`
  返回当前向量的深拷贝。
- `iter()`
  按当前顺序遍历元素。

## 返回新向量的辅助函数

- `map(f)` / `zip_with(other, f)`
  返回变换后的新向量，不修改 `self`。
- `add_constant(cst)`
  给每个元素加上同一个标量。
- `left_scale(scalar)` / `right_scale(scalar)`
  返回缩放后的新向量。
- `lerp(other, alpha)`
  计算 `(1 - alpha) * self + alpha * other`。
- `+`、`*`、一元 `-`
  分别表示按元素加法、Hadamard 乘法和取负。

## 原地辅助函数

- `map_inplace(f)`
  原地改写所有元素。
- `left_scale_inplace(scalar)` / `right_scale_inplace(scalar)`
  原地执行标量缩放。

## 标量与矩阵辅助函数

- `dot(other)`
  计算点积。长度不一致时会直接中止。
- `lin_comb(weights, vectors)`
  顶层辅助函数，用一组权重和输入向量组合出新向量。空输入、数量不一致或向量长度不一致都会直接中止。
- `to_col_matrix()` / `to_row_matrix()`
  把向量转换成矩阵形式。
- `scaled_matrix()`
  创建以该向量为主对角线的对角矩阵。
- `tensor_product(other)`
  计算外积并返回矩阵。

## 使用建议

- 当工作负载确实以更新为主时，直接使用索引或 `*_inplace` 辅助函数。
- 当你希望保留旧值，或让代码风格更接近 `@immut.Vector` 时，优先使用那些返回新向量的辅助函数。
- `backends/default.DenseVector` 包装的就是这个 concrete 实现。
  如果你要从 trait 导向的默认后端入口进入，请看
  [backends/default API](../../backends/default/api.md)。
