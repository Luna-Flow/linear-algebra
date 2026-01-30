# @immut.Vector

---

## @immut.Vector[T]

```moonbit
struct Vector[T] {
  data : IArray[T]
} derive(Eq)
```

- **描述**
  表示一个不可变的向量，底层存储在不可变数组 `IArray[T]` 中。

- **字段**
  - `data` - 存储向量元素的不可变数组。

- **函数与方法**

  ---

  - **`fn[T] Vector::from_array(arr : Array[T]) -> Vector[T]`**
    - **描述**
        从一个可变数组创建一个不可变的向量。
    - **参数**
      - `arr`: `Array[T]` - 输入的可变数组。
    - **返回值**
      `Vector[T]` - 包含数组元素的不可变向量。
    - **示例**
      ```moonbit
      let v = Vector::from_array([1, 2, 3])
      ```

  ---

  - **`fn[T] Vector::make(n : Int, elem : T) -> Vector[T]`**
    - **描述**
        创建一个长度为 `n` 的向量，所有元素都初始化为 `elem`。
    - **参数**
      - `n`: `Int` - 向量长度。
      - `elem`: `T` - 初始值。
    - **返回值**
      `Vector[T]` - 新创建的向量。

  ---

  - **`fn[T] Vector::makei(n : Int, f : (Int) -> T) -> Vector[T]`**
    - **描述**
        创建一个长度为 `n` 的向量，每个元素通过索引函数 `f` 生成。
    - **参数**
      - `n`: `Int` - 向量长度。
      - `f`: `(Int) -> T` - 索引函数，参数为 0 到 `n-1`。
    - **返回值**
      `Vector[T]` - 生成的向量。

  ---

  - **`fn[T] length(self : Vector[T]) -> Int`**
    - **描述**
        获取向量的长度（元素个数）。
    - **参数**
      - `self`: `Vector[T]` - 目标向量。
    - **返回值**
      `Int` - 向量长度。

  ---

  - **`fn[T] Vector::op_get(self : Vector[T], i : Int) -> T`**
    - **描述**
        获取指定索引处的元素。支持 `v[i]` 语法。
    - **参数**
      - `self`: `Vector[T]` - 目标向量。
      - `i`: `Int` - 索引。
    - **返回值**
      `T` - 该位置的元素。

  ---

  - **`fn[T] set(self : Vector[T], i : Int, x : T) -> Vector[T]`**
    - **描述**
        创建一个新向量，其中索引 `i` 处的元素替换为 `x`。原向量不变。
    - **参数**
      - `self`: `Vector[T]` - 原向量。
      - `i`: `Int` - 替换位置的索引。
      - `x`: `T` - 新元素。
    - **返回值**
      `Vector[T]` - 更新后的新向量。

  ---

  - **`fn[T, U] map(self : Vector[T], f : (T) -> U) -> Vector[U]`**
    - **描述**
        对向量中的每个元素应用函数 `f`，并返回包含结果的新向量。
    - **参数**
      - `self`: `Vector[T]` - 输入向量。
      - `f`: `(T) -> U` - 变换函数。
    - **返回值**
      `Vector[U]` - 变换后的新向量。

  ---

  - **`fn[T : Add] add_constant(self : Vector[T], cst : T) -> Vector[T]`**
    - **描述**
        将常数 `cst` 加到向量的每个元素上，返回新向量。
    - **参数**
      - `self`: `Vector[T]` - 输入向量。
      - `cst`: `T` - 要加的常数。
    - **返回值**
      `Vector[T]` - 结果向量。

  ---

  - **`fn[T, U, V] zip_with(self : Vector[T], other : Vector[U], f : (T, U) -> V) -> Vector[V]`**
    - **描述**
        将两个具有相同长度的向量按元素对应用二元函数 `f`。
    - **参数**
      - `self`: `Vector[T]` - 第一个向量。
      - `other`: `Vector[U]` - 第二个向量。
      - `f`: `(T, U) -> V` - 组合函数。
    - **返回值**
      `Vector[V]` - 组合后的新向量。

  ---

  - **`fn[T : Add] add(self : Vector[T], other : Vector[T]) -> Vector[T]`**
    - **描述**
        向量加法（按元素相加）。支持 `+` 运算符。
    - **参数**
      - `self`: `Vector[T]` - 第一个向量。
      - `other`: `Vector[T]` - 第二个向量。
    - **返回值**
      `Vector[T]` - 和向量。

  ---

  - **`fn[T : Mul] mul(self : Vector[T], other : Vector[T]) -> Vector[T]`**
    - **描述**
        向量按元素相乘（Hadamard 乘积）。支持 `*` 运算符。
    - **参数**
      - `self`: `Vector[T]` - 第一个向量。
      - `other`: `Vector[T]` - 第二个向量。
    - **返回值**
      `Vector[T]` - 乘积向量。

  ---

  - **`fn[T : Neg] neg(self : Vector[T]) -> Vector[T]`**
    - **描述**
        向量取负。支持 `-v` 语法。
    - **参数**
      - `self`: `Vector[T]` - 目标向量。
    - **返回值**
      `Vector[T]` - 元素均取负后的新向量。

  ---

  - **`fn[T : Mul] left_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **描述**
        向量左乘标量。
    - **参数**
      - `self`: `Vector[T]` - 原向量。
      - `scalar`: `T` - 标量。
    - **返回值**
      `Vector[T]` - 缩放后的新向量。

  ---

  - **`fn[T : Mul] right_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **描述**
        向量右乘标量。
    - **参数**
      - `self`: `Vector[T]` - 原向量。
      - `scalar`: `T` - 标量。
    - **返回值**
      `Vector[T]` - 缩放后的新向量。

  ---

  - **`fn[T : One + Mul + Add + Neg] lerp(self : Vector[T], other : Vector[T], alpha : T) -> Vector[T]`**
    - **描述**
        在两个向量之间进行线性插值。计算公式为 `(1 - alpha) * self + alpha * other`。
    - **参数**
      - `self`: `Vector[T]` - 起始向量（alpha = 0）。
      - `other`: `Vector[T]` - 终止向量（alpha = 1）。
      - `alpha`: `T` - 插值参数。
    - **返回值**
      `Vector[T]` - 插值结果。

  ---

  - **`fn[T : Add + Mul] lin_comb(scalar_a : T, self : Vector[T], scalar_b : T, other : Vector[T]) -> Vector[T]`**
    - **描述**
        计算两个向量的线性组合 `scalar_a * self + scalar_b * other`。
    - **参数**
      - `scalar_a`: `T` - 第一个向量的权重。
      - `self`: `Vector[T]` - 第一个向量。
      - `scalar_b`: `T` - 第二个向量的权重。
      - `other`: `Vector[T]` - 第二个向量。
    - **返回值**
      `Vector[T]` - 线性组合的结果向量。

  ---

  - **`fn[T] to_col_matrix(self : Vector[T]) -> Matrix[T]`**
    - **描述**
        将向量转换为一个列矩阵（n × 1）。
    - **参数**
      - `self`: `Vector[T]` - 原向量。
    - **返回值**
      `Matrix[T]` - n 行 1 列的矩阵。

  ---

  - **`fn[T] to_row_matrix(self : Vector[T]) -> Matrix[T]`**
    - **描述**
        将向量转换为一个行矩阵（1 × n）。
    - **参数**
      - `self`: `Vector[T]` - 原向量。
    - **返回值**
      `Matrix[T]` - 1 行 n 列的矩阵。

  ---

  - **`fn[T : Zero] scaled_matrix(self : Vector[T]) -> Matrix[T]`**
    - **描述**
        创建一个对角矩阵，其主对角线元素来自该向量。
    - **参数**
      - `self`: `Vector[T]` - 对角线元素来源。
    - **返回值**
      `Matrix[T]` - 对角矩阵。

  ---

  - **`fn[T : Mul] tensor_product(self : Vector[T], other : Vector[T]) -> Matrix[T]`**
    - **描述**
        计算两个向量的张量积（外积），生成一个矩阵。
    - **参数**
      - `self`: `Vector[T]` - 左操作向量（决定结果矩阵的行数）。
      - `other`: `Vector[T]` - 右操作向量（决定结果矩阵的列数）。
    - **返回值**
      `Matrix[T]` - 外积矩阵。
