# immut design

## Design goal

`immut` gives linear algebra with value semantics: a matrix or vector, once
built, never changes, and every operation returns a new value. Programs can
then keep old versions, share values freely between components and reason
about code by substitution. The package also aims to compute *exactly* whenever
the scalar type allows it, so that integer and big-integer matrices get exact
determinants and powers rather than floating-point approximations.

## Constraints

- No public operation may modify an existing value, and no hidden mutable
  state may be observable (no caches inside values).
- Element types are generic, bounded by the `luna-generic` traits; exact
  algorithms may use only ring operations and exact division, never a
  tolerance.
- The package may depend only on `error`, `internal`, `luna-generic` and the
  core persistent vector, not on the experimental `algebra` and `container`
  layers.
- Names, argument order and checked/unchecked conventions follow
  [`mutable`](mutable.md) wherever both packages offer an operation.

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

`determinant` requires the open `DeterminantScalar` strategy trait, which
extends `Compare + Num + Div`. `Int`, `Int16`, `Int64` and `BigInt` select
`Bareiss`; `Float` and `Double` select `PivotedLU`. The operation bounds alone
cannot distinguish exact integer division from rounded floating-point
division, so callers must supply this strategy explicitly for custom types.
Bareiss preserves exact results over integral domains when division is exact
on divisible values and intermediate arithmetic does not overflow. LU uses
field-like division and is approximate on floating-point scalars. This local
algorithm choice does not change the upstream algebraic laws or bounds.

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
| determinant | scalar strategy: Bareiss for integers, LU for floats without tolerance | LU with tolerance, floating point |
| decompositions, inverse, statistics | not available | available |
| `dot` | not on `Vector` (see `ImmutableDenseVector::dot`) | `Vector::dot` |

### No subtraction on `Vector`

`Vector` implements `Add`, `Mul` and `Neg` but not `Sub`; `u - v` is written
`u + -v`. This is an asymmetry inherited from earlier releases, not a
mathematical statement. The `backends/default` wrappers provide `-`.

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
one element copies the path from the root to the leaf, one node of at most 32
slots per level, and shares every other node, so

$$
\text{cost}(\mathtt{set}) = O(\log_{32} N), \qquad
\text{extra memory} = O(32 \log_{32} N), \qquad N = rc ,
$$

and the old matrix stays valid. Reads also cost $O(\log_{32} N)$; since
$32^6 = 2^{30}$ and $32^7 = 2^{35}$, at most seven levels cover every size an
`Int` index can reach. Whole-matrix operations rebuild the trie in $O(N)$.

### Matrix powers by repeated squaring

For a square matrix over a semiring, write $k = \sum_t b_t 2^t$ in binary. Then

$$
A^{k} = \prod_{t : b_t = 1} A^{2^t}, \qquad A^{2^{t+1}} = \big(A^{2^t}\big)^2 .
$$

The rearrangement of the product is valid because matrix multiplication is
associative over any semiring (see the [algebra design](algebra.md));
commutativity of the scalars is not needed, since all factors are powers of
the same $A$ and powers of one element of an associative ring commute with
each other. `pow` keeps a state $S$, an exponent $e$ and a base $B$ with the
invariant

$$
S \cdot B^{e} = A^{k},
$$

initially $(I, k, A)$. If $e$ is odd, $S B^{e} = (S B) B^{e-1}$ and
$B^{e-1} = (B^2)^{\lfloor e/2 \rfloor}$; if $e$ is even,
$B^{e} = (B^2)^{e/2}$. So the step
$(S, e, B) \mapsto (S B^{e \bmod 2}, \lfloor e/2 \rfloor, B^2)$ preserves the
invariant, and $e$ strictly decreases. The loop stops at $e = 1$ with
$S \cdot B$, or at $e = 0$ (only for $k = 0$) with $S = I$. It squares
$\lfloor \log_2 k \rfloor$ times and multiplies into $S$ once per 1-bit of
$k$, so it performs

