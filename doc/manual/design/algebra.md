# algebra design

## Design goal

`algebra` gives generic linear-algebra code a vocabulary for whole vector and
matrix objects that is honest about what each object can do. A trait may only
be implemented by a type that satisfies its laws, and an algorithm should be
able to ask for exactly the structure it uses: a shape, an abelian group, a
Hadamard ring, a transpose, or a matrix product. The package therefore defines
small traits ordered by inclusion instead of one `Matrix` or `VectorSpace`
trait. The [API page](../api/algebra.md) lists the traits; this page explains
the mathematics they encode and the choices that follow from it.

## Constraints

- MoonBit traits have one `Self` parameter and no associated types, so a
  trait cannot name the scalar type of a vector or matrix.
- MoonBit has no type-level naturals, so dimensions are runtime values and
  shape mismatches cannot be rejected by the type checker.
- The package must not import any concrete type, so that external libraries
  can implement the traits without depending on `immut` or `mutable`.
- The traits must reuse MoonBit's operator traits (`Add`, `Neg`, `Sub`, `Mul`)
  so that implementations keep their `+`, `-` and `*` syntax.

## Design decisions

### Abelian group instead of module

**Problem.** The natural trait for "a vector" is an $R$-module, but a module
has two carriers: the vectors and the scalars.

**Options.** (a) A `Module` trait whose scalar type is fixed, for example
`Double`. (b) A trait with an associated scalar type. (c) Only the additive
structure, leaving scalars to concrete methods.

**Decision.** (c): `AdditiveVector` and `AdditiveMatrix` state the abelian
group $(V, +, -)$ and nothing about scalars.

**Why.** MoonBit traits have a single `Self` parameter and no associated types,
so option (b) cannot be expressed. Option (a) would make every module over
`Int`, `BigInt` or a user scalar type unrepresentable, and would hard-code one
floating-point type into a public trait. Scalar multiplication therefore stays
a method of the concrete types (`scale`, `left_scale`, `right_scale`) where the
scalar type is known.

### No zero in the vector traits

A runtime-shaped vector type has no single zero: the identity of $(R^n, +)$
depends on $n$. A trait method `zero() -> Self` would have to choose a length.
The traits therefore ask for `Add`, `Neg` and `Sub` only, and the group laws
are stated without a named zero:

$$
(u + (-u)) + v = v \quad\text{for all } v \text{ of the same length as } u .
$$

The element $u + (-u)$ is the zero of the right length. The upstream `Zero`
trait from `luna-generic` remains available for scalar types, where a single
zero exists.

### Hadamard product as its own level

`Mul` on a vector type could mean the Hadamard product, a dot product, or a
cross product, and only the first is closed ($R^n \times R^n \to R^n$ for all
$n$). `VecMulVector` fixes the meaning to the Hadamard product and lives above
`AdditiveVector`, so an algorithm that only adds vectors does not exclude types
without a product. Scalar-valued products such as the dot product are maps
$R^n \times R^n \to R$ out of the category of vectors; they are methods of the
concrete backends (`DenseVector::dot`), not structure traits.

### Matrix multiplication is partial and documented, not typed

**Problem.** On a runtime-shaped matrix type, `*` is defined only for
composable shapes. A trait method returning `Self` cannot report failure.

**Options.** (a) Put `Mul` into the smallest matrix trait. (b) Encode shapes in
types. (c) Separate shape, transpose and addition from multiplication, and let
each implementation document the behaviour outside the domain.

**Decision.** (c). `TransposeMatrix` and `AdditiveMatrix` are useful without
multiplication, and `MatMulMatrix` is a separate level whose implementors must
document their failure behaviour. A type with statically known shapes, such as
a fixed $1 \times 1$ or $3 \times 3$ matrix, implements `MatMulMatrix` with a
total `*`.

**Why.** MoonBit has no type-level naturals, so (b) is not available for
dynamic dimensions. Option (a) would force a partial operation onto every
matrix type, including ones that never multiply. Checked multiplication with a
`Result` remains available on the concrete types (`@immut.Matrix::matmul`),
where the error type is fixed.

### Transpose returns `Self`

`TransposeMatrix::transpose` returns the same type. Transpose is total on every
shape, so it is a closed operation and fits a trait method. Whether the result
is materialized or a view is not part of the contract; the
[`container`](container.md) layer, by contrast, has a transpose that may
produce a different target type.

## Mathematical background

### Modules and vector spaces

Let $R$ be a ring with unit. A (left) $R$-module is an abelian group
$(V, +, 0, -)$ together with a scalar action $R \times V \to V$,
$(r, v) \mapsto r v$, such that for all $r, s \in R$ and $u, v \in V$

$$
\begin{aligned}
r(u + v) &= r u + r v, & (r + s) v &= r v + s v, \\
(r s) v &= r (s v), & 1 v &= v .
\end{aligned}
$$

