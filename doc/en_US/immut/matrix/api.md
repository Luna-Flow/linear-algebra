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

- **Description**
  Represents an immutable matrix, with data stored in row-major order in an immutable array `IArray[T]`.

- **Fields**
  - `row` - The number of rows.
  - `col` - The number of columns.
  - `data` - The immutable array containing the matrix elements.

- **Functions and Methods**

  ---

  - **`fn[T] Matrix::make(row : Int, col : Int, f : (Int, Int) -> T) -> Matrix[T]`**
    - **Description**
        Creates a new matrix with dimensions `row` × `col` using function `f(row_index, col_index)` to initialize elements.

  ---

  - **`fn[T] Matrix::new(row : Int, col : Int, elem : T) -> Matrix[T]`**
    - **Description**
        Creates a new matrix with all elements initialized to `elem`.

  ---

  - **`fn[T] Matrix::from_2d_array(arr : Array[Array[T]]) -> Matrix[T]`**
    - **Description**
        Creates an immutable matrix from a 2D mutable array.

  ---

  - **`fn[T] row(self : Matrix[T]) -> Int`**
    - **Description**
        Returns the number of rows in the matrix.

  ---

  - **`fn[T] col(self : Matrix[T]) -> Int`**
    - **Description**
        Returns the number of columns in the matrix.

  ---

  - **`fn[T] Matrix::op_get(self : Matrix[T], row : Int) -> Indexed[T]`**
    - **Description**
        Returns a row accessor for the specified row. Supports `m[row][col]` syntax.

  ---

  - **`fn[T] set(self : Matrix[T], i : Int, j : Int, elem : T) -> Matrix[T]`**
    - **Description**
        Returns a new matrix with the element at position (i, j) replaced by `elem`.

  ---

  - **`fn[T, U] map(self : Matrix[T], f : (T) -> U) -> Matrix[U]`**
    - **Description**
        Applies function `f` to each element of the matrix.

  ---

  - **`fn[T : Add] add(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Matrix addition. Supports `+` operator.

  ---

  - **`fn[T : Mul + Add] mul(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Matrix multiplication. Supports `*` operator.

  ---

  - **`fn[T : Neg] neg(self : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Element-wise negation. Supports `-m` syntax.

  ---

  - **`fn[T : Mul] scale(self : Matrix[T], cst : T) -> Matrix[T]`**
    - **Description**
        Scales the matrix by multiplying each element by a constant value.

  ---

  - **`fn[T : One + Zero] Matrix::identity(size : Int) -> Matrix[T]`**
    - **Description**
        Creates an identity matrix of the specified size.

  ---

  - **`fn[T : Conjugate] adjoint(self : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Computes the adjoint (conjugate transpose) of the matrix.

  ---

  - **`fn[T] transpose(self : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Computes the transpose of the matrix.

  ---

  - **`fn[T : Add + Zero] trace(self : Matrix[T]) -> T`**
    - **Description**
        Computes the trace (sum of diagonal elements) of a square matrix.

  ---

  - **`fn[T : Mul + Add + One + Neg + Zero] determinant(self : Matrix[T]) -> T`**
    - **Description**
        Computes the determinant of a square matrix using cofactor expansion.

  ---

  - **`fn[T : Semiring] pow(self : Matrix[T], power : Int) -> Matrix[T]`**
    - **Description**
        Raises the matrix to an integer power.

  ---

  - **`fn[T] horizontal_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Concatenates two matrices horizontally.

  ---

  - **`fn[T] vertical_combine(self : Matrix[T], other : Matrix[T]) -> Matrix[T]`**
    - **Description**
        Concatenates two matrices vertically.

---

## @immut.MatrixFn[T]

```moonbit
struct MatrixFn[T] {
  data : (Int, Int) -> T
  grid : (Int, Int)
}
```

- **Description**
  A lazy functional implementation of a matrix. Elements are computed on-demand by a function.

- **Fields**
  - `data` - The function to compute the element at (row, col).
  - `grid` - The dimensions (row, col) of the matrix.

- **Functions and Methods**

  ---

  - **`fn[T] MatrixFn::make(row : Int, col : Int, f : (Int, Int) -> T) -> MatrixFn[T]`**
    - **Description**
        Creates a functional matrix using generator function `f`.

  ---

  - **`fn[T : Default] MatrixFn::new(row : Int, col : Int) -> MatrixFn[T]`**
    - **Description**
        Creates a functional matrix with all elements set to their default value.

  ---

  - **`fn[T] op_get(self : MatrixFn[T], i : Int) -> Indexed[T]`**
    - **Description**
        Returns a row accessor for the specified row.

  ---

  - **`fn[T, U] map(self : MatrixFn[T], f : (T) -> U) -> MatrixFn[U]`**
    - **Description**
        Transforms the matrix by applying function `f` to elements as they are accessed.
