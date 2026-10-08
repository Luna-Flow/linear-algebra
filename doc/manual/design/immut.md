# immut design

## Design goal

`immut` gives linear algebra with value semantics: a matrix or vector, once
built, never changes, and every operation returns a new value. Programs can
then keep old versions, share values freely between components and reason
about code by substitution. The package also aims to compute *exactly* whenever
the scalar type allows it, so that integer and big-integer matrices get exact
determinants and powers rather than floating-point approximations.

## Mathematical background

### Value semantics and referential transparency

An expression is referentially transparent when it can be replaced by its
value without changing the program. With immutable matrices,

$$
\texttt{let } B = A.\mathtt{set}(i, j, x) \;\Longrightarrow\;
A \text{ is the same value before and after,}
$$

so any expression mentioning $A$ means the same thing on either side of the
update. Algebraic identities can then be used directly as program
transformations: $(A + B) + C$ and $A + (B + C)$ denote the same value for
exact scalars, and an intermediate result may be reused or recomputed at will.

### Persistent storage

Entries live in row-major order in `moonbitlang/core/immut/vector`, a
persistent vector implemented as a trie with branching factor 32. Replacing
one element copies the path from the root to the leaf and shares every other
node, so

$$
\text{cost}(\mathtt{set}) = O(\log_{32} N), \qquad
\text{extra memory} = O(\log_{32} N), \qquad N = rc ,
$$

and the old matrix stays valid. Reads also cost $O(\log_{32} N)$; at most seven
levels cover $2^{32}$ elements. Whole-matrix operations rebuild the trie in
$O(N)$.

### Matrix powers by repeated squaring

For a square matrix over a semiring, write $k = \sum_t b_t 2^t$ in binary. Then

$$
A^{k} = \prod_{t : b_t = 1} A^{2^t}, \qquad A^{2^{t+1}} = \big(A^{2^t}\big)^2 ,
$$

which needs at most $\lfloor \log_2 k \rfloor$ squarings and as many extra
products, instead of $k - 1$ products. The rearrangement of the product is
valid because matrix multiplication is associative over any semiring (see the
[algebra design](algebra.md)); commutativity of the scalars is not needed,
since all factors are powers of the same $A$. `pow` keeps a state $S$, an
exponent $e$ and a base $B$ with the invariant

$$
S \cdot B^{e} = A^{k},
$$

initially $(I, k, A)$; each step either multiplies $S$ by $B$ when $e$ is odd,
then halves $e$ and squares $B$. The invariant is preserved, and when $e = 0$
the state is $A^k$. For fixed-width integers the result is exact in
$\mathbb{Z}/2^{32}\mathbb{Z}$ even when it overflows, because wrapping
arithmetic *is* the ring arithmetic of that quotient.

### Fraction-free determinant

Gaussian elimination over a field computes $\det A$ as the product of pivots
but divides at every step, which leaves the integers. Bareiss' algorithm keeps
every intermediate value an integer.[^bareiss] Let $a^{(-1)}_{-1,-1} = 1$,
$a^{(0)}_{ij} = a_{ij}$, and for $k = 0, 1, \dots, n-2$ and $i, j > k$

$$
a^{(k+1)}_{ij} =
\frac{a^{(k)}_{kk}\, a^{(k)}_{ij} - a^{(k)}_{ik}\, a^{(k)}_{kj}}{a^{(k-1)}_{k-1,k-1}} .
$$

By Sylvester's determinant identity, each $a^{(k)}_{ij}$ equals the minor of
$A$ formed by rows $0, \dots, k-1, i$ and columns $0, \dots, k-1, j$:

$$
a^{(k)}_{ij} = \det
\begin{pmatrix}
a_{00} & \cdots & a_{0,k-1} & a_{0j} \\
\vdots & & \vdots & \vdots \\
a_{k-1,0} & \cdots & a_{k-1,k-1} & a_{k-1,j} \\
a_{i0} & \cdots & a_{i,k-1} & a_{ij}
\end{pmatrix}.
$$

Two consequences follow. First, the division in the recurrence is *exact*: the
numerator is a multiple of the previous pivot, so over an integral domain such
as $\mathbb{Z}$ the quotient is again in the domain. Second, the last value is
the full determinant, $a^{(n-1)}_{n-1,n-1} = \det A$. The proof of the identity
is in the attachment below.

[Bareiss elimination: exactness and correctness](../../attachments/design_immut_bareiss.typ)

Pivoting fits in without breaking exactness. Row $i$ of $a^{(k)}$ depends only
on row $i$ of $A$ and on rows $0, \dots, k-1$, so exchanging two rows with
indices $\ge k$ before step $k$ is the same as running the algorithm on $A$
with those rows exchanged, which multiplies the final result by $-1$. If the
whole column below the pivot is zero, those minors vanish, the rows are
linearly dependent, and $\det A = 0$.

Every intermediate value is a minor of $A$, so Hadamard's inequality bounds
them all:

$$
\big|a^{(k)}_{ij}\big| \le \prod_{r} \lVert \text{row}_r \rVert_2
$$

over the $k + 1$ rows involved. The numerator of the recurrence is a difference
of two products of such minors, so it is bounded by twice the square of that
product. This gives
an overflow criterion for `Int`: if $H = \prod_r \max(1, \lVert \text{row}_r \rVert_2)$
satisfies $2H^2 < 2^{31}$, no intermediate value overflows and the result is
exact (for `Int64`, $2H^2 < 2^{63}$). For `BigInt` the algorithm is always
exact, every intermediate integer is bounded by $2H^2$, and it uses $O(n^3)$
arithmetic operations.

