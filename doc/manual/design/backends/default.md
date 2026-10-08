# backends/default design

## Design goal

The `algebra` traits are only useful if some real dense type implements them.
`backends/default` provides that reference backend by wrapping the concrete
`@mutable` and `@immut` types, while keeping those concrete packages free of
any dependency on the experimental `algebra` layer. It is a backend, not the
centre of the ecosystem: generic algorithms depend on the traits, and this
package is one way to satisfy them.

## Constraints

- `impl Trait for Type` is allowed only in the package that owns the trait or
  the type.
- `immut` and `mutable` must not depend on the experimental `algebra` layer.
- Wrapping must not copy data or change the semantics of the wrapped
  operations.

## Design decisions

### Owned wrapper types

**Problem.** MoonBit allows `impl Trait for Type` only in the package that owns
the trait or the type. Implementing `@algebra.MatMulMatrix` for
`@mutable.Matrix` would have to happen in `algebra` (which must not know
concrete types) or in `mutable` (which would then depend on the experimental
`algebra` layer).

**Decision.** Define new types `DenseMatrix[T]`, `DenseVector[T]` and their
immutable counterparts in this package, each a struct with one public field
`inner`, and implement the traits for them here.

**Why.** The wrapper is owned by the package that implements the traits, so
the rule is satisfied, and the dependency direction stays
`backends/default → algebra, immut, mutable`. The cost is one indirection in
the type, removed by `inner()` and `from_backend` without copying.

### Backend methods for scalar-valued maps

`dot`, `scale`, `axpy` and `matvec` are methods of the wrappers, not traits:
they involve the scalar type explicitly, which the `algebra` traits cannot name
(see the algebra design). Keeping them as methods lets each backend choose its
own constraints, for example `AddMonoid + Mul` for `dot` on the mutable vector
and `Zero + Add + Mul` on the immutable one.

### `axpy` returns a new vector

The BLAS routine `axpy` updates $y \leftarrow a x + y$ in place. Here
`x.axpy(a, y)` returns $x a + y$ as a new vector for both wrappers, so the
mutable and immutable backends share one value-returning contract. In-place
updates remain available on the inner `@mutable.Vector`.

### Scalars multiply on the right

`scale` uses `right_scale`, computing $v_i a$. For commutative scalars this is
the same as $a v_i$; for non-commutative scalars the choice is visible, and it
is documented rather than hidden.

## Mathematical background

### Instances are evidence of laws

Implementing `@algebra.MatMulMatrix` for a type claims the laws listed in the
[algebra design](../algebra.md): associativity and distributivity of `*` over
`+` wherever defined. For the wrappers these laws are inherited from the
wrapped types, because every operator is defined as "unwrap, apply the inner
operator, wrap":

$$
\mathrm{wrap}(A) \cdot \mathrm{wrap}(B) = \mathrm{wrap}(A \cdot B) .
$$

So `wrap` is a homomorphism for every operation, and any equation that holds
for the inner type holds for the wrapper. The converse matters too: the
wrappers satisfy *only* the laws of the inner type. `MatMulMatrix` for
`DenseMatrix[T]` is implemented for every `T : AddMonoid + Mul`, a bound that
does not require distributivity or associativity of `*` on `T`. The product
laws of the [algebra design](../algebra.md) hold when `T` is a semiring
(`Int`, `BigInt`, ...), hold up to rounding for `Float` and `Double`, and can
fail for a scalar type whose `Mul` is not associative or not distributive; the
instance exists for such a type, but its laws do not. Tightening the bound
is a public API change, tracked as
[#94](https://github.com/Luna-Flow/linear-algebra/issues/94).

### Partiality of the dense product

For runtime-shaped dense matrices the product is defined on
$\{(A, B) : \operatorname{cols}(A) = \operatorname{rows}(B)\}$. The trait
method returns `Self`, so outside that set the wrapper must do something; it
aborts, as the inner type does. This is the documented runtime precondition
that the `MatMulMatrix` contract asks implementations to state.

### Dot product and its rounding error

`dot` computes $s_n = \sum_{i=1}^{n} u_i v_i$ by the recurrence
$s_0 = 0$, $s_i = s_{i-1} + u_i v_i$. In floating point each step multiplies
the error of all earlier terms by another factor $(1 + \delta)$, and the
standard argument gives

$$
\big|\mathrm{fl}(s_n) - s_n\big| \le \gamma_n \sum_{i=1}^{n} |u_i v_i|,
\qquad \gamma_n = \frac{n u}{1 - n u} .
$$

The relative error is therefore small when the terms have the same sign, and
can be large when $\sum |u_i v_i| \gg |s_n|$ (cancellation). `matvec` is $m$
such dot products and inherits the same bound row by row.

## Correctness and invariants

- **Homomorphism.** `inner(a op b) == inner(a) op inner(b)` for every operator
  (for `-` the right side is `inner(a) + -inner(b)`, since the inner vector
  types have no `Sub`), so the wrappers satisfy exactly the laws of the wrapped
  types.
- **No copies on wrapping.** `from_backend(x).inner()` is physically `x`;
  writes to a mutable inner value are visible through the wrapper.
- **Transpose.** `transpose` materializes; it never returns a view, so the
  `TransposeMatrix` law $(A^{\mathsf T})^{\mathsf T} = A$ holds as values.
- **Complexity.** `+`, `-`, `scale`: $O(n)$; `dot`: $n$ multiply-adds; `matvec`:
  $mn$; `*`: $rcn$ multiply-adds; `transpose`: $O(rc)$ copies.

## Alternatives rejected

- **A runtime backend selector** inside one matrix type. It would make every
  operation branch on the backend and hide which kernel runs. Backends are
  chosen by type.
- **Implementing the traits in `immut` and `mutable` directly.** That would tie
  the stable concrete packages to the experimental `algebra` layer.
- **In-place `axpy`.** It would give the two wrappers different semantics for
  the same name.

## Boundaries

`backends/default` defines no new traits and no new numerical algorithms; the
decompositions, inverses and statistics of [`mutable`](../mutable.md) are
reached through `inner()`. It does not provide sparse, lazy, static-size or
GPU backends; those should implement the `algebra` traits for their own types
rather than convert into these wrappers. The native OpenBLAS backend that once
sat beside it is withdrawn in this release and preserved in
`contrib/openblas_backend`.
