# @mutable.Matrix

---

## @mutable.Matrix[T]

```moonbit
struct Matrix[T] {
  row : Int
  col : Int
  data : Array[T]
} derive(Eq)
```

- **描述**
  这个结构体表示一个可变的矩阵，其数据存储在一维数组 `data` 中

- **字段**
  - `row` - 矩阵的行数
  - `col` - 矩阵的列数
  - `data` - 矩阵的数据

- **方法**

  - **`fn[T] Matrix::make(row, col, f) -> Matrix[T]`**
    - **描述**
        这个函数用于创建一个新的矩阵，并使用给定的函数初始化矩阵的数据

    - **参数**
      - `row: Int` - 矩阵的行数
      - `col: Int` - 矩阵的列数
      - `f: (Int, Int) -> T` - 用于初始化矩阵数据的函数，第一个参数是行索引，第二个参数是列索引

    - **返回值**
      `Matrix[T]` - 新创建的矩阵对象

  ---

  - **`fn[T] Matrix::new(row, col, elem) -> Matrix[T]`**
    - **描述**
        创建一个新的矩阵，所有元素都初始化为指定的值

    - **参数**
      - `row: Int` - 矩阵的行数
      - `col: Int` - 矩阵的列数
      - `elem: T` - 用于初始化所有元素的值

    - **返回值**
      `Matrix[T]` - 新创建的矩阵对象

  ---

  - **`fn[T] Matrix::from_2d_array(arr) -> Matrix[T]`**
    - **描述**
        从二维数组创建矩阵

    - **参数**
      - `arr: Array[Array[T]]` - 二维数组，每个子数组代表矩阵的一行

    - **返回值**
      `Matrix[T]` - 新创建的矩阵对象

  ---

  - **`fn[T] Matrix::from_array(row, col, data) -> Matrix[T]`**
    - **描述**
        从一维数组和指定的行列数创建矩阵，数据按行优先顺序存储

    - **参数**
      - `row: Int` - 矩阵的行数
      - `col: Int` - 矩阵的列数
      - `data: Array[T]` - 包含矩阵元素的一维数组

    - **返回值**
      `Matrix[T]` - 新创建的矩阵对象

  ---

  - **`fn[T] row(self) -> Int`**
    - **描述**
        获取矩阵的行数

    - **参数**
      - `self: Matrix[T]` - 要查询的矩阵

    - **返回值**
      `Int` - 矩阵的行数

  ---

  - **`fn[T] col(self) -> Int`**
    - **描述**
        获取矩阵的列数

    - **参数**
      - `self: Matrix[T]` - 要查询的矩阵

    - **返回值**
      `Int` - 矩阵的列数

  ---

  - **`fn[T] Matrix::op_get(self, row) -> Lens[T]`**
    - **描述**
        获取矩阵指定行的访问器，用于读取和修改该行的元素

    - **参数**
      - `self: Matrix[T]` - 要访问的矩阵
      - `row: Int` - 行索引（从0开始）

    - **返回值**
      `Lens[T]` - 该行的访问器对象

  ---

  - **`fn[T, U] Matrix::map(self, f) -> Matrix[U]`**
    - **描述**
        对矩阵的每个元素应用函数，创建一个新的矩阵

    - **参数**
      - `self: Matrix[T]` - 输入矩阵
      - `f: (T) -> U` - 应用于每个元素的函数

    - **返回值**
      `Matrix[U]` - 包含转换后元素的新矩阵

  ---

  - **`fn[T] Matrix::map_in_place(self, f) -> Unit`**
    - **描述**
        就地对矩阵的每个元素应用变换函数，修改原矩阵

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `f: (T) -> T` - 应用于每个元素的变换函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::map_row_inplace(self, row, f) -> Unit`**
    - **描述**
        就地对矩阵指定行的所有元素应用变换函数

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `row: Int` - 要变换的行索引
      - `f: (T) -> T` - 应用于行元素的变换函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::map_col_inplace(self, col, f) -> Unit`**
    - **描述**
        就地对矩阵指定列的所有元素应用变换函数

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `col: Int` - 要变换的列索引
      - `f: (T) -> T` - 应用于列元素的变换函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::each(self, f) -> Unit`**
    - **描述**
        对矩阵的每个元素执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `f: (T) -> Unit` - 对每个元素执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::eachi(self, f) -> Unit`**
    - **描述**
        对矩阵的每个元素及其索引执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `f: (Int, T) -> Unit` - 对每个元素及其线性索引执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::each_row_col(self, f) -> Unit`**
    - **描述**
        对矩阵的每个元素及其行列索引执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `f: (Int, Int, T) -> Unit` - 对每个元素及其行列索引执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::each_row(self, row, f) -> Unit`**
    - **描述**
        对矩阵指定行的每个元素执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `row: Int` - 要遍历的行索引
      - `f: (T) -> Unit` - 对每个元素执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::eachi_row(self, row, f) -> Unit`**
    - **描述**
        对矩阵指定行的每个元素及其列索引执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `row: Int` - 要遍历的行索引
      - `f: (Int, T) -> Unit` - 对每个元素及其列索引执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::each_col(self, col, f) -> Unit`**
    - **描述**
        对矩阵指定列的每个元素执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `col: Int` - 要遍历的列索引
      - `f: (T) -> Unit` - 对每个元素执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::eachi_col(self, col, f) -> Unit`**
    - **描述**
        对矩阵指定列的每个元素及其行索引执行函数

    - **参数**
      - `self: Matrix[T]` - 要遍历的矩阵
      - `col: Int` - 要遍历的列索引
      - `f: (Int, T) -> Unit` - 对每个元素及其行索引执行的函数

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] Matrix::copy(self) -> Matrix[T]`**
    - **描述**
        创建矩阵的深拷贝

    - **参数**
      - `self: Matrix[T]` - 要复制的矩阵

    - **返回值**
      `Matrix[T]` - 原矩阵的独立副本

  ---

  - **`fn[T] to_transpose(self) -> Transpose[T]`**
    - **描述**
        将矩阵转换为转置视图，不复制底层数据

    - **参数**
      - `self: Matrix[T]` - 要转置的矩阵

    - **返回值**
      `Transpose[T]` - 转置视图对象

  ---

  - **`fn[T] transpose(self) -> Matrix[T]`**
    - **描述**
        计算矩阵的转置，创建新矩阵

    - **参数**
      - `self: Matrix[T]` - 要转置的矩阵

    - **返回值**
      `Matrix[T]` - 转置后的新矩阵

  ---

  - **`fn[T] swap_rows(self, r1, r2) -> Unit`**
    - **描述**
        交换矩阵中两行的位置

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `r1: Int` - 第一行的索引
      - `r2: Int` - 第二行的索引

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T] swap_cols(self, c1, c2) -> Unit`**
    - **描述**
        交换矩阵中两列的位置

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `c1: Int` - 第一列的索引
      - `c2: Int` - 第二列的索引

    - **返回值**
      `Unit` - 无返回值

  ---

  - **`fn[T : Mul] scale(self, cst) -> Matrix[T]`**
    - **描述**
        将矩阵的每个元素乘以标量值

    - **参数**
      - `self: Matrix[T]` - 要缩放的矩阵
      - `cst: T` - 标量值

    - **返回值**
      `Matrix[T]` - 缩放后的新矩阵

  ---

  - **`fn[T : Add] add_constant(self, cst) -> Matrix[T]`**
    - **描述**
        将常数值加到矩阵的每个元素上

    - **参数**
      - `self: Matrix[T]` - 要修改的矩阵
      - `cst: T` - 要添加的常数值

    - **返回值**
      `Matrix[T]` - 加法运算后的新矩阵

  ---

  - **`fn[T : One + Zero] identity(size) -> Matrix[T]`**
    - **描述**
        创建指定大小的单位矩阵

    - **参数**
      - `size: Int` - 单位矩阵的行数和列数

    - **返回值**
      `Matrix[T]` - 单位矩阵

  ---

  - **`fn[T : Compare + Zero] null(self) -> Bool`**
    - **描述**
        检查矩阵是否为零矩阵（所有元素都为零）

    - **参数**
      - `self: Matrix[T]` - 要检查的矩阵

    - **返回值**
      `Bool` - 如果是零矩阵返回true，否则返回false

  ---

  - **`fn[T : Conjugate] adjoint(self) -> Matrix[T]`**
    - **描述**
        计算矩阵的伴随（共轭转置）

    - **参数**
      - `self: Matrix[T]` - 要计算伴随的矩阵

    - **返回值**
      `Matrix[T]` - 伴随矩阵

  ---

  - **`fn[T : Semiring] pow(self, power) -> Matrix[T]`**
    - **描述**
        计算方阵的幂

    - **参数**
      - `self: Matrix[T]` - 要计算幂的方阵
      - `power: Int` - 非负整数指数

    - **返回值**
      `Matrix[T]` - 矩阵的幂

  ---

  - **`fn[T : Compare + Num + Sub + Inverse] reduce_row_elimination(self) -> Matrix[T]`**
    - **描述**
        使用高斯消元法将矩阵化简为行最简形

    - **参数**
      - `self: Matrix[T]` - 要化简的矩阵

    - **返回值**
      `Matrix[T]` - 化简后的矩阵

  ---

  - **`fn[T] horizontal_combine(self, other) -> Matrix[T]`**
    - **描述**
        水平合并两个矩阵（将第二个矩阵放在第一个矩阵右侧）

    - **参数**
      - `self: Matrix[T]` - 左侧矩阵
      - `other: Matrix[T]` - 右侧矩阵

    - **返回值**
      `Matrix[T]` - 合并后的新矩阵

  ---

  - **`fn[T] vertical_combine(self, other) -> Matrix[T]`**
    - **描述**
        垂直合并两个矩阵（将第二个矩阵放在第一个矩阵下方）

    - **参数**
      - `self: Matrix[T]` - 上方矩阵
      - `other: Matrix[T]` - 下方矩阵

    - **返回值**
      `Matrix[T]` - 合并后的新矩阵

  ---

  - **`fn[T] row_to_array(self, row) -> Array[T]`**
    - **描述**
        提取矩阵指定行并返回为数组

    - **参数**
      - `self: Matrix[T]` - 源矩阵
      - `row: Int` - 要提取的行索引

    - **返回值**
      `Array[T]` - 包含该行所有元素的数组

  ---

  - **`fn[T] col_to_array(self, col) -> Array[T]`**
    - **描述**
        提取矩阵指定列并返回为数组

    - **参数**
      - `self: Matrix[T]` - 源矩阵
      - `col: Int` - 要提取的列索引

    - **返回值**
      `Array[T]` - 包含该列所有元素的数组

  ---

  - **`fn[T] to_array(self) -> Array[T]`**
    - **描述**
        将矩阵转换为一维数组（按行优先顺序）

    - **参数**
      - `self: Matrix[T]` - 要转换的矩阵

    - **返回值**
      `Array[T]` - 包含矩阵所有元素的一维数组

  ---

  - **`fn[T] to_2d_array(self) -> Array[Array[T]]`**
    - **描述**
        将矩阵转换为二维数组

    - **参数**
      - `self: Matrix[T]` - 要转换的矩阵

    - **返回值**
      `Array[Array[T]]` - 二维数组表示

  ---

  - **`fn[T] row_to_vector(self, row) -> Vector[T]`**
    - **描述**
        提取矩阵指定行并返回为向量

    - **参数**
      - `self: Matrix[T]` - 源矩阵
      - `row: Int` - 要提取的行索引

    - **返回值**
      `Vector[T]` - 包含该行所有元素的向量

  ---

  - **`fn[T] col_to_vector(self, col) -> Vector[T]`**
    - **描述**
        提取矩阵指定列并返回为向量

    - **参数**
      - `self: Matrix[T]` - 源矩阵
      - `col: Int` - 要提取的列索引

    - **返回值**
      `Vector[T]` - 包含该列所有元素的向量

  ---

  - **`fn[T] to_vector(self) -> Vector[T]`**
    - **描述**
        将矩阵转换为向量（按行优先顺序）

    - **参数**
      - `self: Matrix[T]` - 要转换的矩阵

    - **返回值**
      `Vector[T]` - 包含矩阵所有元素的向量

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] determinant(self) -> T`**
    - **描述**
        计算方阵的行列式值

    - **参数**
      - `self: Matrix[T]` - 要计算行列式的方阵

    - **返回值**
      `T` - 行列式的值

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let det = m.determinant()  // 计算2x2矩阵的行列式
      ```

  ---

  - **`fn[T : Add + Default] trace(self) -> T`**
    - **描述**
        计算方阵的迹（主对角线元素之和）

    - **参数**
      - `self: Matrix[T]` - 要计算迹的方阵

    - **返回值**
      `T` - 矩阵的迹

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let tr = m.trace()  // 计算迹：1 + 4 = 5
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] eigen(self) -> (Array[T], Matrix[T])`**
    - **描述**
        计算方阵的特征值和特征向量

    - **参数**
      - `self: Matrix[T]` - 要计算特征值和特征向量的方阵

    - **返回值**
      `(Array[T], Matrix[T])` - 第一个元素是特征值数组，第二个元素是特征向量矩阵

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 2.0], [1.0, 3.0]])
      let (eigenvalues, eigenvectors) = m.eigen()
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] power_method(self, ~max_iterations : Int = 1000, ~tolerance_val : T? = None) -> (T, Vector[T])`**
    - **描述**
        使用幂法计算矩阵的主特征值和特征向量

    - **参数**
      - `self: Matrix[T]` - 要计算的方阵
      - `max_iterations: Int` - 最大迭代次数（默认1000）
      - `tolerance_val: T?` - 收敛容忍度（可选）

    - **返回值**
      `(T, Vector[T])` - 主特征值和对应的特征向量

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 2.0], [1.0, 3.0]])
      let (eigenvalue, eigenvector) = m.power_method()
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] qr_decomposition(self) -> (Matrix[T], Matrix[T])`**
    - **描述**
        进行QR分解，将矩阵分解为正交矩阵Q和上三角矩阵R

    - **参数**
      - `self: Matrix[T]` - 要分解的矩阵

    - **返回值**
      `(Matrix[T], Matrix[T])` - Q矩阵和R矩阵

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let (q, r) = m.qr_decomposition()
      ```

  ---

  - **`fn[T : Add + Div + Default] mean(self) -> T`**
    - **描述**
        计算矩阵所有元素的平均值

    - **参数**
      - `self: Matrix[T]` - 要计算平均值的矩阵

    - **返回值**
      `T` - 矩阵元素的平均值

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let avg = m.mean()  // 计算平均值：(1+2+3+4)/4 = 2.5
      ```

  ---

  - **`fn[T : SMul[T] + Add + Div + Default] variance(self) -> T`**
    - **描述**
        计算矩阵所有元素的方差

    - **参数**
      - `self: Matrix[T]` - 要计算方差的矩阵

    - **返回值**
      `T` - 矩阵元素的方差

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let var = m.variance()  // 计算方差
      ```

  ---

  - **`fn[T : SMul[T] + Add + Div + Sqrt[T] + Default] std_dev(self) -> T`**
    - **描述**
        计算矩阵所有元素的标准差

    - **参数**
      - `self: Matrix[T]` - 要计算标准差的矩阵

    - **返回值**
      `T` - 矩阵元素的标准差

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let std = m.std_dev()  // 计算标准差
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] is_symmetric(self) -> Bool`**
    - **描述**
        检查矩阵是否为对称矩阵

    - **参数**
      - `self: Matrix[T]` - 要检查的矩阵

    - **返回值**
      `Bool` - 如果是对称矩阵返回true，否则返回false

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [2.0, 3.0]])
      let is_sym = m.is_symmetric()  // 检查是否对称
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] is_positive_definite(self) -> Bool`**
    - **描述**
        检查矩阵是否为正定矩阵

    - **参数**
      - `self: Matrix[T]` - 要检查的方阵

    - **返回值**
      `Bool` - 如果是正定矩阵返回true，否则返回false

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[2.0, 1.0], [1.0, 2.0]])
      let is_pos_def = m.is_positive_definite()  // 检查是否正定
      ```

  ---

  - **`fn[T : SMul[T] + Add + Neg + Mul + Default] matrix_power(self, n) -> Matrix[T]`**
    - **描述**
        计算矩阵的n次幂

    - **参数**
      - `self: Matrix[T]` - 要计算幂的方阵
      - `n: Int` - 幂次

    - **返回值**
      `Matrix[T]` - 矩阵的n次幂

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[2, 1], [1, 2]])
      let m_squared = m.matrix_power(2)  // 计算矩阵的平方
      ```

  ---

  - **`fn[T : Add + Mul + Neg + Div + Default] frobenius_norm(self) -> T`**
    - **描述**
        计算矩阵的Frobenius范数

    - **参数**
      - `self: Matrix[T]` - 要计算范数的矩阵

    - **返回值**
      `T` - 矩阵的Frobenius范数

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let norm = m.frobenius_norm()  // 计算Frobenius范数
      ```

  ---

  - **`fn[T : Ord + Default] max_element(self) -> T`**
    - **描述**
        找到矩阵中的最大元素

    - **参数**
      - `self: Matrix[T]` - 要搜索的矩阵

    - **返回值**
      `T` - 矩阵中的最大元素

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 5, 3], [2, 8, 1]])
      let max_val = m.max_element()  // 找到最大值：8
      ```

  ---

  - **`fn[T : Ord + Default] min_element(self) -> T`**
    - **描述**
        找到矩阵中的最小元素

    - **参数**
      - `self: Matrix[T]` - 要搜索的矩阵

    - **返回值**
      `T` - 矩阵中的最小元素

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[5, 2, 8], [1, 9, 3]])
      let min_val = m.min_element()  // 找到最小值：1
      ```

  ---

  - **`fn[T : Compare + Num + Sub + Inverse] Matrix::rank(self) -> Int`**
    - **描述**
        使用行约化计算矩阵的秩

    - **参数**
      - `self: Matrix[T]` - 要计算秩的矩阵

    - **返回值**
      `Int` - 矩阵的秩，即其行向量或列向量张成的向量空间的维度

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [7.0, 8.0, 9.0]])
      let rank = m.rank()
      inspect(rank, content="2")  // 矩阵的秩为2
      ```

  ---

  - **`fn[T : Add + Zero] trace(self) -> T`**
    - **描述**
        计算方阵的迹（主对角线元素之和）

    - **参数**
      - `self: Matrix[T]` - 要计算迹的方阵

    - **返回值**
      `T` - 矩阵的迹

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
      let trace = m.trace()
      inspect(trace, content="15")  // 1 + 5 + 9 = 15
      ```

  ---

  - **`fn[T] Matrix::is_square(self) -> Bool`**
    - **描述**
        检查矩阵是否为方阵（行数等于列数）

    - **参数**
      - `self: Matrix[T]` - 要检查的矩阵

    - **返回值**
      `Bool` - 如果是方阵返回true，否则返回false

    - **示例**

      ```moonbit
      let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
      let m2 = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      inspect(m1.is_square(), content="true")  // 2x2矩阵是方阵
      inspect(m2.is_square(), content="false") // 2x3矩阵不是方阵
      ```

  ---

  - **`fn[T] iter(self) -> Iter[T]`**
    - **描述**
        创建矩阵元素的迭代器

    - **参数**
      - `self: Matrix[T]` - 要迭代的矩阵

    - **返回值**
      `Iter[T]` - 按行优先顺序产生每个元素的迭代器

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let iter = m.iter()
      inspect(iter.collect(), content="[1, 2, 3, 4]") // 按行优先顺序收集所有元素
      ```

  ---

  - **`fn[T] iter_row(self, row) -> Iter[T]`**
    - **描述**
        创建矩阵指定行的元素迭代器

    - **参数**
      - `self: Matrix[T]` - 要迭代的矩阵
      - `row: Int` - 要迭代的行的零基索引

    - **返回值**
      `Iter[T]` - 从左到右产生指定行中每个元素的迭代器

    - **异常**
      如果`row`为负数或大于等于行数则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      let row_iter = m.iter_row(1)
      for elem in row_iter {
        println(elem) // 打印: 4, 5, 6
      }
      ```

  ---

  - **`fn[T] iter_col(self, col) -> Iter[T]`**
    - **描述**
        创建矩阵指定列的元素迭代器

    - **参数**
      - `self: Matrix[T]` - 要迭代的矩阵
      - `col: Int` - 要迭代的列的零基索引

    - **返回值**
      `Iter[T]` - 从上到下产生指定列中每个元素的迭代器

    - **异常**
      如果`col`为负数或大于等于列数则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      let col_iter = m.iter_col(1)
      for elem in col_iter {
        println(elem) // 打印: 2, 5
      }
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Neg + Num + Div + Sqrt + Tolerance] eigen(self) -> (Vector[T], Matrix[T])`**
    - **描述**
        使用QR算法计算方阵的特征值和特征向量

    - **参数**
      - `self: Matrix[T]` - 要计算特征值和特征向量的方阵

    - **返回值**
      `(Vector[T], Matrix[T])` - 包含特征值的向量和特征向量矩阵

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
      let (eigenvals, eigenvecs) = m.eigen()
      // eigenvals 应该接近 [3.0, 2.0]
      // eigenvecs 包含对应的特征向量作为列
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Div + Num + Tolerance] power_method(self, max_iterations) -> (T, Vector[T])`**
    - **描述**
        使用幂法计算矩阵的主导特征值和对应的特征向量

    - **参数**
      - `self: Matrix[T]` - 要计算的方阵
      - `max_iterations: Int` - 要执行的最大迭代次数

    - **返回值**
      `(T, Vector[T])` - 包含主导特征值和对应特征向量的元组

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
      let (lambda, v) = m.power_method(100)
      // lambda 是主导特征值，v 是对应的特征向量
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Num + Div + Sqrt + SMul] eigen_2x2(self) -> Vector[T]`**
    - **描述**
        使用解析方法计算2x2矩阵的特征值

    - **参数**
      - `self: Matrix[T]` - 要计算特征值的2x2矩阵

    - **返回值**
      `Vector[T]` - 包含两个特征值的向量

    - **异常**
      如果矩阵不是2x2则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[6.0, -2.0], [-2.0, 9.0]])
      let eigenvals = m.eigen_2x2()
      // 返回包含两个特征值的向量
      ```

  ---

  - **`fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] determinant(self) -> T`**
    - **描述**
        使用基于LU分解和部分选主元的高效算法计算方阵的行列式

    - **参数**
      - `self: Matrix[T]` - 要计算行列式的方阵

    - **返回值**
      `T` - 矩阵的行列式值

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 3.0], [6.0, 3.0]])
      inspect(m.determinant(), content="-6.0")
      ```

  ---

  - **`fn[T : Compare + Num + Sub + Inverse + Zero + One + Tolerance + Div] inverse(self) -> Matrix[T]?`**
    - **描述**
        使用高斯-约旦消元法计算方阵的逆矩阵

    - **参数**
      - `self: Matrix[T]` - 要计算逆矩阵的方阵

    - **返回值**
      `Matrix[T]?` - 如果矩阵可逆则返回`Some(逆矩阵)`，如果矩阵奇异（不可逆）则返回`None`

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      match m.inverse() {
        Some(inv) => println("矩阵可逆")
        None => println("矩阵奇异")
      }
      ```

  ---

  - **`fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] is_invertible(self) -> Bool`**
    - **描述**
        检查矩阵是否可逆（非奇异）

    - **参数**
      - `self: Matrix[T]` - 要检查可逆性的方阵

    - **返回值**
      `Bool` - 如果矩阵可逆返回true，否则返回false

    - **异常**
      如果矩阵不是方阵则会终止程序

    - **示例**

      ```moonbit
      let m1 = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let m2 = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])  // 奇异矩阵
      inspect(m1.is_invertible(), content="true")
      inspect(m2.is_invertible(), content="false")
      ```

