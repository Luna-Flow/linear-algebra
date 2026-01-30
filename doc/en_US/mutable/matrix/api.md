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

- **Description**
  This struct represents a mutable matrix with data stored in a one-dimensional array `data`

- **Fields**
  - `row` - Number of rows in the matrix
  - `col` - Number of columns in the matrix
  - `data` - Matrix data storage

- **Methods**

  - **`fn[T] Matrix::make(row, col, f) -> Matrix[T]`**
    - **Description**
        Creates a new matrix and initializes the matrix data using the given function

    - **Parameters**
      - `row: Int` - Number of rows in the matrix
      - `col: Int` - Number of columns in the matrix
      - `f: (Int, Int) -> T` - Function to initialize matrix data, first parameter is row index, second parameter is column index

    - **Returns**
      `Matrix[T]` - Newly created matrix object

  ---

  - **`fn[T] Matrix::new(row, col, elem) -> Matrix[T]`**
    - **Description**
        Creates a new matrix with all elements initialized to the specified value

    - **Parameters**
      - `row: Int` - Number of rows in the matrix
      - `col: Int` - Number of columns in the matrix
      - `elem: T` - Value to initialize all elements

    - **Returns**
      `Matrix[T]` - Newly created matrix object

  ---

  - **`fn[T] Matrix::from_2d_array(arr) -> Matrix[T]`**
    - **Description**
        Creates a matrix from a 2D array

    - **Parameters**
      - `arr: Array[Array[T]]` - 2D array where each sub-array represents a row of the matrix

    - **Returns**
      `Matrix[T]` - Newly created matrix object

  ---

  - **`fn[T] Matrix::from_array(row, col, data) -> Matrix[T]`**
    - **Description**
        Creates a matrix from a 1D array and specified row/column dimensions, data stored in row-major order

    - **Parameters**
      - `row: Int` - Number of rows in the matrix
      - `col: Int` - Number of columns in the matrix
      - `data: Array[T]` - 1D array containing matrix elements

    - **Returns**
      `Matrix[T]` - Newly created matrix object

  ---

  - **`fn[T] row(self) -> Int`**
    - **Description**
        Gets the number of rows in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to query

    - **Returns**
      `Int` - Number of rows in the matrix

  ---

  - **`fn[T] col(self) -> Int`**
    - **Description**
        Gets the number of columns in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to query

    - **Returns**
      `Int` - Number of columns in the matrix

  ---

  - **`fn[T] Matrix::op_get(self, row) -> Lens[T]`**
    - **Description**
        Gets an accessor for the specified row of the matrix, used for reading and modifying elements in that row

    - **Parameters**
      - `self: Matrix[T]` - Matrix to access
      - `row: Int` - Row index (starting from 0)

    - **Returns**
      `Lens[T]` - Accessor object for that row

    - **Performance Note**
      Calling `m[row]` allocates a new `Lens` object and two closures. For performance-critical bulk operations, it is highly recommended to:
      1. **Cache the lens**: Store the result of `m[row]` in a variable before the loop.
      2. **Use built-in tools**: For common operations, use `each_row`, `map_row_inplace`, etc., which avoid Lens overhead entirely.

  ---

  - **`fn[T, U] Matrix::map(self, f) -> Matrix[U]`**
    - **Description**
        Applies a function to each element of the matrix, creating a new matrix

    - **Parameters**
      - `self: Matrix[T]` - Input matrix
      - `f: (T) -> U` - Function to apply to each element

    - **Returns**
      `Matrix[U]` - New matrix containing transformed elements

  ---

  - **`fn[T] Matrix::map_in_place(self, f) -> Unit`**
    - **Description**
        Applies a transformation function to each element of the matrix in-place, modifying the original matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `f: (T) -> T` - Transformation function to apply to each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::map_row_inplace(self, row, f) -> Unit`**
    - **Description**
        Applies a transformation function to all elements in the specified row in-place

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `row: Int` - Row index to transform
      - `f: (T) -> T` - Transformation function to apply to row elements

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::map_col_inplace(self, col, f) -> Unit`**
    - **Description**
        Applies a transformation function to all elements in the specified column in-place

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `col: Int` - Column index to transform
      - `f: (T) -> T` - Transformation function to apply to column elements

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::each(self, f) -> Unit`**
    - **Description**
        Executes a function for each element of the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `f: (T) -> Unit` - Function to execute for each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::eachi(self, f) -> Unit`**
    - **Description**
        Executes a function for each element of the matrix and its index

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `f: (Int, T) -> Unit` - Function to execute for each element and its linear index

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::each_row_col(self, f) -> Unit`**
    - **Description**
        Executes a function for each element of the matrix and its row-column indices

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `f: (Int, Int, T) -> Unit` - Function to execute for each element and its row-column indices

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::each_row(self, row, f) -> Unit`**
    - **Description**
        Executes a function for each element in the specified row

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `row: Int` - Row index to traverse
      - `f: (T) -> Unit` - Function to execute for each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::eachi_row(self, row, f) -> Unit`**
    - **Description**
        Executes a function for each element in the specified row and its column index

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `row: Int` - Row index to traverse
      - `f: (Int, T) -> Unit` - Function to execute for each element and its column index

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::each_col(self, col, f) -> Unit`**
    - **Description**
        Executes a function for each element in the specified column

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `col: Int` - Column index to traverse
      - `f: (T) -> Unit` - Function to execute for each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::eachi_col(self, col, f) -> Unit`**
    - **Description**
        Executes a function for each element in the specified column and its row index

    - **Parameters**
      - `self: Matrix[T]` - Matrix to traverse
      - `col: Int` - Column index to traverse
      - `f: (Int, T) -> Unit` - Function to execute for each element and its row index

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Matrix::copy(self) -> Matrix[T]`**
    - **Description**
        Creates a deep copy of the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to copy

    - **Returns**
      `Matrix[T]` - Independent copy of the original matrix

  ---

  - **`fn[T] to_transpose(self) -> Transpose[T]`**
    - **Description**
        Converts the matrix to a transpose view without copying the underlying data

    - **Parameters**
      - `self: Matrix[T]` - Matrix to transpose

    - **Returns**
      `Transpose[T]` - Transpose view object

  ---

  - **`fn[T] transpose(self) -> Matrix[T]`**
    - **Description**
        Computes the transpose of the matrix, creating a new matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to transpose

    - **Returns**
      `Matrix[T]` - New transposed matrix

  ---

  - **`fn[T] swap_rows(self, r1, r2) -> Unit`**
    - **Description**
        Swaps the positions of two rows in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `r1: Int` - Index of the first row
      - `r2: Int` - Index of the second row

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] swap_cols(self, c1, c2) -> Unit`**
    - **Description**
        Swaps the positions of two columns in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `c1: Int` - Index of the first column
      - `c2: Int` - Index of the second column

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T : Mul] scale(self, cst) -> Matrix[T]`**
    - **Description**
        Multiplies each element of the matrix by a scalar value

    - **Parameters**
      - `self: Matrix[T]` - Matrix to scale
      - `cst: T` - Scalar value

    - **Returns**
      `Matrix[T]` - New scaled matrix

  ---

  - **`fn[T : Add] add_constant(self, cst) -> Matrix[T]`**
    - **Description**
        Adds a constant value to each element of the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to modify
      - `cst: T` - Constant value to add

    - **Returns**
      `Matrix[T]` - New matrix after addition operation

  ---

  - **`fn[T : One + Zero] identity(size) -> Matrix[T]`**
    - **Description**
        Creates an identity matrix of the specified size

    - **Parameters**
      - `size: Int` - Number of rows and columns in the identity matrix

    - **Returns**
      `Matrix[T]` - Identity matrix

  ---

  - **`fn[T : Compare + Zero] null(self) -> Bool`**
    - **Description**
        Checks if the matrix is a zero matrix (all elements are zero)

    - **Parameters**
      - `self: Matrix[T]` - Matrix to check

    - **Returns**
      `Bool` - Returns true if it's a zero matrix, false otherwise

  ---

  - **`fn[T : Conjugate] adjoint(self) -> Matrix[T]`**
    - **Description**
        Computes the adjoint (conjugate transpose) of the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to compute adjoint for

    - **Returns**
      `Matrix[T]` - Adjoint matrix

  ---

  - **`fn[T : Semiring] pow(self, power) -> Matrix[T]`**
    - **Description**
        Computes the power of a square matrix

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute power for
      - `power: Int` - Non-negative integer exponent

    - **Returns**
      `Matrix[T]` - Matrix power

  ---

  - **`fn[T : Compare + Num + Sub + Inverse] reduce_row_elimination(self) -> Matrix[T]`**
    - **Description**
        Reduces the matrix to row echelon form using Gaussian elimination

    - **Parameters**
      - `self: Matrix[T]` - Matrix to reduce

    - **Returns**
      `Matrix[T]` - Reduced matrix

  ---

  - **`fn[T] horizontal_combine(self, other) -> Matrix[T]`**
    - **Description**
        Horizontally combines two matrices (places the second matrix to the right of the first)

    - **Parameters**
      - `self: Matrix[T]` - Left matrix
      - `other: Matrix[T]` - Right matrix

    - **Returns**
      `Matrix[T]` - New combined matrix

  ---

  - **`fn[T] vertical_combine(self, other) -> Matrix[T]`**
    - **Description**
        Vertically combines two matrices (places the second matrix below the first)

    - **Parameters**
      - `self: Matrix[T]` - Top matrix
      - `other: Matrix[T]` - Bottom matrix

    - **Returns**
      `Matrix[T]` - New combined matrix

  ---

  - **`fn[T] row_to_array(self, row) -> Array[T]`**
    - **Description**
        Extracts the specified row from the matrix and returns it as an array

    - **Parameters**
      - `self: Matrix[T]` - Source matrix
      - `row: Int` - Row index to extract

    - **Returns**
      `Array[T]` - Array containing all elements from that row

  ---

  - **`fn[T] col_to_array(self, col) -> Array[T]`**
    - **Description**
        Extracts the specified column from the matrix and returns it as an array

    - **Parameters**
      - `self: Matrix[T]` - Source matrix
      - `col: Int` - Column index to extract

    - **Returns**
      `Array[T]` - Array containing all elements from that column

  ---

  - **`fn[T] to_array(self) -> Array[T]`**
    - **Description**
        Converts the matrix to a 1D array (in row-major order)

    - **Parameters**
      - `self: Matrix[T]` - Matrix to convert

    - **Returns**
      `Array[T]` - 1D array containing all matrix elements

  ---

  - **`fn[T] to_2d_array(self) -> Array[Array[T]]`**
    - **Description**
        Converts the matrix to a 2D array

    - **Parameters**
      - `self: Matrix[T]` - Matrix to convert

    - **Returns**
      `Array[Array[T]]` - 2D array representation

  ---

  - **`fn[T] row_to_vector(self, row) -> Vector[T]`**
    - **Description**
        Extracts the specified row from the matrix and returns it as a vector

    - **Parameters**
      - `self: Matrix[T]` - Source matrix
      - `row: Int` - Row index to extract

    - **Returns**
      `Vector[T]` - Vector containing all elements from that row

  ---

  - **`fn[T] col_to_vector(self, col) -> Vector[T]`**
    - **Description**
        Extracts the specified column from the matrix and returns it as a vector

    - **Parameters**
      - `self: Matrix[T]` - Source matrix
      - `col: Int` - Column index to extract

    - **Returns**
      `Vector[T]` - Vector containing all elements from that column

  ---

  - **`fn[T] to_vector(self) -> Vector[T]`**
    - **Description**
        Converts the matrix to a vector (in row-major order)

    - **Parameters**
      - `self: Matrix[T]` - Matrix to convert

    - **Returns**
      `Vector[T]` - Vector containing all matrix elements

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] determinant(self) -> T`**
    - **Description**
        Computes the determinant value of a square matrix

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute determinant for

    - **Returns**
      `T` - Determinant value

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let det = m.determinant()  // Compute determinant of 2x2 matrix
      ```

  ---

  - **`fn[T : Add + Default] trace(self) -> T`**
    - **Description**
        Computes the trace of a square matrix (sum of main diagonal elements)

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute trace for

    - **Returns**
      `T` - Matrix trace

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let tr = m.trace()  // Compute trace: 1 + 4 = 5
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] eigen(self) -> (Array[T], Matrix[T])`**
    - **Description**
        Computes eigenvalues and eigenvectors of a square matrix

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute eigenvalues and eigenvectors for

    - **Returns**
      `(Array[T], Matrix[T])` - First element is eigenvalue array, second element is eigenvector matrix

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 2.0], [1.0, 3.0]])
      let (eigenvalues, eigenvectors) = m.eigen()
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] power_method(self, ~max_iterations : Int = 1000, ~tolerance_val : T? = None) -> (T, Vector[T])`**
    - **Description**
        Computes the dominant eigenvalue and eigenvector using the power method

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute for
      - `max_iterations: Int` - Maximum number of iterations (default 1000)
      - `tolerance_val: T?` - Convergence tolerance (optional)

    - **Returns**
      `(T, Vector[T])` - Dominant eigenvalue and corresponding eigenvector

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 2.0], [1.0, 3.0]])
      let (eigenvalue, eigenvector) = m.power_method()
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] qr_decomposition(self) -> (Matrix[T], Matrix[T])`**
    - **Description**
        Performs QR decomposition, decomposing the matrix into an orthogonal matrix Q and an upper triangular matrix R

    - **Parameters**
      - `self: Matrix[T]` - Matrix to decompose

    - **Returns**
      `(Matrix[T], Matrix[T])` - Q matrix and R matrix

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let (q, r) = m.qr_decomposition()
      ```

  ---

  - **`fn[T : Add + Div + Default] mean(self) -> T`**
    - **Description**
        Computes the mean of all elements in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to compute mean for

    - **Returns**
      `T` - Mean of matrix elements

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let avg = m.mean()  // Compute mean: (1+2+3+4)/4 = 2.5
      ```

  ---

  - **`fn[T : SMul[T] + Add + Div + Default] variance(self) -> T`**
    - **Description**
        Computes the variance of all elements in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to compute variance for

    - **Returns**
      `T` - Variance of matrix elements

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let var = m.variance()  // Compute variance
      ```

  ---

  - **`fn[T : SMul[T] + Add + Div + Sqrt[T] + Default] std_dev(self) -> T`**
    - **Description**
        Computes the standard deviation of all elements in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to compute standard deviation for

    - **Returns**
      `T` - Standard deviation of matrix elements

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let std = m.std_dev()  // Compute standard deviation
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] is_symmetric(self) -> Bool`**
    - **Description**
        Checks if the matrix is symmetric

    - **Parameters**
      - `self: Matrix[T]` - Matrix to check

    - **Returns**
      `Bool` - Returns true if it's a symmetric matrix, false otherwise

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [2.0, 3.0]])
      let is_sym = m.is_symmetric()  // Check if symmetric
      ```

  ---

  - **`fn[T : SMul[T] + Tolerance[T] + Ord + Neg + Add + Mul + Div + Sqrt[T] + Default] is_positive_definite(self) -> Bool`**
    - **Description**
        Checks if the matrix is positive definite

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to check

    - **Returns**
      `Bool` - Returns true if it's a positive definite matrix, false otherwise

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[2.0, 1.0], [1.0, 2.0]])
      let is_pos_def = m.is_positive_definite()  // Check if positive definite
      ```

  ---

  - **`fn[T : SMul[T] + Add + Neg + Mul + Default] matrix_power(self, n) -> Matrix[T]`**
    - **Description**
        Computes the n-th power of a matrix

    - **Parameters**
      - `self: Matrix[T]` - Square matrix to compute power for
      - `n: Int` - Power exponent

    - **Returns**
      `Matrix[T]` - Matrix to the n-th power

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[2, 1], [1, 2]])
      let m_squared = m.matrix_power(2)  // Compute matrix squared
      ```

  ---

  - **`fn[T : Add + Mul + Neg + Div + Default] frobenius_norm(self) -> T`**
    - **Description**
        Computes the Frobenius norm of the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to compute norm for

    - **Returns**
      `T` - Frobenius norm of the matrix

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let norm = m.frobenius_norm()  // Compute Frobenius norm
      ```

  ---

  - **`fn[T : Ord + Default] max_element(self) -> T`**
    - **Description**
        Finds the maximum element in the matrix

    - **Parameters**
      - `self: Matrix[T]` - Matrix to search

    - **Returns**
      `T` - Maximum element in the matrix

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 5, 3], [2, 8, 1]])
      let max_val = m.max_element()  // Find maximum value: 8
      `

    ---

  - **`fn[T : Compare + Num + Sub + Inverse] Matrix::rank(self) -> Int`**
    - **Description**
        Calculates the rank of the matrix using row reduction

    - **Parameters**
      - `self: Matrix[T]` - The matrix to compute the rank of

    - **Returns**
      `Int` - The rank of the matrix, which is the dimension of the vector space spanned by its rows or columns

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [7.0, 8.0, 9.0]])
      let rank = m.rank()
      inspect(rank, content="2")  // The rank of the matrix is 2
      ```

  ---

  - **`fn[T : Add + Zero] trace(self) -> T`**
    - **Description**
        Calculates the trace of a square matrix (sum of main diagonal elements)

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to calculate the trace of

    - **Returns**
      `T` - The trace of the matrix

    - **Panics**
      If the matrix is not square (row count != column count)

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
      let trace = m.trace()
      inspect(trace, content="15")  // 1 + 5 + 9 = 15
      ```

  ---

  - **`fn[T] Matrix::is_square(self) -> Bool`**
    - **Description**
        Checks if the matrix is square (i.e., has the same number of rows and columns)

    - **Parameters**
      - `self: Matrix[T]` - The matrix to check for squareness

    - **Returns**
      `Bool` - Returns true if the matrix is square, false otherwise

    - **Example**

      ```moonbit
      let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
      let m2 = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      inspect(m1.is_square(), content="true")  // 2x2 matrix is square
      inspect(m2.is_square(), content="false") // 2x3 matrix is not square
      ```

  ---

  - **`fn[T] iter(self) -> Iter[T]`**
    - **Description**
        Creates an iterator over the matrix elements

    - **Parameters**
      - `self: Matrix[T]` - The matrix to iterate over

    - **Returns**
      `Iter[T]` - An iterator that yields each element of the matrix in row-major order

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2], [3, 4]])
      let iter = m.iter()
      inspect(iter.collect(), content="[1, 2, 3, 4]") // Collects all elements in row-major order
      ```

  ---

  - **`fn[T] iter_row(self, row) -> Iter[T]`**
    - **Description**
        Creates an iterator over the elements of a specific row in the matrix

    - **Parameters**
      - `self: Matrix[T]` - The matrix to iterate over
      - `row: Int` - The zero-based index of the row to iterate

    - **Returns**
      `Iter[T]` - An iterator that yields each element in the specified row from left to right

    - **Panics**
      If `row` is negative or greater than or equal to the number of rows

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      let row_iter = m.iter_row(1)
      for elem in row_iter {
        println(elem) // prints: 4, 5, 6
      }
      ```

  ---

  - **`fn[T] iter_col(self, col) -> Iter[T]`**
    - **Description**
        Creates an iterator over the elements of a specific column in the matrix

    - **Parameters**
      - `self: Matrix[T]` - The matrix to iterate over
      - `col: Int` - The zero-based index of the column to iterate

    - **Returns**
      `Iter[T]` - An iterator that yields each element in the specified column from top to bottom

    - **Panics**
      If `col` is negative or greater than or equal to the number of columns

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
      let col_iter = m.iter_col(1)
      for elem in col_iter {
        println(elem) // prints: 2, 5
      }
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Neg + Num + Div + Sqrt + Tolerance] eigen(self) -> (Vector[T], Matrix[T])`**
    - **Description**
        Computes the eigenvalues and eigenvectors of a square matrix using the QR algorithm

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to compute eigenvalues and eigenvectors for

    - **Returns**
      `(Vector[T], Matrix[T])` - A tuple containing a vector of eigenvalues and a matrix where each column is an eigenvector

    - **Panics**
      If the matrix is not square

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
      let (eigenvals, eigenvecs) = m.eigen()
      // eigenvals should be close to [3.0, 2.0]
      // eigenvecs contains the corresponding eigenvectors as columns
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Div + Num + Tolerance] power_method(self, max_iterations) -> (T, Vector[T])`**
    - **Description**
        Computes the dominant eigenvalue and eigenvector using the power method

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to compute for
      - `max_iterations: Int` - The maximum number of iterations to perform

    - **Returns**
      `(T, Vector[T])` - A tuple containing the dominant eigenvalue and corresponding eigenvector

    - **Panics**
      If the matrix is not square

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, -2.0], [1.0, 1.0]])
      let (lambda, v) = m.power_method(100)
      // lambda is the dominant eigenvalue, v is the corresponding eigenvector
      ```

  ---

  - **`fn[T : Compare + Add + Mul + Sub + Num + Div + Sqrt + SMul] eigen_2x2(self) -> Vector[T]`**
    - **Description**
        Computes eigenvalues for 2x2 matrices analytically

    - **Parameters**
      - `self: Matrix[T]` - The 2x2 matrix to compute eigenvalues for

    - **Returns**
      `Vector[T]` - A vector containing the two eigenvalues

    - **Panics**
      If the matrix is not 2x2

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[6.0, -2.0], [-2.0, 9.0]])
      let eigenvals = m.eigen_2x2()
      // Returns a vector containing the two eigenvalues
      ```

  ---

  - **`fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] determinant(self) -> T`**
    - **Description**
        Calculates the determinant of a square matrix using an efficient algorithm based on LU decomposition with partial pivoting

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to compute the determinant for

    - **Returns**
      `T` - The determinant value of the matrix

    - **Panics**
      If the matrix is not square

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[4.0, 3.0], [6.0, 3.0]])
      inspect(m.determinant(), content="-6.0")
      ```

  ---

  - **`fn[T : Compare + Num + Sub + Inverse + Zero + One + Tolerance + Div] inverse(self) -> Matrix[T]?`**
    - **Description**
        Computes the inverse of a square matrix using the Gauss-Jordan elimination method

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to compute the inverse of

    - **Returns**
      `Matrix[T]?` - `Some(inverse_matrix)` if the matrix is invertible, `None` if the matrix is singular (non-invertible)

    - **Panics**
      If the matrix is not square

    - **Example**

      ```moonbit
      let m = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      match m.inverse() {
        Some(inv) => println("Matrix is invertible")
        None => println("Matrix is singular")
      }
      ```

  ---

  - **`fn[T : Compare + Sub + Mul + Div + Zero + One + Num + Tolerance] is_invertible(self) -> Bool`**
    - **Description**
        Checks if a matrix is invertible (non-singular)

    - **Parameters**
      - `self: Matrix[T]` - The square matrix to check for invertibility

    - **Returns**
      `Bool` - Returns true if the matrix is invertible, false otherwise

    - **Panics**
      If the matrix is not square

    - **Example**

      ```moonbit
      let m1 = Matrix::from_2d_array([[1.0, 2.0], [3.0, 4.0]])
      let m2 = Matrix::from_2d_array([[1.0, 2.0], [2.0, 4.0]])  // Singular matrix
      inspect(m1.is_invertible(), content="true")
      inspect(m2.is_invertible(), content="false")
      ```

---

## Numeric Trait Definitions

### SMul[T]

```moonbit
trait SMul[T] {
  op_smul(T, T) -> T
}
```

- **Description**
  Scalar multiplication trait that defines scalar multiplication operations for type T

- **Methods**
  - **`op_smul(T, T) -> T`**
    - **Description**: Performs scalar multiplication operation
    - **Parameters**: Two values of type T
    - **Returns**: Result of multiplication

### Tolerance[T]

```moonbit
trait Tolerance[T] {
  tolerance() -> T
}
```

- **Description**
  Tolerance trait that defines tolerance thresholds for numerical computations

- **Methods**
  - **`tolerance() -> T`**
    - **Description**: Returns tolerance value for type T
    - **Returns**: Tolerance threshold

### Sqrt[T]

```moonbit
trait Sqrt[T] {
  sqrt(T) -> T
}
```

- **Description**
  Square root trait that defines square root operations for type T

- **Methods**
  - **`sqrt(T) -> T`**
    - **Description**: Computes square root
    - **Parameters**: Value to compute square root for
    - **Returns**: Square root result

---

## @mutable.Lens[T]

```moonbit
struct Lens[T] {
  set : (Int, T) -> Unit
  get : (Int) -> T
}
```

- **Description**
  This struct represents a data accessor used to access elements in a matrix

- **Fields**
  - `set` - Function to modify element values, takes row index and value as parameters
  - `get` - Function to access element values, takes row index as parameter and returns element value

- **Methods**

  - **`fn[T] op_get(self, col) -> T`**
    - **Description**
        Gets the value at the specified column index from the accessor

    - **Parameters**
      - `self: Lens[T]` - Accessor to access
      - `col: Int` - Column index

    - **Returns**
      `T` - Element value at the specified position

  ---

  - **`fn[T] Lens::op_set(self, col, elem) -> Unit`**
    - **Description**
        Sets the value at the specified column index in the accessor

    - **Parameters**
      - `self: Lens[T]` - Accessor to modify
      - `col: Int` - Column index
      - `elem: T` - Value to set

    - **Returns**
      `Unit` - No return value

---

## Operator Overloading

### Arithmetic Operators

- **`impl[T : Mul + Add] Mul for Matrix[T] with op_mul`**
  - **Description**
      Matrix multiplication operator overload, computes the product of two matrices

  - **Example**

    ```moonbit
    let a = Matrix::from_2d_array([[1, 2], [3, 4]])
    let b = Matrix::from_2d_array([[5, 6], [7, 8]])
    let result = a * b  // Matrix multiplication
    ```

- **`impl[T : Add] Add for Matrix[T] with op_add`**
  - **Description**
      Matrix addition operator overload, computes element-wise addition of two matrices

  - **Example**

    ```moonbit
    let m1 = Matrix::from_2d_array([[1, 2], [3, 4]])
    let m2 = Matrix::from_2d_array([[5, 6], [7, 8]])
    let result = m1 + m2  // Matrix addition
    ```

- **`impl[T : Add + Neg] Sub for Matrix[T] with op_sub`**
  - **Description**
      Matrix subtraction operator overload, computes element-wise subtraction of two matrices

  - **Example**

    ```moonbit
    let m1 = Matrix::from_2d_array([[5, 7], [9, 11]])
    let m2 = Matrix::from_2d_array([[1, 2], [3, 4]])
    let result = m1 - m2  // Matrix subtraction
    ```

- **`impl[T : Neg] Neg for Matrix[T] with op_neg`**
  - **Description**
      Matrix negation operator overload, negates all elements of the matrix

  - **Example**

    ```moonbit
    let m = Matrix::from_2d_array([[1, -2], [3, -4]])
    let negated = -m  // Matrix negation
    ```

### Display and Output

- **`impl[T : Show] Show for Matrix[T] with to_string`**
  - **Description**
      Converts matrix to a readable string representation

  - **Example**

    ```moonbit
    let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
    inspect(m.to_string(), content="|1, 2, 3|\n|4, 5, 6|")
    ```

- **`impl[T : Show] Show for Matrix[T] with output`**
  - **Description**
      Outputs the string representation of the matrix to a logger

### Index Access

- **`Matrix::op_get(self, row) -> Lens[T]`**
  - **Description**
      Uses bracket syntax to access matrix rows, returns an accessor object for that row

  - **Example**

    ```moonbit
    let m = Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
    let row_lens = m[1]  // Get accessor for row 2
    let value = row_lens[0]  // Access element at column 1 of that row
    row_lens[2] = 10  // Modify element at column 3 of that row
    ```

---

## @mutable.Transpose[T]

```moonbit
pub struct Transpose[T](Matrix[T])
```

- **Description**
  A transpose view of a matrix, providing transposed access to the underlying matrix without copying data.

- **Methods**

  - **`fn[T] row(self : Transpose[T]) -> Int`**
    - **Returns**: Number of rows (equals number of columns in original matrix).

  - **`fn[T] col(self : Transpose[T]) -> Int`**
    - **Returns**: Number of columns (equals number of rows in original matrix).

  - **`fn[T] transpose(self : Transpose[T]) -> Matrix[T]`**
    - **Returns**: Since Transpose is a view of a Matrix, calling transpose again returns the original `Matrix[T]`.

  - **`fn[T] materialize(self : Transpose[T]) -> Matrix[T]`**
    - **Returns**: Creates a new `Matrix[T]` with a physically transposed data layout.

  - **`fn[T] map_in_place(self : Transpose[T], f : (T) -> T) -> Unit`**
    - **Action**: Modifies the underlying matrix data in-place.

  - **`fn[T] Transpose::op_get(self : Transpose[T], row : Int) -> Lens[T]`**
    - **Description**: Returns a row accessor for the specified row. Supports `t[row][col]` syntax.

### Operator Overloading for Transpose

- **`impl[T : Add + Mul] Mul for Transpose[T] with mul`**
  - **Description**: Matrix multiplication for transposed matrices. Returns `Transpose[T]`.

- **`impl[T : Add] Add for Transpose[T] with add`**
  - **Description**: Matrix addition for transposed matrices. Returns `Transpose[T]`.

- **`impl[T : Add + Neg] Sub for Transpose[T] with sub`**
  - **Description**: Matrix subtraction for transposed matrices. Returns `Transpose[T]`.

- **`impl[T : Neg] Neg for Transpose[T] with neg`**
  - **Description**: Matrix negation for transposed matrices. Returns `Transpose[T]`.

- **`impl[T : Eq] Eq for Transpose[T] with equal`**
  - **Description**: Equality check for transposed matrices.

- **`impl[T : Show] Show for Transpose[T] with to_string`**
  - **Description**: String representation of transposed matrix.
  - **`fn[T] Transpose::op_get(self, row) -> Lens[T]`**
    - **Description**
        Gets an accessor for the specified row of the transpose view.

    - **Performance Note**
        Calling `t[row]` involves allocation overhead. When processing row data in a loop, it is recommended to cache the result using `let row = t[i]`.