A vector space is a module over a field. Most of linear algebra is stated for
vector spaces, but most of the *code* only needs much less: matrix addition
needs the abelian group, matrix multiplication needs a semiring of scalars, and
only elimination needs division. Integer matrices, for example, form a
$\mathbb{Z}$-module and are not a vector space; requiring a field would exclude
them from algorithms that never divide.

### Coordinates

A dense vector of length $n$ over $R$ is an element of $R^n$, a dense
$m \times n$ matrix an element of $R^{m \times n}$. Entry-wise addition makes
both abelian groups; the scalar action $r \cdot (a_{ij}) = (r a_{ij})$ makes
them $R$-modules. For fixed $n$, the entry-wise product

$$
(u \odot v)_i = u_i v_i
$$

makes $R^n$ a ring as well (the product ring), with unit $(1, \dots, 1)$.

### Matrices as a category

Matrix multiplication is not an operation on one set. Its shape rule

$$
(m \times n) \cdot (n \times p) = m \times p
$$

says that matrices are the morphisms of a category $\mathbf{Mat}_R$ whose
objects are the natural numbers: an $m \times n$ matrix is an arrow
$n \to m$, multiplication is composition, and the identity matrix $I_n$ is the
identity arrow on $n$. A product $AB$ is defined exactly when the arrows are
composable. Over a fixed object $n$ the arrows $n \to n$ (the square matrices)
form a ring, the familiar $M_n(R)$.

Associativity of composition holds whenever $R$ is a semiring. For
$A \in R^{m \times n}$, $B \in R^{n \times p}$, $C \in R^{p \times q}$:

$$
\begin{aligned}
\big((AB)C\big)_{il}
  &= \sum_{k=1}^{p} (AB)_{ik} C_{kl}
   = \sum_{k=1}^{p} \Big(\sum_{j=1}^{n} A_{ij} B_{jk}\Big) C_{kl} \\
  &= \sum_{k=1}^{p} \sum_{j=1}^{n} A_{ij} B_{jk} C_{kl}
   && \text{right distributivity, associativity of } \cdot \\
  &= \sum_{j=1}^{n} \sum_{k=1}^{p} A_{ij} B_{jk} C_{kl}
   && \text{associativity and commutativity of } + \\
  &= \sum_{j=1}^{n} A_{ij} \Big(\sum_{k=1}^{p} B_{jk} C_{kl}\Big)
   = \big(A(BC)\big)_{il}
   && \text{left distributivity.}
\end{aligned}
$$

Commutativity of multiplication was never used, so the law holds for matrices
over any semiring, including non-commutative ones such as quaternions. The
derivation also covers empty inner dimensions: when $n = 0$ or $p = 0$ an inner
sum is the empty sum $0$, and right distributivity over the empty sum is the
absorption law $0 \cdot c = 0$ (and left distributivity gives $a \cdot 0 = 0$),
which every semiring has.[^absorb]

[^absorb]: For rings absorption follows from distributivity,
$0 \cdot c = (0 + 0)c = 0 \cdot c + 0 \cdot c$; for semirings, which lack
subtraction, it is an axiom. The same
computation with $C = I$ shows $AI = A$, and distributivity of the product over
matrix addition follows entry-wise from distributivity in $R$.

### Transpose

The transpose is the map $(A^{\mathsf T})_{ij} = A_{ji}$ from
$R^{m \times n}$ to $R^{n \times m}$. It is total and

$$
(A^{\mathsf T})^{\mathsf T} = A, \qquad
(A + B)^{\mathsf T} = A^{\mathsf T} + B^{\mathsf T} .
$$

The product rule needs more. For composable $A$ and $B$:

$$
\begin{aligned}
\big((AB)^{\mathsf T}\big)_{ik} &= (AB)_{ki} = \sum_j A_{kj} B_{ji}, \\
\big(B^{\mathsf T} A^{\mathsf T}\big)_{ik} &= \sum_j (B^{\mathsf T})_{ij} (A^{\mathsf T})_{jk}
  = \sum_j B_{ji} A_{kj} .
\end{aligned}
$$

The two sums agree term by term exactly when $A_{kj} B_{ji} = B_{ji} A_{kj}$,
that is, when the scalars commute. So
$(AB)^{\mathsf T} = B^{\mathsf T} A^{\mathsf T}$ is a theorem for matrices over
a commutative ring and false in general.[^conj] Transpose is a contravariant
functor $\mathbf{Mat}_R \to \mathbf{Mat}_R$ only in the commutative case.

