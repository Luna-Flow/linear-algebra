# @mutable.Vector

---

## @mutable.Vector[T]

```moonbit
struct Vector[T] {
  length : Int
  data : Array[T]
} derive(Eq)
```

- **Description**
  This struct represents a mutable vector with data stored in a one-dimensional array `data`

- **Fields**
  - `length` - Length of the vector
  - `data` - Vector data storage

- **Methods**

  - **`fn[T] Vector::make(length, f) -> Vector[T]`**
    - **Description**
        Creates a new vector and initializes the vector data using the given function

    - **Parameters**
      - `length: Int` - Length of the vector
      - `f: (Int) -> T` - Function to initialize vector data, parameter is the index

    - **Returns**
      `Vector[T]` - Newly created vector object

  ---

  - **`fn[T] Vector::new(length, elem) -> Vector[T]`**
    - **Description**
        Creates a new vector with all elements initialized to the specified value

    - **Parameters**
      - `length: Int` - Length of the vector
      - `elem: T` - Value to initialize all elements

    - **Returns**
      `Vector[T]` - Newly created vector object

  ---

  - **`fn[T] Vector::from_array(data) -> Vector[T]`**
    - **Description**
        Creates a vector from an array

    - **Parameters**
      - `data: Array[T]` - Array containing vector elements

    - **Returns**
      `Vector[T]` - Newly created vector object

  ---

  - **`fn[T] length(self) -> Int`**
    - **Description**
        Gets the length of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to query

    - **Returns**
      `Int` - Length of the vector

  ---

  - **`fn[T] Vector::op_get(self, index) -> T`**
    - **Description**
        Gets the element at the specified index position in the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to access
      - `index: Int` - Element index (starting from 0)

    - **Returns**
      `T` - Element value at the specified position

  ---

  - **`fn[T] Vector::op_set(self, index, elem) -> Unit`**
    - **Description**
        Sets the element value at the specified index position in the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to modify
      - `index: Int` - Element index (starting from 0)
      - `elem: T` - New value to set

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T, U] Vector::map(self, f) -> Vector[U]`**
    - **Description**
        Applies a function to each element of the vector, creating a new vector

    - **Parameters**
      - `self: Vector[T]` - Input vector
      - `f: (T) -> U` - Function to apply to each element

    - **Returns**
      `Vector[U]` - New vector containing transformed elements

  ---

  - **`fn[T] Vector::map_inplace(self, f) -> Unit`**
    - **Description**
        Applies a transformation function to each element of the vector in-place, modifying the original vector

    - **Parameters**
      - `self: Vector[T]` - Vector to modify
      - `f: (T) -> T` - Transformation function to apply to each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Vector::each(self, f) -> Unit`**
    - **Description**
        Executes a function for each element of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to traverse
      - `f: (T) -> Unit` - Function to execute for each element

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Vector::eachi(self, f) -> Unit`**
    - **Description**
        Executes a function for each element of the vector and its index

    - **Parameters**
      - `self: Vector[T]` - Vector to traverse
      - `f: (Int, T) -> Unit` - Function to execute for each element and its index

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] Vector::copy(self) -> Vector[T]`**
    - **Description**
        Creates a deep copy of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to copy

    - **Returns**
      `Vector[T]` - Independent copy of the original vector

  ---

  - **`fn[T : Mul] scale(self, cst) -> Vector[T]`**
    - **Description**
        Multiplies each element of the vector by a scalar value

    - **Parameters**
      - `self: Vector[T]` - Vector to scale
      - `cst: T` - Scalar value

    - **Returns**
      `Vector[T]` - New scaled vector

  ---

  - **`fn[T : Add] add_constant(self, cst) -> Vector[T]`**
    - **Description**
        Adds a constant value to each element of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to modify
      - `cst: T` - Constant value to add

    - **Returns**
      `Vector[T]` - New vector after addition operation

  ---

  - **`fn[T : Compare + Zero] null(self) -> Bool`**
    - **Description**
        Checks if the vector is a zero vector (all elements are zero)

    - **Parameters**
      - `self: Vector[T]` - Vector to check

    - **Returns**
      `Bool` - Returns true if it's a zero vector, false otherwise

  ---

  - **`fn[T : Conjugate] conjugate(self) -> Vector[T]`**
    - **Description**
        Computes the conjugate of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to compute conjugate for

    - **Returns**
      `Vector[T]` - Conjugate vector

  ---

  - **`fn[T : Add + Mul] dot(self, other) -> T`**
    - **Description**
        Computes the dot product (inner product) of two vectors

    - **Parameters**
      - `self: Vector[T]` - First vector
      - `other: Vector[T]` - Second vector

    - **Returns**
      `T` - Dot product result

  ---

  - **`fn[T : Add + Mul + Zero] norm_squared(self) -> T`**
    - **Description**
        Computes the squared magnitude of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to compute for

    - **Returns**
      `T` - Squared magnitude

  ---

  - **`fn[T : Add + Mul + Zero + Sqrt] norm(self) -> T`**
    - **Description**
        Computes the magnitude (Euclidean norm) of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to compute for

    - **Returns**
      `T` - Vector magnitude

  ---

  - **`fn[T : Add + Mul + Zero + Sqrt + Div] normalize(self) -> Vector[T]`**
    - **Description**
        Computes the unit vector of the vector

    - **Parameters**
      - `self: Vector[T]` - Vector to normalize

    - **Returns**
      `Vector[T]` - Normalized unit vector

  ---

  - **`fn[T : Add + Mul + Zero + Sqrt + Div] normalize_inplace(self) -> Unit`**
    - **Description**
        Normalizes the vector to a unit vector in-place

    - **Parameters**
      - `self: Vector[T]` - Vector to normalize

    - **Returns**
      `Unit` - No return value

  ---

  - **`fn[T] to_array(self) -> Array[T]`**
    - **Description**
        Converts the vector to an array

    - **Parameters**
      - `self: Vector[T]` - Vector to convert

    - **Returns**
      `Array[T]` - Array containing all vector elements

  ---
  
  - **`fn[T] Vector::op_get(self, index) -> T`**
    - **Description**
        Accesses vector elements using bracket syntax

    - **Example**

      ```moonbit
      let v = Vector::from_array([1, 2, 3])
      let value = v[1]  // Get element at index 1, value is 2
      ```

  - **`fn[T] Vector::op_set(self, index, elem) -> Unit`**
    - **Description**
        Sets vector elements using bracket syntax

    - **Example**

      ```moonbit
      let v = Vector::from_array([1, 2, 3])
      v[1] = 10  // Set element at index 1 to 10
      ```

