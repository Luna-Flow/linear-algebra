# container API

## Purpose

`Luna-Flow/linear-algebra/container` describes how generic code observes,
builds and edits linear containers without knowing their storage. A capability
is an *operation dictionary*: a record of functions for one container type `V`
or `M` and one element type `T`. Five generic algorithms (map, convert and
transpose) are written against these dictionaries. Ready-made dictionaries for
the repository's own types are in [`container/adapters`](container/adapters.md).

Source: [`src/container/vector_ops.mbt`](../../../src/container/vector_ops.mbt),
[`src/container/matrix_ops.mbt`](../../../src/container/matrix_ops.mbt),
[`src/container/generic_algorithms.mbt`](../../../src/container/generic_algorithms.mbt).
The model is explained in the [container design](../design/container.md); the
[integration guide](../integration/container.md) shows how external libraries
publish dictionaries.

> [!WARNING]
> `container` is experimental. Record fields, error contracts and algorithm
> signatures may change incompatibly before the package is declared stable.

## Importing

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/container",
  "Luna-Flow/linear-algebra/container/adapters" @container_adapters,
  "Luna-Flow/linear-algebra/error" @la_error,
}
```

The examples on this page write every name with its package prefix, such as
`@container.`, instead of a `using` declaration: all pages of this manual
compile into one test package, where the declarations of different pages
would clash.

## Contracts shared by all dictionaries

Every function in a dictionary is checked: it returns a `Result` and must not
abort for any argument.

- A read or edit at an index outside the shape returns an error of kind
  `IndexOutOfBounds`.
- A build with a negative length or dimension returns an error of kind
  `NegativeDimension` and does not call the initializer.
- Degenerate shapes $0 \times n$ and $n \times 0$ are valid and must be
  preserved exactly; they are not the same as $0 \times 0$.
- Matrix coordinates are `(row, col)`, zero-based. Builders call the
  initializer with `(row, col)`.

The record fields are public and readable. Call a field as a function with
parentheses around the field access: `(ops.get)(m, 0, 1)`.

## Vector dictionaries

### `VectorReadOps`

`VectorReadOps[V, T]` observes a vector-like container `V` with elements `T`.

```mbti
pub struct VectorReadOps[V, T] {
  length : (V) -> Int
  get : (V, Int) -> Result[T, @error.LinearAlgebraError]
}
```

`length(v)` returns the number of elements $n \ge 0$; `get(v, i)` returns
element $i$ for $0 \le i < n$ and `IndexOutOfBounds` otherwise.

### `VectorReadOps::new`

`VectorReadOps::new(length, get)` builds a read dictionary from two functions.

```mbti
pub fn[V, T] VectorReadOps::new((V) -> Int, (V, Int) -> Result[T, @error.LinearAlgebraError]) -> Self[V, T]
```

### `VectorBuildOps`

`VectorBuildOps[V, T]` constructs vectors of type `V` from an index function.

```mbti
pub struct VectorBuildOps[V, T] {
  tabulate : (Int, (Int) -> T) -> Result[V, @error.LinearAlgebraError]
}
```

`tabulate(n, f)` returns the vector $(f(0), \dots, f(n-1))$, or
`NegativeDimension` for $n < 0$.

### `VectorBuildOps::new`

`VectorBuildOps::new(tabulate)` builds a build dictionary.

```mbti
pub fn[V, T] VectorBuildOps::new((Int, (Int) -> T) -> Result[V, @error.LinearAlgebraError]) -> Self[V, T]
```

### `VectorPersistentEditOps`

`VectorPersistentEditOps[V, T]` replaces one element and returns a new value.

```mbti
pub struct VectorPersistentEditOps[V, T] {
  set : (V, Int, T) -> Result[V, @error.LinearAlgebraError]
}
```

`set(v, i, x)` returns a vector equal to `v` except at index $i$, where it holds
`x`. The argument `v` must remain unchanged, even if the implementation shares
storage between versions.

### `VectorPersistentEditOps::new`

`VectorPersistentEditOps::new(set)` builds a persistent-edit dictionary.

```mbti
pub fn[V, T] VectorPersistentEditOps::new((V, Int, T) -> Result[V, @error.LinearAlgebraError]) -> Self[V, T]
```

### `VectorMutableEditOps`

`VectorMutableEditOps[V, T]` replaces one element in place.

```mbti
pub struct VectorMutableEditOps[V, T] {
  set : (V, Int, T) -> Result[Unit, @error.LinearAlgebraError]
}
```

`set(v, i, x)` writes `x` at index $i$ of `v`. On error nothing is written.

### `VectorMutableEditOps::new`

`VectorMutableEditOps::new(set)` builds a mutable-edit dictionary.

```mbti
pub fn[V, T] VectorMutableEditOps::new((V, Int, T) -> Result[Unit, @error.LinearAlgebraError]) -> Self[V, T]
```

## Matrix dictionaries

### `MatrixReadOps`

`MatrixReadOps[M, T]` observes a matrix-like container.

```mbti
pub struct MatrixReadOps[M, T] {
  shape : (M) -> (Int, Int)
  get : (M, Int, Int) -> Result[T, @error.LinearAlgebraError]
}
```

`shape(m)` returns `(rows, cols)`; `get(m, r, c)` returns entry $(r, c)$ or
`IndexOutOfBounds`.

### `MatrixReadOps::new`

`MatrixReadOps::new(shape, get)` builds a matrix read dictionary.

```mbti
pub fn[M, T] MatrixReadOps::new((M) -> (Int, Int), (M, Int, Int) -> Result[T, @error.LinearAlgebraError]) -> Self[M, T]
```

### `MatrixBuildOps`

`MatrixBuildOps[M, T]` constructs matrices from a coordinate function.

```mbti
pub struct MatrixBuildOps[M, T] {
  tabulate : (Int, Int, (Int, Int) -> T) -> Result[M, @error.LinearAlgebraError]
}
```

`tabulate(r, c, f)` returns the matrix with entries $f(i, j)$, or
`NegativeDimension` when $r < 0$ or $c < 0$.

### `MatrixBuildOps::new`

`MatrixBuildOps::new(tabulate)` builds a matrix build dictionary.

```mbti
pub fn[M, T] MatrixBuildOps::new((Int, Int, (Int, Int) -> T) -> Result[M, @error.LinearAlgebraError]) -> Self[M, T]
```

### `MatrixPersistentEditOps`

`MatrixPersistentEditOps[M, T]` replaces one entry and returns a new matrix,
leaving the argument unchanged.

```mbti
pub struct MatrixPersistentEditOps[M, T] {
  set : (M, Int, Int, T) -> Result[M, @error.LinearAlgebraError]
}
```

### `MatrixPersistentEditOps::new`

`MatrixPersistentEditOps::new(set)` builds a persistent-edit dictionary.

```mbti
pub fn[M, T] MatrixPersistentEditOps::new((M, Int, Int, T) -> Result[M, @error.LinearAlgebraError]) -> Self[M, T]
```

### `MatrixMutableEditOps`

`MatrixMutableEditOps[M, T]` replaces one entry in place.

```mbti
pub struct MatrixMutableEditOps[M, T] {
  set : (M, Int, Int, T) -> Result[Unit, @error.LinearAlgebraError]
}
```

### `MatrixMutableEditOps::new`

`MatrixMutableEditOps::new(set)` builds a mutable-edit dictionary.

```mbti
pub fn[M, T] MatrixMutableEditOps::new((M, Int, Int, T) -> Result[Unit, @error.LinearAlgebraError]) -> Self[M, T]
```

A dictionary for a plain `Array[Int]`, used through its fields:

```moonbit check
///|
fn cont_api_array_read() -> @container.VectorReadOps[Array[Int], Int] {
  @container.VectorReadOps::new(xs => xs.length(), (xs, i) => {
    guard i >= 0 && i < xs.length() else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds("index \{i}"),
      )
    }
    Ok(xs[i])
  })
}