$$
\lfloor \log_2 k \rfloor + \operatorname{popcount}(k) \le 2 \lfloor \log_2 k \rfloor + 1
$$

matrix products instead of $k - 1$; the first product into $S$ is by $I$. Over
$n \times n$ matrices that is $O(n^3 \log k)$ scalar operations.

For fixed-width integers the result is exact in $\mathbb{Z}/2^{w}\mathbb{Z}$
($w = 32$ for `Int`, $64$ for `Int64`) even when it overflows, because
wrapping arithmetic *is* the ring arithmetic of that quotient, and the
argument above uses only the semiring laws.

### Fraction-free determinant

Gaussian elimination over a field computes $\det A$ as the product of pivots
but divides at every step, which leaves the integers. Bareiss' algorithm keeps
every intermediate value an integer.[^bareiss] Let $a^{(-1)}_{-1,-1} = 1$,
$a^{(0)}_{ij} = a_{ij}$, and for $k = 0, 1, \dots, n-2$ and $i, j > k$

$$
a^{(k+1)}_{ij} =
\frac{a^{(k)}_{kk}\, a^{(k)}_{ij} - a^{(k)}_{ik}\, a^{(k)}_{kj}}{a^{(k-1)}_{k-1,k-1}} .
$$

**Every value is a minor.** Let $M_k$ be the leading $k \times k$ block of $A$
($\det M_0 = 1$), and for $i, j \ge k$ let $d^{(k)}_{ij}$ be the *bordered
minor* formed by rows $0, \dots, k-1, i$ and columns $0, \dots, k-1, j$:

$$
d^{(k)}_{ij} = \det
\begin{pmatrix}
M_k & c_j \\
r_i & a_{ij}
\end{pmatrix},
\qquad
c_j = \begin{pmatrix} a_{0j} \\ \vdots \\ a_{k-1,j} \end{pmatrix},\quad
r_i = (a_{i0}, \dots, a_{i,k-1}) .
$$

