# @immut.Matrix

---

## @immut.Matrix[T]

```moonbit
struct Matrix[T] {
  row : Int
  col : Int
  data : IArray[T]
} derive(Eq)
```

- **描述**
  表示一个不可变的矩阵，数据按行优先顺序存储在不可变数组 `IArray[T]` 中。

- **字段**
  - `row` - 矩阵的行数。
  - `col` - 矩阵的列数。
  - `data` - 存储矩阵元素的不可变数组。

- **函数与方法**

  ---

  - **`fn[T] Matrix::make(row : Int, col : Int, f : (Int, Int) -> T) -> Matrix[T]`**
    - **描述**
        创建一个新矩阵，并使用给定的函数 `f(row_index, col_index)` 初始化数据。
    - **参数**
      - `row`: `Int` - 行数。
      - `col`: `Int` - 列数。
      - `f`: `(Int, Int) -> T` - 初始化函数。
    - **返回值**
      `Matrix[T]` - 新创建的矩阵。

  ---

  - **`fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T]`**
    - **描述**
        创建一个新矩阵，所有元素都初始化为指定的值 `elem`。
    - **参数**
      - `row`: `Int` - 行数。
      - `col`: `Int` - 列数。
      - `elem`: `T` - 初始值。
    - **返回值**
      `Matrix[T]` - 新创建的矩阵。

  ---

  - **`fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T]`**
    - **描述**
        从一个二维可变数组创建一个不可变矩阵。
    - **参数**
      - `arr`: `Array[Array[T]]` - 输入的二维数组。
    - **返回值**
      `Matrix[T]` - 生成的矩阵。

  ---

  - **`fn[T] row(self : Matrix[T]) -> Int`**
    - **描述**
        获取矩阵的行数。

  ---

  - **`fn[T] col(self : Matrix[T]) -> Int`**
    - **描述**
        获取矩阵的列数。

  ---

  - **`fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Indexed[T]`**
    - **描述**
        获取矩阵指定行的访问器。支持 `m[row][col]` 语法。

  ---

  - **`fn[T] set(self : Matrix[T], i : Int, j : Int, elem : T) -> Matrix[T]`**
    - **描述**
        创建一个新矩阵，其中 (i, j) 位置的元素替换为 `elem`。原矩阵不变。

  ---

  - **`fn[T, U] map(self : Matrix[T], f : (T) -> U) -> Matrix[U]`**
    - **描述**
        对矩阵的每个元素应用函数 `f`。

  ---

  - **`fn[T, U] mapi(self : Matrix[T], f : (Int, Int, T) -> U) -> Matrix[U]`**
    - **描述**
        对矩阵的每个元素应用带行列索引的函数 `f`。

  ---

  - **`fn[T : Add] add(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **描述**
        矩阵加法。支持 `+` 运算符。

  ---

  - **`fn[T : Mul + Add] mul(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **描述**
        矩阵乘法。支持 `*` 运算符。

  ---

  - **`fn[T : Neg] neg(self : Matrix[T]) -> Matrix[T]`**
    - **描述**
        矩阵按元素取负。支持 `-m` 语法。

  ---

  - **`fn[T : Mul] scale(self : Matrix[T], cst : T) -> Matrix[T]`**
    - **描述**
        矩阵按元素缩放。

  ---

  - **`fn[T : One + Zero] Matrix::identity(size : Int) -> Matrix[T]`**
    - **描述**
        创建指定大小的单位矩阵。

  ---

  - **`fn[T : Conjugate] adjoint(self : Matrix[T]) -> Matrix[T]`**
    - **描述**
        计算矩阵的伴随（共轭转置）。

  ---

  - **`fn[T] transpose(self : Matrix[T]) -> Matrix[T]`**
    - **描述**
        计算矩阵的转置。

  ---

  - **`fn[T : Add + Zero] trace(self : Matrix[T]) -> T`**
    - **描述**
        计算方阵的迹。

  ---

  - **`fn[T : Mul + Add + One + Neg + Zero] determinant(self : Matrix[T]) -> T`**
    - **描述**
        计算方阵的行列式（采用代数余子式展开）。

  ---

  - **`fn[T : Semiring] pow(self : Matrix[T], power : Int) -> Matrix[T]`**
    - **描述**
        计算矩阵的整数次幂。

  ---

  - **`fn[T] horizontal_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **描述**
        水平合并两个具有相同行数的矩阵。

  ---

  - **`fn[T] vertical_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **描述**
        垂直合并两个具有相同列数的矩阵。

  ---

  - **`fn[T] swap_rows(self : Matrix[T], r1 : Int, r2 : Int) -> Matrix[T]`**
    - **描述**
        交换矩阵的两行并返回新矩阵。

  ---

  - **`fn[T] swap_cols(self : Matrix[T], c1 : Int, c2 : Int) -> Matrix[T]`**
    - **描述**
        交换矩阵的两列并返回新矩阵。

---

## @immut.MatrixFn[T]

```moonbit
struct MatrixFn[T] {
  data : (Int, Int) -> T
  grid : (Int, Int)
}
```

- **描述**
  使用惰性计算的矩阵实现。结果由函数动态生成，不占用大量内存。

- **字段**
  - `data` - 用于计算 (row, col) 位置元素的函数。
  - `grid` - 矩阵的维度（行，列）。

- **函数与方法**

  ---

  - **`fn[T] MatrixFn::make(row : Int, col : Int, f : (Int, Int) -> T) -> MatrixFn[T]`**
    - **描述**
        根据生成函数 `f` 创建函数矩阵。

  ---

  - **`fn[T : Default] MatrixFn::new(row : Int, col : Int) -> MatrixFn[T]`**
    - **描述**
        创建一个元素均为默认值的函数矩阵。

  ---

  - **`fn[T] op_get(self : MatrixFn[T], i : Int) -> Indexed[T]`**
    - **描述**
        获取指定行的访问器。

  ---

  - **`fn[T, U] map(self : MatrixFn[T], f : (T) -> U) -> MatrixFn[U]`**
    - **描述**
        通过映射函数 `f` 转换矩阵。

  ---

  - **`fn[T] map_row(self : MatrixFn[T], row : Int, f : (T) -> T) -> MatrixFn[T]`**
    - **描述**
        仅对特定行应用变换。

  ---

  - **`fn[T] map_col(self : MatrixFn[T], col : Int, f : (T) -> T) -> MatrixFn[T]`**
    - **描述**
        仅对特定列应用变换。

  ---

  - **`fn[T] transpose(self : MatrixFn[T]) -> MatrixFn[T]`**
    - **描述**
        返回矩阵的转置视图（不移动数据）。