[^conj]: For a ring with an involution $x \mapsto \bar{x}$ that reverses
products, $\overline{xy} = \bar{y}\,\bar{x}$, the conjugate transpose
$A^{*} = \overline{A}^{\mathsf T}$ does satisfy $(AB)^{*} = B^{*} A^{*}$ without
commutativity, because each term becomes $\overline{A_{kj} B_{ji}} = \overline{B_{ji}}\,\overline{A_{kj}}$.
This is why the concrete matrix types offer `adjoint` next to `transpose`.

## Correctness and invariants

The traits are empty or have one observation method, so correctness is a
property of each implementation. The laws an implementation promises are:

| Level | Laws (whenever both sides are defined) |
| --- | --- |
| `AdditiveVector`, `AdditiveMatrix` | abelian group laws; operations preserve shape |
| `VecMulVector` | $R^n$ is a ring under `+` and `*`: associativity, distributivity |
| `TransposeMatrix` | $\operatorname{shape}(A^{\mathsf T}) = \operatorname{shape}(A)$ reversed; $(A^{\mathsf T})^{\mathsf T} = A$ |
| `AdditiveMatrix` | $(A + B)^{\mathsf T} = A^{\mathsf T} + B^{\mathsf T}$ |
| `MatMulMatrix` | $(AB)C = A(BC)$; distributivity; $(AB)^{\mathsf T} = B^{\mathsf T}A^{\mathsf T}$ if the scalars commute |

Two caveats apply to concrete scalar types.

**Fixed-width integers.** `Int` is the ring $\mathbb{Z}/2^{32}\mathbb{Z}$, not
$\mathbb{Z}$. The laws above hold exactly in that ring, because wrapping
addition and multiplication are the ring operations of
$\mathbb{Z}/2^{32}\mathbb{Z}$; a matrix product that overflows is still the
correct product modulo $2^{32}$.

**Floating point.** `Float` and `Double` are not rings: addition is not
associative under rounding. The laws hold only up to rounding error, and tests
must compare with a tolerance. For an inner product of length $n$ computed in
any order, the standard model $\mathrm{fl}(x \circ y) = (x \circ y)(1 + \delta)$,
$|\delta| \le u$, gives

$$
\big|\mathrm{fl}(AB) - AB\big| \le \gamma_n\, |A|\,|B|,
\qquad \gamma_n = \frac{n u}{1 - n u},
$$

entry-wise, where $u = 2^{-53}$ for `Double`.[^higham] Applying the bound twice,
with inner dimensions $n$ and $p$,

$$
\begin{aligned}
\big|\mathrm{fl}(\mathrm{fl}(AB)\,C) - ABC\big|
&\le \big|\mathrm{fl}(\mathrm{fl}(AB)\,C) - \mathrm{fl}(AB)\,C\big| + \big|(\mathrm{fl}(AB) - AB)\,C\big| \\
&\le \gamma_p\, |\mathrm{fl}(AB)|\,|C| + \gamma_n\, |A|\,|B|\,|C| \\
&\le \big(\gamma_p(1 + \gamma_n) + \gamma_n\big)\, |A|\,|B|\,|C|
 \le \gamma_{n+p}\, |A|\,|B|\,|C| ,
\end{aligned}
$$

using $|\mathrm{fl}(AB)| \le (1 + \gamma_n)|A|\,|B|$ and
$\gamma_a + \gamma_b + \gamma_a\gamma_b \le \gamma_{a+b}$ (Higham, Lemma 3.3).
The same holds for $\mathrm{fl}(A\,\mathrm{fl}(BC))$, so the two evaluation
orders can differ by up to $2\gamma_{n+p}\,|A|\,|B|\,|C|$. This is the scale a
tolerance-based comparison must allow.

[^higham]: N. J. Higham, *Accuracy and Stability of Numerical Algorithms*,
2nd ed., SIAM, 2002, §3.1 and §3.5. The bound follows by applying the model to
each of the $n - 1$ additions and $n$ multiplications of one inner product.

## Alternatives rejected

- **A `VectorSpace` or `Module` trait.** Rejected until scalar association can
  be expressed without fixing a scalar type; see the first decision.
- **A shape-dependent `zero(rows, cols)` method.** It would duplicate the
  upstream `Zero` trait with a different meaning and still could not serve
  generic code that does not know the shape.
- **Inner products and norms as structure traits.** They map into the scalars,
  depend on the scalar type (a norm into `Double` is not a norm into `Int`), and
  have several reasonable choices. They stay backend methods.
- **One `Matrix` trait with every operation.** It would force partial
  multiplication and Hadamard products onto types that do not have them.

## Boundaries

`algebra` does not define scalar traits (those come from `luna-generic` and
`arithmetic`), storage, element access, mutation or construction (those belong
to [`container`](container.md)), checked error reporting, decompositions,
solvers, norms or inner products. It does not provide implementations for the
concrete `@immut` and `@mutable` types; [`backends/default`](backends/default.md)
does that through owned wrapper types.