---

## 数值特征定义

### SMul[T]

```moonbit
trait SMul[T] {
  op_smul(T, T) -> T
}
```

- **描述**
  标量乘法特征，定义了类型 T 的标量乘法操作

- **方法**
  - **`op_smul(T, T) -> T`**
    - **描述**: 执行标量乘法运算
    - **参数**: 两个类型为 T 的值
    - **返回值**: 乘法结果

### Tolerance[T]

```moonbit
trait Tolerance[T] {
  tolerance() -> T
}
```

- **描述**
  容忍度特征，定义了数值计算中的容忍度阈值

- **方法**
  - **`tolerance() -> T`**
    - **描述**: 返回类型 T 的容忍度值
    - **返回值**: 容忍度阈值

### Sqrt[T]

```moonbit
trait Sqrt[T] {
  sqrt(T) -> T
}
```

- **描述**
  平方根特征，定义了类型 T 的平方根运算

- **方法**
  - **`sqrt(T) -> T`**
    - **描述**: 计算平方根
    - **参数**: 要计算平方根的值
    - **返回值**: 平方根结果

---

## @mutable.Lens[T]

```moonbit
struct Lens[T] {
  set : (Int, T) -> Unit
  get : (Int) -> T
}
```

- **描述**
  这个结构体表示一个数据访问器，用于访问矩阵中的元素

