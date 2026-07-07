# @mutable.Vector

本页描述当前仓库实现，并作为 `0.4.0` 的 API 基线。

---

## @mutable.Vector[T]

```moonbit
pub struct Vector[T](Array[T])
```

### 设计与性能说明

- **数组存储**：`Vector[T]` 包装 `Array[T]`，索引读取和写入会作用在底层可变存储上。
- **随机访问**：随机访问和修改可以直接使用 `v[i]` 与 `v[i] = x`。
- **批量操作**：进行聚合或批量变换时，优先使用 `.map_inplace()`、`.dot()` 等已有方法，而不是手写索引循环。

- **描述**
  表示一个可变的向量，是对 `Array[T]` 的包装。可以通过索引访问和修改元素。

### 语义说明

- `@mutable.Vector` 是面向原地修改的：索引写入和 `*_inplace` 系列 API 会直接修改原值。
- 非 `inplace` 的代数辅助函数仍然返回新向量，让调用方可以显式选择“执行导向的修改”还是“返回新值的变换”。

- **函数与方法**

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
      - `f`: `(Int) -> T` - 索引函数。
    - **返回值**
      `Vector[T]` - 生成的向量。

  ---

  - **`fn[T] Vector::from_array(arr : Array[T]) -> Vector[T]`**
    - **描述**
        将现有的数组转换为向量。

  ---

  - **`fn[T] length(self : Vector[T]) -> Int`**
    - **描述**
        获取向量的长度。

  ---

  - **`fn[T] Vector::op_get(self : Vector[T], i : Int) -> T`**
    - **描述**
        获取指定索引处的元素。支持 `v[i]` 语法。

  ---

  - **`fn[T] Vector::op_set(self : Vector[T], i : Int, x : T) -> Unit`**
    - **描述**
        设置指定索引处的元素值。支持 `v[i] = x` 语法。

  ---

  - **`fn[T] copy(self : Vector[T]) -> Vector[T]`**
    - **描述**
        创建向量的深拷贝。

  ---

  - **`fn[T, U] map(self : Vector[T], f : (T) -> U) -> Vector[U]`**
    - **描述**
        映射变换，返回新向量。

  ---

  - **`fn[T] map_inplace(self : Vector[T], f : (T) -> T) -> Unit`**
    - **描述**
        就地应用变换函数，修改原向量。

  ---

  - **`fn[T : Mul] left_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **描述**
        左乘标量转换（返回新向量）：`scalar * x`。

  ---

  - **`fn[T : Mul] right_scale(self : Vector[T], scalar : T) -> Vector[T]`**
    - **描述**
        右乘标量转换（返回新向量）：`x * scalar`。

  ---

  - **`fn[T : Mul] left_scale_inplace(self : Vector[T], scalar : T) -> Unit`**
    - **描述**
        就地进行左乘标量缩放。

  ---

  - **`fn[T : Mul] right_scale_inplace(self : Vector[T], scalar : T) -> Unit`**
    - **描述**
        就地进行右乘标量缩放。

  ---

  - **`fn[T : Add + Mul] dot(self : Vector[T], other : Vector[T]) -> T`**
    - **描述**
        计算两个向量的点积。

  ---

  - **`fn[T : Zero] scaled_matrix(self : Vector[T]) -> Matrix[T]`**
    - **描述**
        创建以该向量为对角线的对角矩阵。

  ---

  - **`fn[T : Mul] tensor_product(self : Vector[T], other : Vector[T]) -> Matrix[T]`**
    - **描述**
        计算两个向量的张量积（外积）。