///|
test "a hand-written read dictionary" {
  let ops = cont_api_array_read()
  inspect((ops.length)([4, 5, 6]), content="3")
  inspect((ops.get)([4, 5, 6], 1).unwrap(), content="5")
  match (ops.get)([4, 5, 6], 3) {
    Err(e) => inspect(e.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("index 3 is out of bounds")
  }
}
```

## Generic algorithms

All algorithms read the whole source first, in row-major order, into a
temporary buffer, and only then call the target's `tabulate`. A read error is
returned before anything is built, so no partially built target is ever
observable. Each runs in $O(n)$ dictionary calls for $n$ elements and uses
$O(n)$ extra memory.

### `vector_map`

`vector_map(source, source_ops, target_ops, f)` builds a vector of the target
type whose element $i$ is `f(source[i])`.

```mbti
pub fn[V1, V2, A, B] vector_map(V1, VectorReadOps[V1, A], VectorBuildOps[V2, B], (A) -> B) -> Result[V2, @error.LinearAlgebraError]
```

It returns `NegativeDimension` if `source_ops.length` reports a negative
length, the first read error otherwise, and finally whatever `tabulate`
returns. `f` is called exactly once per element, in index order, right after
that element is read; if a read fails, `f` has already been called on the
elements before it.

### `vector_convert`

`vector_convert(source, source_ops, target_ops)` copies a vector into another
representation with the same element type.

```mbti
pub fn[V1, V2, T] vector_convert(V1, VectorReadOps[V1, T], VectorBuildOps[V2, T]) -> Result[V2, @error.LinearAlgebraError]
```

It is `vector_map` with the identity function.

### `matrix_map`

`matrix_map(source, source_ops, target_ops, f)` builds a matrix of the same
shape whose entry $(i, j)$ is `f(source[i][j])`.

```mbti
pub fn[M1, M2, A, B] matrix_map(M1, MatrixReadOps[M1, A], MatrixBuildOps[M2, B], (A) -> B) -> Result[M2, @error.LinearAlgebraError]
```

### `matrix_convert`

`matrix_convert(source, source_ops, target_ops)` copies a matrix into another
representation with the same element type and shape.

```mbti
pub fn[M1, M2, T] matrix_convert(M1, MatrixReadOps[M1, T], MatrixBuildOps[M2, T]) -> Result[M2, @error.LinearAlgebraError]
```

### `matrix_transpose`

`matrix_transpose(source, source_ops, target_ops)` builds the transpose of
`source` in the target representation: shape $(c, r)$ for a source of shape
$(r, c)$, entry $(i, j)$ equal to source entry $(j, i)$.

```mbti
pub fn[M1, M2, T] matrix_transpose(M1, MatrixReadOps[M1, T], MatrixBuildOps[M2, T]) -> Result[M2, @error.LinearAlgebraError]
```

Unlike `@algebra.TransposeMatrix::transpose`, the target type may differ from
the source type.

The three matrix algorithms with the repository adapters:

```moonbit check
///|
test "map, convert and transpose across representations" {
  let source = @mutable.Matrix::from_2d_array([[1, 2, 3], [4, 5, 6]])
  let read = @container_adapters.mutable_matrix_read_ops()
  let doubled : @immut.Matrix[Int] = @container.matrix_map(
    source,
    read,
    @container_adapters.immutable_matrix_build_ops(),
    x => x * 2,
  ).unwrap()
  inspect(doubled, content="|2, 4, 6|\n|8, 10, 12|")
  let as_text : @immut.Matrix[String] = @container.matrix_map(
    source,
    read,
    @container_adapters.immutable_matrix_build_ops(),
    x => "<\{x}>",
  ).unwrap()
  inspect(as_text[1][2], content="<6>")
  let t : @immut.Matrix[Int] = @container.matrix_transpose(
    source,
    read,
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(t, content="|1, 4|\n|2, 5|\n|3, 6|")
  let copy : @mutable.Matrix[Int] = @container.matrix_convert(
    t,
    @container_adapters.immutable_matrix_read_ops(),
    @container_adapters.mutable_matrix_build_ops(),
  ).unwrap()
  debug_inspect(copy.shape(), content="(3, 2)")
}
```

The vector algorithms work the same way:

```moonbit check
///|
test "vector map and convert" {
  let v = @immut.Vector::from_array([1, 2, 3])
  let squares : @mutable.Vector[Int] = @container.vector_map(
    v,
    @container_adapters.immutable_vector_read_ops(),
    @container_adapters.mutable_vector_build_ops(),
    x => x * x,
  ).unwrap()
  inspect(squares, content="|1, 4, 9|")
  let back : @immut.Vector[Int] = @container.vector_convert(
    squares,
    @container_adapters.mutable_vector_read_ops(),
    @container_adapters.immutable_vector_build_ops(),
  ).unwrap()
  inspect(back, content="|1, 4, 9|")
}
```