- **字段**
  - `set` - 修改元素值的函数，接收行索引和值作为参数
  - `get` - 访问元素值的函数，接收行索引作为参数并返回元素值

- **方法**

  - **`fn[T] op_get(self, col) -> T`**
    - **描述**
        从访问器中获取指定列索引的值

    - **参数**
      - `self: Lens[T]` - 要访问的访问器
      - `col: Int` - 列索引

    - **返回值**
      `T` - 指定位置的元素值

  ---

  - **`fn[T] Lens::op_set(self, col, elem) -> Unit`**
    - **描述**
        在访问器中设置指定列索引的值

    - **参数**
      - `self: Lens[T]` - 要修改的访问器
      - `col: Int` - 列索引
      - `elem: T` - 要设置的值

    - **返回值**
      `Unit` - 无返回值

---

## 运算符重载

### 算术运算符

- **`impl[T : Mul + Add] Mul for Matrix[T] with op_mul`**
  - **描述**
      矩阵乘法运算符重载，计算两个矩阵的乘积

  - **示例**

    ```moonbit
    let a = Matrix::from_2d_array([[1, 2], [3, 4]])
    let b = Matrix::from_2d_array([[5, 6], [7, 8]])
    let result = a * b  // 矩阵乘法
    ```

- **`impl[T : Add] Add for Matrix[T] with op_add`**
  - **描述**
      矩阵加法运算符重载，计算两个矩阵的元素级相加

  - **示例**

    ```moonbit
    let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
    let m2 = Matrix::from_2d_array([[5, 6], [7, 8]])
    let result = m1 + m2  // 矩阵加法
    ```