We show $a^{(k)}_{ij} = d^{(k)}_{ij}$ (Sylvester's determinant identity). It
is enough to prove the identity for matrices whose entries are independent
indeterminates, over their field of fractions, where every $M_k$ is
invertible; both sides are polynomials with integer coefficients, so it then
holds in every commutative ring. Block elimination gives

$$
d^{(k)}_{ij} = \det M_k \cdot \big(a_{ij} - r_i M_k^{-1} c_j\big)
             = \det M_k \cdot s^{(k)}_{ij},
$$

where $S^{(k)} = (s^{(k)}_{ij})$ is the Schur complement of $M_k$ in $A$. The
quotient property of Schur complements says that one more step of block
elimination is one step of ordinary elimination on $S^{(k)}$:

$$
s^{(k+1)}_{ij} = s^{(k)}_{ij} - \frac{s^{(k)}_{ik}\, s^{(k)}_{kj}}{s^{(k)}_{kk}},
\qquad
\det M_{k+1} = \det M_k \cdot s^{(k)}_{kk} .
$$

Substituting,

$$
\begin{aligned}
d^{(k+1)}_{ij}
&= \det M_{k+1}\, s^{(k+1)}_{ij}
 = \det M_k \big(s^{(k)}_{kk} s^{(k)}_{ij} - s^{(k)}_{ik} s^{(k)}_{kj}\big) \\
&= \frac{\big(\det M_k\, s^{(k)}_{kk}\big)\big(\det M_k\, s^{(k)}_{ij}\big)
        - \big(\det M_k\, s^{(k)}_{ik}\big)\big(\det M_k\, s^{(k)}_{kj}\big)}{\det M_k} \\
&= \frac{d^{(k)}_{kk}\, d^{(k)}_{ij} - d^{(k)}_{ik}\, d^{(k)}_{kj}}{d^{(k-1)}_{k-1,k-1}} ,
\end{aligned}
$$

because $\det M_k = d^{(k-1)}_{k-1,k-1}$. This is the recurrence, so by
induction on $k$ the algorithm computes exactly the bordered minors. Two
consequences follow. First, the division in the recurrence is *exact*: the
quotient is a minor of $A$, so over an integral domain such as $\mathbb{Z}$ the
numerator is a multiple of the previous pivot and the quotient is unique.
Second, the last value is the full determinant,
$a^{(n-1)}_{n-1,n-1} = d^{(n-1)}_{n-1,n-1} = \det A$. The attachment below
gives the same proof in more detail.

[Bareiss elimination: exactness and correctness](../../attachments/design_immut_bareiss.typ)

**Pivoting.** The code chooses as pivot the candidate $a^{(k)}_{ik}$, $i \ge k$,
of largest `abs`. Row $i$ of $a^{(k)}$ depends only on row $i$ of $A$ and on
rows $0, \dots, k-1$, so exchanging two rows with indices $\ge k$ before step
$k$ is the same as running the algorithm on $A$ with those rows exchanged,
which multiplies the final result by $-1$; the code tracks the sign. The
previous pivot, the divisor, sits in row $k - 1$ and is not moved.

**A zero pivot column.** If every candidate $a^{(k)}_{ik}$, $i \ge k$, is zero,
the code returns $0$ at once. This is correct: the previous pivot
$\det M_k$ is non-zero (otherwise the code would have stopped earlier), so
$s^{(k)}_{ik} = d^{(k)}_{ik} / \det M_k = 0$ for all $i \ge k$. Column $k$ of
the Schur complement $S^{(k)}$ is zero, so $\det S^{(k)} = 0$ and

$$
\det A = \det M_k \cdot \det S^{(k)} = 0 .
$$

**Size of intermediate values.** Every intermediate value is a minor of $A$,
so Hadamard's inequality bounds them:

$$
\big|a^{(k)}_{ij}\big| \le \prod_{r} \lVert \text{row}_r \rVert_2
$$

over the $k + 1$ rows involved (restricted to the chosen columns, which only
decreases the norms). Let
$H = \prod_r \max(1, \lVert \text{row}_r \rVert_2)$ over all rows; every such
product is at most $H$. The numerator of the recurrence is a difference of two
products of two minors, so every product is at most $H^2$ and the numerator at
most $2H^2$. This gives an overflow criterion for `Int`: if $2H^2 < 2^{31}$, no
intermediate value overflows and the result is exact (for `Int64`,
$2H^2 < 2^{63}$). Once a numerator wraps, the exact division no longer holds,
so the result is wrong rather than correct modulo $2^{w}$. For `BigInt` the
algorithm is always exact; it uses $O(n^3)$ arithmetic operations on integers
of at most $\log_2(2H^2) + 1$ bits.

**Floating point.** Bareiss forms products of minors before dividing. For
$A = 1000 I_{60}$ plus a superdiagonal of ones, triangularity gives
$\det A = 1000^{60} = 10^{180}$. Bareiss intermediates are leading minors,
so the products grow like $1000^{2(k+1)}$ and overflow binary64 even though
the final determinant is representable. `Float` and `Double` now select LU
with partial pivoting for every size, avoiding this source of minor growth.

### Pivoted LU determinant

The kernel copies the matrix, chooses the largest absolute entry in the
remaining pivot column, exchanges rows, and subtracts
$a_{ik}/a_{kk}$ times the pivot row from each later row. Row addition preserves
the determinant over a commutative field; each row exchange changes its sign.
After elimination the matrix is upper triangular, so
$\det A = (-1)^s \prod_k u_{kk}$ in exact arithmetic, where $s$ counts swaps.
This argument requires field-like division and does not apply to truncating
integer division; those scalars retain Bareiss.

There is no absolute or relative zero threshold. An exactly zero selected
pivot returns zero; the method does not classify numerical rank. The empty
pivot product is one. Inputs are immutable because all elimination occurs on
a private array. Floating-point rounding and elimination growth remain, and
the sequential pivot product may overflow or underflow even when the final
mathematical determinant is representable. NaN and infinity follow scalar
arithmetic without a checked error. Tests of known triangular and dense
factorizations are finite evidence, not a universal accuracy proof.

[^bareiss]: E. H. Bareiss, "Sylvester's identity and multistep integer-preserving
Gaussian elimination", *Mathematics of Computation* 22 (1968), 565–578.

**Small sizes.** For $n \le 4$ the package uses closed formulas instead. For
$n = 3$ it is the cofactor expansion along the first row; for $n = 4$ it is
Laplace's expansion along the first two rows,

$$
\det A = \sum_{\{p<q\}} (-1)^{1+p+q}\,
\det A_{\{0,1\},\{p,q\}}\, \det A_{\{2,3\},\overline{\{p,q\}}} ,
$$

six products of complementary $2 \times 2$ minors. These formulas use only ring
operations, so they are exact over every commutative ring and need no division
at all. Over `Int` they are therefore exact modulo $2^{32}$ even when an
intermediate value wraps, and the result is the true determinant whenever
$|\det A| < 2^{31}$.

### Lazy matrices

A `MatrixFn` is a pair $(\text{shape}, f)$ with $f : [r] \times [c] \to T$.
Operations compose functions: $\mathtt{map}(g)$ is $g \circ f$, transpose is
$f \circ \mathrm{swap}$, and the product is

$$
(f \cdot g)(i, k) = \sum_{j} f(i, j)\, g(j, k) ,
$$

evaluated on demand. Nothing is cached, so reading one entry of a product
costs the inner dimension $n$ times the cost of an entry of each factor. For a
left-nested chain of $d$ products of $n \times n$ matrices the cost $C_d$ of
one entry satisfies $C_d = n(C_{d-1} + 1)$, so $C_d = \Theta(n^d)$. Repeated
squaring is worse, because both factors of $B \cdot B$ are the same
unevaluated $B$: $C_{t+1} = 2n\, C_t$, so one entry of $A^{2^t}$ costs
$(2n)^t$ reads of $A$, that is $k^{1 + \log_2 n}$ for $k = 2^t$. Lazy powers
are cheap to build and expensive to read.

## Correctness and invariants

- **Immutability.** No public operation modifies an existing `Matrix`,
  `Vector` or `MatrixFn`; `set` and `swap_*` return new values.
- **Shape invariants.** $r, c \ge 0$ and the backing vector has exactly $rc$
  elements; constructors reject anything else by aborting.
- **Bounds.** Every public read checks row and column separately, so a column
  index that would land inside the next row is rejected rather than read.
- **Exactness.** Over `BigInt`, `determinant` and `pow` are exact; over `Int`
  and `Int64`, `pow` is exact modulo $2^{w}$, and `determinant` is exact unless
  an intermediate product overflows ($n \ge 5$) or the determinant itself does
  not fit ($n \le 4$; see the Hadamard bound).
- **Empty cases.** $\det$ and $\operatorname{tr}$ of the $0 \times 0$ matrix
  are $1$ and $0$; $A^0 = I$; a product with inner dimension $0$ is the zero
  matrix.
- **Complexity.** `set`: $O(\log_{32} N)$; `map`, `+`, `transpose`,
  `swap_*`: $O(N)$; `matmul`: $rcn$ multiply-adds; `determinant`: $O(n^3)$;
  `pow`: at most $2\lfloor\log_2 k\rfloor + 1$ products, $O(n^3 \log k)$.

## Alternatives rejected

- **LU for every scalar.** Truncating integer division would invalidate
  elimination. Explicit scalar strategies preserve Bareiss for exact domains
  and use LU for floating point without introducing a tolerance policy.
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