- **Trait Implementations**
  
  **Operator Overloading**

  - **`impl[T : Add] Add for Vector[T] with op_add`**
    - **Description**
        Vector addition operator overload, computes element-wise addition of two vectors

    - **Example**

      ```moonbit
      let v1 = Vector::from_array([1, 2, 3])
      let v2 = Vector::from_array([4, 5, 6])
      let result = v1 + v2  // Vector addition
      ```

  ---

  - **`impl[T : Add + Neg] Sub for Vector[T] with op_sub`**
    - **Description**
        Vector subtraction operator overload, computes element-wise subtraction of two vectors

    - **Example**

      ```moonbit
      let v1 = Vector::from_array([5, 7, 9])
      let v2 = Vector::from_array([1, 2, 3])
      let result = v1 - v2  // Vector subtraction
      ```

  ---

  - **`impl[T : Neg] Neg for Vector[T] with op_neg`**
    - **Description**
        Vector negation operator overload, negates all elements of the vector

    - **Example**

      ```moonbit
      let v = Vector::from_array([1, -2, 3])
      let negated = -v  // Vector negation
      ```

  **Display and Output**

  - **`impl[T : Show] Show for Vector[T] with to_string`**
    - **Description**
        Converts vector to a readable string representation

    - **Example**

      ```moonbit
      let v = Vector::from_array([1, 2, 3])
      inspect(v.to_string(), content="[1, 2, 3]")
      ```

  ---

  - **`impl[T : Show] Show for Vector[T] with output`**
    - **Description**
        Outputs the string representation of the vector to a logger

---