- **`impl[T : Add + Neg] Sub for Matrix[T] with op_sub`**
  - **描述**
      矩阵减法运算符重载，计算两个矩阵的元素级相减

  - **示例**

    ```moonbit
    let m1 = Matrix::from_2d_array([[5, 7], [9, 11]])
    let m2 = Matrix::from_2d_array([[1, 2], [3, 4]])
    let result = m1 - m2  // 矩阵减法
    ```

- **`impl[T : Neg] Neg for Matrix[T] with op_neg`**
  - **描述**
      矩阵取负运算符重载，对矩阵所有元素取负

  - **示例**

    ```moonbit
    let m = Matrix::from_2d_array([[1, -2], [3, -4]])
    let negated = -m  // 矩阵取负
    ```

### 显示和输出

- **`impl[T : Show] Show for Matrix[T] with to_string`**
  - **描述**
      将矩阵转换为可读的字符串表示

  - **示例**

    ```moonbit
    let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
    inspect(m.to_string(), content="|1, 2, 3|\n|4, 5, 6|")
    ```

- **`impl[T : Show] Show for Matrix[T] with output`**
  - **描述**
      将矩阵的字符串表示输出到日志记录器

### 索引访问

- **`Matrix::op_get(self, row) -> Lens[T]`**
  - **描述**
      使用方括号语法访问矩阵行，返回该行的访问器对象

  - **示例**

    ```moonbit
    let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
    let row_lens = m[1]  // 获取第2行的访问器
    let value = row_lens[0]  // 访问该行第1列 of the element
    row_lens[2] = 10  // 修改该行第3列 of the element
    ```

---

## @mutable.Transpose[T]

```moonbit
pub struct Transpose[T](Matrix[T])
```

- **描述**
  矩阵的转置视图，提供对底层矩阵的转置访问，而不拷贝数据。

- **方法**

  - **`fn[T] row(self : Transpose[T]) -> Int`**
    - **返回**：行数（等于原矩阵的列数）。

  - **`fn[T] col(self : Transpose[T]) -> Int`**
    - **返回**：列数（等于原矩阵的行数）。

  - **`fn[T] transpose(self : Transpose[T]) -> Matrix[T]`**
    - **返回**：由于 Transpose 是 Matrix 的视图，再次调用 transpose 会返回原始的 `Matrix[T]`。

  - **`fn[T] materialize(self : Transpose[T]) -> Matrix[T]`**
    - **返回**：创建一个新的、物理上已转置布局的 `Matrix[T]`。

  - **`fn[T] map_in_place(self : Transpose[T], f : (T) -> T) -> Unit`**
    - **作用**：就地修改底层矩阵的数据。