[^bareiss]: E. H. Bareiss, "Sylvester's identity and multistep integer-preserving
Gaussian elimination", *Mathematics of Computation* 22 (1968), 565–578.

For $n \le 4$ the package uses closed formulas instead. For $n = 3$ it is the
cofactor expansion along the first row; for $n = 4$ it is Laplace's expansion
along the first two rows,

$$
\det A = \sum_{\{p<q\}} (-1)^{p+q+1}\,
\det A_{\{0,1\},\{p,q\}}\, \det A_{\{2,3\},\overline{\{p,q\}}} ,
$$

six products of complementary $2 \times 2$ minors. These formulas use only ring
operations, so they are exact for every ring and need no division at all.

### Lazy matrices

A `MatrixFn` is a pair $(\text{shape}, f)$ with $f : [r] \times [c] \to T$.
Operations compose functions: $\mathtt{map}(g)$ is $g \circ f$, transpose is
$f \circ \mathrm{swap}$, and the product is

$$
(f \cdot g)(i, k) = \sum_{j} f(i, j)\, g(j, k) ,
$$

evaluated on demand. Nothing is cached, so the cost of one entry of a product
is the inner dimension times the cost of entries of the factors. A product
tree of depth $d$ over $n \times n$ matrices therefore costs $O(n^{d})$ per
entry: lazy powers are cheap to build and expensive to read.

## Design decisions

### Persistent vector storage

**Options.** (a) A copied `Array` per update, (b) a persistent trie,
(c) functions only. **Decision.** (b) for `Matrix` and `Vector`, (c) offered
separately as `MatrixFn`. **Why.** A copied array makes `set` cost $O(N)$; a
trie makes it $O(\log_{32} N)$ while keeping reads fast and the value
immutable. Functions are useful for structured or symbolic matrices, but their
read cost depends on the history of operations, so they are a separate type
whose cost model is stated rather than hidden.

### Exact algorithms where the scalar allows them

`determinant` asks only for `Compare + Num + Div`, not for a field, so it
accepts `Int`, `Int64` and `BigInt`. With Bareiss elimination the result is
exact over those types; over `Double` it behaves like elimination with scaled
pivots. The [`mutable`](mutable.md) package, which targets floating point,
uses LU with partial pivoting and a tolerance instead.

### Checked short names, unchecked explicit names

`matmul`, `trace`, `determinant` and `pow` return `Result`; their
`unchecked_*` partners abort. The operators `+`, `-`, `*` cannot return
`Result` and abort on mismatched shapes. The checked form validates and then
calls the unchecked one, which gives the law
`checked(x) == Ok(unchecked(x))` on the domain by construction.

### Alignment with `mutable`

Names, argument order and checked/unchecked conventions match `@mutable`
wherever both packages offer an operation, and the
[`consistency`](consistency.md) tests compare their results. Differences are
deliberate and listed here:

| Operation | `immut` | `mutable` |
| --- | --- | --- |
| identity | `Matrix::identity(n)` | top-level `identity(n)` |
| update | `set` returns a new matrix | `set` writes in place |
| `m[r][c] = x` | not available | available |
| determinant | Bareiss, exact over integral domains | LU with tolerance, floating point |
| decompositions, inverse, statistics | not available | available |
| `dot` | not on `Vector` (see `ImmutableDenseVector::dot`) | `Vector::dot` |

### No subtraction on `Vector`

`Vector` implements `Add`, `Mul` and `Neg` but not `Sub`; `u - v` is written
`u + -v`. This is an asymmetry inherited from earlier releases, not a
mathematical statement. The `backends/default` wrappers provide `-`.

## Correctness and invariants

- **Immutability.** No public operation modifies an existing `Matrix`,
  `Vector` or `MatrixFn`; `set` and `swap_*` return new values.
- **Shape invariants.** $r, c \ge 0$ and the backing vector has exactly $rc$
  elements; constructors reject anything else by aborting.
- **Bounds.** Every public read checks row and column separately, so a column
  index that would land inside the next row is rejected rather than read.
- **Exactness.** Over `BigInt`, `determinant` and `pow` are exact; over `Int`
  and `Int64`, `pow` is exact modulo $2^{w}$ and `determinant` is exact unless
  a minor overflows (see the Hadamard bound).
- **Empty cases.** $\det$ and $\operatorname{tr}$ of the $0 \times 0$ matrix
  are $1$ and $0$; $A^0 = I$; a product with inner dimension $0$ is the zero
  matrix.
- **Complexity.** `set`: $O(\log_{32} N)$; `map`, `+`, `transpose`,
  `swap_*`: $O(N)$; `matmul`: $O(rcn)$; `determinant`: $O(n^3)$; `pow`:
  $O(n^3 \log k)$.

## Alternatives rejected

- **Floating-point LU for `immut` determinants.** It would need a field and a
  tolerance and would lose exactness for integer matrices, the main reason to
  use this package.
- **A runtime backend selector inside `Matrix`.** Backends are separate types
  ([`backends/default`](backends/default.md)); `Matrix` has one representation.
- **Caching in `MatrixFn`.** It would make a pure value hold mutable state and
  change the cost model silently. Materialize with `Matrix::make` instead.

## Boundaries

`immut` does not provide in-place updates, views, inverses, decompositions,
eigenvalues, statistics or tolerance-based predicates; those belong to
[`mutable`](mutable.md). It does not detect integer overflow, does not offer a
checked `MatrixFn` API, and does not implement the [`algebra`](algebra.md)
traits itself (the wrappers in `backends/default` do).
