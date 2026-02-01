# @mutable.Vector

---

## @mutable.Vector[T]

```moonbit
pub struct Vector[T](Array[T])
```

### 设计与性能说明
- **后端特定优化**：与矩阵操作一样，向量工具针对每个目标后端（Wasm/JS 和 Native）进行了针对性优化，在保持 **API 一致性**的同时确保最高速度。
- **随机访问**：对于随机访问和修改，请直接使用索引语法 `v[i]` 和 `v[i] = x`。这提供了最高效的单个元素交互。
- **批量操作**：在可能的情况下，使用如 `.map_inplace()` 或 `.dot()` 等优化方法进行聚合计算，而不是通过手动索引编写循环。

- **描述**
  表示一个可变的向量，是对 `Array[T]` 的包装。可以通过索引访问和修改元素。

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
