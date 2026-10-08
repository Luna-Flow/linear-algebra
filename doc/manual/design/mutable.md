# mutable design

## Design goal

`mutable` is the execution-oriented half of the repository. It stores a
matrix in one flat row-major array, lets callers update it in place and work
through live views, and implements the floating-point numerical routines:
determinant, inverse, rank, row reduction, Cholesky factorization, symmetric
eigenvalues and the power method. The public API still reads like value
operations wherever possible; mutation is confined to methods that return
`Unit` and to the views, so callers can tell from a signature whether a call
changes its receiver.

## Constraints

- The package must run on all four MoonBit targets (`native`, `js`, `wasm`,
  `wasm-gc`) with one public specification.
- It may depend only on `error`, `internal` and the upstream scalar packages,
  not on the experimental `algebra` and `container` layers.
- Element types are generic. The numerical routines can only assume the
  `luna-generic` structure traits (`Field`, `Num`) plus `Compare`, `Sqrt` and
  this package's `Tolerance`; they cannot inspect the floating-point format.
- Its names, argument order and checked/unchecked conventions follow
  [`immut`](immut.md) wherever both packages offer an operation.

## Design decisions

### Flat row-major storage

**Options.** An array of row arrays, a persistent structure, or one flat
array. **Decision.** One `Array[T]` with entry $(i, j)$ at $i c + j$, shared by
all four targets. **Why.** It gives $O(1)$ access with one bounds check per
coordinate, contiguous rows for the inner loops of elimination and products,
and zero-cost row and column views. `from_array` adopts the caller's array so
that large inputs need not be copied; the price is aliasing, which the API
documents.

### Views instead of copies

`row_view`, `col_view` and `to_transpose` return live views in $O(1)$. A
view is a pair (matrix, index) or a wrapper, so writes go to the shared storage
and no synchronization is needed. Materializing is always explicit
(`to_vector`, `materialize`, `transpose`).

### Target-specific kernels with shared semantics

The package has one source file per target for the matrix, LU, view and
transpose code. They differ only in loop structure (unrolling, packing,
avoidance of division in index computations) chosen for each backend; the
public semantics, including bounds and error behaviour, are identical, and the
tests run on all four targets. Floating-point results may differ in the last
bits because summation orders differ.

### Tolerance-based decisions

Elimination must decide when a computed quantity "is zero". The package uses
one absolute threshold $\tau$ = `Tolerance::tolerance()` = $10^{-11}$ for
`Double` and `Float`, applied as follows:

| Routine | Test |
| --- | --- |
| LU (`determinant` for $n \ge 5$, `inverse`, `is_invertible`) | pivot $\lvert u_{kk}\rvert < \tau$ means singular |
| `inverse` of a diagonal matrix | $\lvert a_{ii}\rvert < \tau$ means singular |
| `rank` | largest remaining $\lvert a_{ik}\rvert < \tau$ means no pivot; a multiplier $< \tau$ is dropped |
| `reduce_row_elimination` | pivot candidate $\le \tau$ is set to zero and skipped; column entries $\le \tau$ are set to zero |
| `cholesky_decomposition` | radicand $\le \tau$ means not positive definite |
| `is_symmetric`, fast-path detection (identity, diagonal, permutation, triangular) | $\lvert a_{ij} - b_{ij}\rvert \le \tau$ counts as equal |
| `eigen`, $2 \times 2$ | discriminant $< -\tau$ aborts, $\lvert\text{discriminant}\rvert \le \tau$ counts as zero |
| `eigen`, Householder step | a row with $\sum_k \lvert a_{ik}\rvert \le \tau$ is not reflected |
| `eigen` deflation | $\lvert e_m\rvert \le \tau(\lvert d_m\rvert + \lvert d_{m+1}\rvert + 1)$ |
| `power_method` | residual $\lVert Ax - \lambda x\rVert_\infty \le \tau$ accepts; $\lVert Ax\rVert_\infty \le \tau$ or $x^{\mathsf T}x \le \tau$ gives `None` |

An absolute threshold is simple and predictable, but it is not scale
invariant. Scaling $A$ by $10^{-12}$ makes every pivot fall below $\tau$, so a
perfectly conditioned matrix is reported singular; scaling by $10^{12}$ lets a
numerically singular matrix pass. Scale data to order one before calling
these routines. For `Float`, $\tau = 10^{-11}$ is far below the unit roundoff
$\approx 6 \times 10^{-8}$, so for data of order one the tests effectively
check for exact zeros, and nearly singular `Float` matrices are not detected.
The trait is closed (`pub`, not `pub(open)`), so these two instances are the
only ones; a scale-aware tolerance policy is future work and would be a
breaking change.

### Fast paths

`inverse` recognizes the identity (returns a copy), diagonal matrices
(inverts the diagonal) and permutation matrices (returns the transpose, since
$P^{\mathsf T} P = I$ for a matrix whose columns are distinct coordinate
vectors). `cholesky_decomposition` recognizes the identity and diagonal
matrices, and `determinant` recognizes triangular matrices for $n \ge 5$ and
multiplies the diagonal. Each test costs $O(n^2)$ and saves an $O(n^3)$
factorization. The tests use the tolerance, so a matrix that is diagonal up to
$\tau$ is treated as exactly diagonal, and a matrix within $\tau$ of the
identity is returned as it is (by `inverse` and by `cholesky_decomposition`,
whose result is then not exactly lower triangular).

### Checked forms without changing the kernels

Every checked method validates (squareness, exponent sign, non-emptiness,
lengths) and then calls its unchecked partner, which keeps the original
aborting or `Option` behaviour. There is no checked matrix product here: `*`
validates and aborts, and `unchecked_matmul` does not validate at all. This
asymmetry with `@immut.Matrix::matmul` is known; a checked `matmul` would be
an addition, not a change.

### Symmetric eigenvalues only

General real matrices can have complex eigenvalues, which a function
returning `Vector[T]` cannot represent for real `T`. `eigen` therefore accepts
only symmetric matrices, for which all eigenvalues are real and an orthonormal
eigenbasis exists, and aborts otherwise.

### Which traits the routines require, and why

| Bound | Needed for |
| --- | --- |
| `AddMonoid + Mul` | products, `mul_vec`, `dot`, `trace`: sums of products starting from `0` |
| `Semiring` | `pow`: needs `1` for $A^0 = I$ and distributivity for associativity of the product |
| `Field` | elimination divides by pivots; `mean` divides by $N$ |
| `Num` | `abs` for pivot selection and every tolerance test |
| `Compare` | comparing magnitudes |
| `Sqrt` | Cholesky diagonal, Householder norms, Givens rotations, $\lVert\cdot\rVert_F$, `std_dev` |
| `Tolerance` | the zero decisions above |

`Field` is commutative in `luna-generic`, which the derivations below use (for
example $\det(LU) = \det L \det U$ and $(AB)^{\mathsf T} = B^{\mathsf T} A^{\mathsf T}$).

## Mathematical background

Throughout, $u$ is the unit roundoff ($2^{-53}$ for `Double`, $2^{-24}$ for
`Float`), $\mathrm{fl}(x \circ y) = (x \circ y)(1 + \delta)$ with
$|\delta| \le u$, and

$$
\gamma_n = \frac{n u}{1 - n u}, \qquad
\prod_{k=1}^{n} (1 + \delta_k)^{\pm 1} = 1 + \theta_n,\quad |\theta_n| \le \gamma_n
\quad (n u < 1) .
$$

The second fact[^gamma] is what turns "each operation is rounded" into bounds
for whole algorithms. Inequalities between matrices hold entry-wise, and $|A|$
is the matrix of absolute values. A flop is one floating-point addition,
subtraction, multiplication or division.

[^gamma]: Higham, Lemma 3.1. The proof is an induction on $n$ using
$|\theta_{n+1}| \le |\theta_n| + u + u|\theta_n|$.

### Matrix product

$(AB)_{ik} = \sum_j a_{ij} b_{jk}$ costs $rcn$ multiply-adds, $2rcn$ flops. The
kernels sum in different orders (four partial products per step in the
unrolled kernels; a packed copy of the columns of $B$ for products of at least
$4 \times 16 \times 16$), but in any order each product $a_{ij} b_{jk}$ passes
through one multiplication and at most $n - 1$ additions, so it carries a
factor $1 + \theta_n$ and

$$
\big|\mathrm{fl}(AB) - AB\big| \le \gamma_n |A|\,|B| .
$$

Results on different targets therefore agree to that accuracy, not bit for
bit.

### LU factorization with partial pivoting

For square $A$, Gaussian elimination with partial pivoting computes a
permutation $P$, a unit lower triangular $L$ and an upper triangular $U$ with

$$
PA = LU .
$$

**Derivation.** Write $A^{(0)} = A$. At step $k$ the algorithm chooses the row
$p \ge k$ with the largest $|a^{(k)}_{pk}|$ and swaps it into position $k$
(a transposition $P_k$). It then subtracts multiples of row $k$ from the rows
below, which is multiplication by the Gauss transform

$$
M_k = I - \ell_k e_k^{\mathsf T}, \qquad
\ell_k = (0, \dots, 0, l_{k+1,k}, \dots, l_{n-1,k})^{\mathsf T}, \qquad
l_{ik} = a^{(k)}_{ik} / a^{(k)}_{kk},
$$

so that $a^{(k+1)}_{ij} = a^{(k)}_{ij} - l_{ik} a^{(k)}_{kj}$ and column $k$
below the diagonal becomes zero. After $n - 1$ steps

$$
U = M_{n-2} P_{n-2} \cdots M_0 P_0 \, A .
$$

Since $e_k^{\mathsf T} \ell_k = 0$, $M_k^{-1} = I + \ell_k e_k^{\mathsf T}$, and a
later transposition $P_j$ ($j > k$) only exchanges entries of $\ell_k$:
$P_j M_k = \tilde M_k P_j$ with $\tilde M_k = I - (P_j \ell_k) e_k^{\mathsf T}$.
Moving all permutations to the right gives $U = \tilde M_{n-2} \cdots \tilde M_0 P A$
with $P = P_{n-2} \cdots P_0$, hence $PA = LU$ with

$$
L = \tilde M_0^{-1} \cdots \tilde M_{n-2}^{-1}
  = I + \sum_k \tilde\ell_k e_k^{\mathsf T} .
$$

This is why the code can store the multipliers in place of the eliminated
entries and swap whole rows, multipliers included: the stored lower triangle
is exactly $L$. The pivot choice gives $|l_{ik}| \le 1$.

**Cost.** Step $k$ updates an $(n-k-1) \times (n-k-1)$ block with one
multiply and one subtract per entry, so

$$
\sum_{k=0}^{n-1} 2 (n - k - 1)^2 = \frac{(n-1) n (2n-1)}{3} \approx \tfrac23 n^3
$$

flops.

**Determinant.** Taking determinants of $PA = LU$ with $\det L = 1$ and
$\det P = (-1)^{s}$ for $s$ exchanges,

$$
\det A = (-1)^{s} \prod_{k} u_{kk} .
$$

**Solving and the inverse.** $Ax = b$ becomes $L y = P b$ (forward
substitution, $y_i = (Pb)_i - \sum_{k<i} l_{ik} y_k$) and $U x = y$ (back
substitution, $x_i = (y_i - \sum_{k>i} u_{ik} x_k) / u_{ii}$). Each costs
$\sum_i 2i \approx n^2$ flops per right-hand side. The inverse is the solution
for the $n$ columns of $I$; the code does not exploit the zeros of $e_j$, so
the total is $\tfrac23 n^3 + n \cdot 2n^2 = \tfrac83 n^3$ flops.

**Stability.** The computed factors satisfy the backward error bound
(Wilkinson; Higham, Theorem 9.3)[^higham]

$$
\hat L \hat U = P(A + \Delta A), \qquad |\Delta A| \le \gamma_n |\hat L|\,|\hat U| .
$$

To turn this into a norm bound, let
$\rho_n = \max_{i,j,k} |a^{(k)}_{ij}| / \max_{i,j} |a_{ij}|$ be the growth
factor. Every row of $\hat L$ has at most $n$ entries of magnitude at most $1$,
so $\lVert \hat L \rVert_\infty \le n$, and every row of $\hat U$ has at most
$n$ entries bounded by $\rho_n \max |a_{ij}| \le \rho_n \lVert A \rVert_\infty$,
so

$$
\lVert \Delta A \rVert_\infty
\le \gamma_n \lVert \hat L \rVert_\infty \lVert \hat U \rVert_\infty
\le n^2 \gamma_n \rho_n \lVert A \rVert_\infty .
$$

Partial pivoting bounds the growth: since $|l_{ik}| \le 1$,
$|a^{(k+1)}_{ij}| \le |a^{(k)}_{ij}| + |a^{(k)}_{kj}| \le 2 \max |a^{(k)}|$, so
$\rho_n \le 2^{n-1}$. The bound is attained only by contrived matrices; in
practice $\rho_n$ is small and the method is backward stable. Including the
two triangular solves, each computed solution satisfies
$(A + \Delta A)\hat x = b$ with $\lVert \Delta A \rVert_\infty \le 2 n^2 \gamma_n \rho_n \lVert A \rVert_\infty$
(Higham, Theorem 9.5), and the *forward* error is governed by the condition
number $\kappa_\infty(A) = \lVert A \rVert_\infty \lVert A^{-1} \rVert_\infty$:

$$
\frac{\lVert \hat x - x \rVert_\infty}{\lVert x \rVert_\infty}
\le \frac{\kappa_\infty(A)\, \epsilon}{1 - \kappa_\infty(A)\, \epsilon},
\qquad \epsilon = 2 n^2 \gamma_n \rho_n .
$$

Each column of the computed inverse obeys this bound.

[^higham]: N. J. Higham, *Accuracy and Stability of Numerical Algorithms*,
2nd ed., SIAM, 2002, chapters 3 (basics), 8 (triangular systems), 9 (LU) and
10 (Cholesky).

### Closed forms for small determinants

For $n \le 4$ the determinant is evaluated by formulas instead of LU: the rule
$ad - bc$, cofactor expansion along the first row for $n = 3$, and for $n = 4$
Laplace's expansion along the first two rows into six products of
complementary $2 \times 2$ minors,

$$
\det A = \sum_{p<q} (-1)^{(0 + 1) + (p + q)} \det A_{\{0,1\},\{p,q\}} \det A_{\{2,3\},\overline{\{p,q\}}} ,
$$

where $\overline{\{p,q\}}$ is the complementary pair of columns. The sign is
$(-1)^{1+p+q}$: $+$ for $\{0,1\}, \{0,3\}, \{1,2\}, \{2,3\}$ and $-$ for
$\{0,2\}, \{1,3\}$, which is the pattern
$s_{01} c_{23} - s_{02} c_{13} + s_{03} c_{12} + s_{12} c_{03} - s_{13} c_{02} + s_{23} c_{01}$
in the code.

They use no division and no pivoting decision, which avoids the tolerance test
for tiny matrices. Their rounding error is easy to bound: every one of the $n!$
monomials $\pm a_{0\sigma(0)} \cdots a_{n-1,\sigma(n-1)}$ passes through at most
$m$ roundings, with $m = 2, 5, 10$ for $n = 2, 3, 4$ (for $n = 4$: two in each
$2 \times 2$ minor, one for their product, five for the sum of six terms), so

$$
\big|\mathrm{fl}(\det A) - \det A\big| \le \gamma_m \operatorname{per}(|A|),
\qquad \operatorname{per}(|A|) = \sum_{\sigma} \prod_i |a_{i\sigma(i)}| .
$$

The permanent is at least $|\det A|$, and much larger when the monomials
cancel; then the relative accuracy is lost, exactly as the determinant itself
is ill-conditioned there. These formulas are not backward stable in the LU
sense.

### Rank and reduced row echelon form

`rank` runs elimination with partial pivoting on a copy and counts pivots
whose magnitude is at least the tolerance, moving to the next column when the
largest remaining entry is below it. This is the *numerical rank* with an
absolute threshold $\tau$. It is exact for matrices whose pivots are well
separated from $\tau$ and otherwise depends on scaling. The singular value
decomposition gives the reliable numerical rank, $\#\{\sigma_i > \tau\}$, because
by the Eckart–Young theorem $\sigma_{k+1}$ is the 2-norm distance to the nearest
matrix of rank $k$; elimination pivots have no such meaning, and a matrix with
all pivots of order one can be within $2^{-n}$ of a singular one.[^kahan] The
SVD is not implemented.

[^kahan]: Kahan's example: the upper triangular matrix with $1$ on the
diagonal and $-1$ above it has all pivots equal to $1$, while its smallest
singular value decreases like $2^{-n}$.

`reduce_row_elimination` is Gauss–Jordan elimination: each pivot row is scaled
to make the pivot one, and the pivot column is cleared in every other row. For
each of at most $\min(r, c)$ pivots it updates all $r$ rows over all $c$
columns, about $2 r c \min(r, c)$ flops, and works in place. Unlike LU it
produces the reduced form, in which every pivot column is a coordinate vector,
so the non-pivot columns of the result express the dependent columns of $A$ in
terms of the pivot columns.

### Cholesky factorization

A symmetric positive definite (SPD) matrix has a unique factorization
$A = L L^{\mathsf T}$ with $L$ lower triangular and $l_{jj} > 0$. Comparing
entries of $A = L L^{\mathsf T}$ for $i \ge j$,

$$
a_{ij} = \sum_{k=0}^{j} l_{ik} l_{jk}
\quad\Longrightarrow\quad
l_{jj} = \sqrt{a_{jj} - \sum_{k<j} l_{jk}^2}, \qquad
l_{ij} = \frac{1}{l_{jj}} \Big(a_{ij} - \sum_{k<j} l_{ik} l_{jk}\Big) .
$$

Each equation determines one new entry from earlier ones, which proves
uniqueness once the radicands are positive. The code evaluates them row by row
(the Cholesky–Banachiewicz order) and reads only the lower triangle of $A$; the
cost is $\sum_j 2 j (n - j) \approx \tfrac13 n^3$ flops, half of LU, because
symmetry halves the work.

**Why success characterizes SPD.** Write $D = \operatorname{diag}(l_{jj})$.
Then $A = (L D^{-1})(D L^{\mathsf T})$ is an LU factorization without pivoting,
whose pivots are $u_{jj} = l_{jj}^2$, the radicands. The product of the first
$j + 1$ pivots is the leading principal minor $\det M_{j+1}$, so the radicand at
step $j$ equals $\det M_{j+1} / \det M_j$. By Sylvester's criterion $A$ is SPD
exactly when all leading principal minors are positive, so in exact arithmetic
the factorization succeeds exactly for SPD matrices. With the tolerance,
`cholesky_decomposition` succeeds exactly when every ratio
$\det M_{j+1} / \det M_j$ exceeds $\tau$ (up to rounding), and
`is_positive_definite` is implemented by attempting it.

**Stability.** Cholesky needs no pivoting: from
$a_{jj} = \sum_k l_{jk}^2$ every $|l_{jk}| \le \sqrt{a_{jj}}$, so entries cannot
grow, and the computed factor satisfies
$\hat L \hat L^{\mathsf T} = A + \Delta A$ with
$|\Delta A| \le \gamma_{n+1} |\hat L|\,|\hat L^{\mathsf T}|$ (Higham,
Theorem 10.3). Since $(|\hat L|\,|\hat L^{\mathsf T}|)_{ij} \le \sqrt{a_{ii} a_{jj}}$
up to $O(u)$ by the Cauchy–Schwarz inequality, the backward error is small
relative to the diagonal of $A$.

### Symmetric eigenvalue problem

For real symmetric $A$ the spectral theorem gives $A = Q \Lambda Q^{\mathsf T}$
with $Q$ orthogonal and $\Lambda$ real diagonal. `eigen` computes it in two
phases for $n \ne 2$, and by a closed formula for $n = 2$.

**Householder tridiagonalization.** For $x \in \mathbb{R}^m$, $x \ne 0$, let
$\alpha = -\operatorname{sgn}(x_{m-1}) \lVert x \rVert_2$ and
$v = x - \alpha e_{m-1}$. The reflector $H = I - 2 v v^{\mathsf T} / v^{\mathsf T} v$
is symmetric and orthogonal, and it maps $x$ to $\alpha e_{m-1}$:

$$
\begin{aligned}
v^{\mathsf T} v &= \lVert x \rVert^2 - 2 \alpha x_{m-1} + \alpha^2
  = 2\big(\lVert x \rVert^2 - \alpha x_{m-1}\big) = 2\, v^{\mathsf T} x, \\
H x &= x - \frac{2\, v^{\mathsf T} x}{v^{\mathsf T} v}\, v = x - v = \alpha e_{m-1} .
\end{aligned}
$$

The sign of $\alpha$ is opposite to $x_{m-1}$, so $x_{m-1} - \alpha$ adds two
numbers of the same sign and cannot cancel. The code (the `tred2` scheme)
works from the last row upwards: for row $i$ it reflects
$x = (a_{i0}, \dots, a_{i,i-1})$ onto its last coordinate, applies $H$ from
both sides, and so zeroes row and column $i$ outside the tridiagonal band.
After $n - 2$ such steps

$$
Q_1^{\mathsf T} A Q_1 = T, \qquad Q_1 = H_{n-1} H_{n-2} \cdots H_2 ,
$$

where $T$ is symmetric tridiagonal with diagonal $d$ and off-diagonal $e$. The
two-sided update costs $\tfrac43 n^3$ flops and accumulating $Q_1$ explicitly
another $\tfrac43 n^3$. Before forming each reflector the row is divided by
$\sum_k |x_k|$, which avoids overflow and underflow in $\lVert x \rVert_2$; a
row whose sum is at most $\tau$ is left unreflected.

**Implicit QL with Wilkinson shifts.** The tridiagonal $T$ is diagonalized by
plane rotations. Before each sweep on the unreduced block starting at $l$, the
shift $\sigma$ is the eigenvalue of the leading $2 \times 2$ block
$\begin{pmatrix} d_l & e_l \\ e_l & d_{l+1} \end{pmatrix}$ closer to $d_l$.
With $g = (d_{l+1} - d_l)/(2 e_l)$, its eigenvalues are

$$
\lambda_\pm = \frac{d_l + d_{l+1}}{2} \pm \sqrt{\Big(\frac{d_{l+1} - d_l}{2}\Big)^2 + e_l^2}
= d_l + e_l \big(g \pm \sqrt{g^2 + 1}\big),
$$

because $\tfrac12(d_l + d_{l+1}) = d_l + e_l g$ and the square root equals
$|e_l| \sqrt{g^2 + 1}$ (the sign of $e_l$ is absorbed by $\pm$). The one closer
to $d_l$ makes $|g \pm \sqrt{g^2+1}|$ small, that is, takes the sign opposite
to $g$:

$$
\sigma = d_l + e_l\big(g - \operatorname{sgn}(g)\sqrt{g^2+1}\big)
       = d_l - \frac{e_l}{g + \operatorname{sgn}(g)\sqrt{g^2 + 1}} ,
$$

where the second form follows from
$(g - s\sqrt{g^2+1})(g + s\sqrt{g^2+1}) = g^2 - (g^2 + 1) = -1$ for
$s = \operatorname{sgn}(g)$, and avoids the cancellation of the first. The code
uses it with $\operatorname{sgn}(0) = 1$. A sweep starts from $d_m - \sigma$ and
applies Givens rotations
$\begin{pmatrix} c & s \\ -s & c \end{pmatrix}$, $c^2 + s^2 = 1$, from the
bottom of the block upwards, each one chasing the bulge created by the
previous; $Q$ is updated with the same rotations, $6n$ flops each. The
rotation parameters are computed as $c = g/f$, $r = \sqrt{c^2 + 1}$,
$s = 1/r$, $c = c s$ (or the symmetric form), dividing by the larger of
$|f|, |g|$ so that no square of a large number is formed.

An off-diagonal entry is treated as zero when

$$
|e_m| \le \tau\,\big(|d_m| + |d_{m+1}| + 1\big),
$$

and the block then splits. For symmetric tridiagonal matrices the Wilkinson
shift converges for every input in exact arithmetic (Wilkinson, 1968), and
typically cubically; about two sweeps per eigenvalue is usual. The code
nevertheless aborts after 60 sweeps for one starting index $l$. With
accumulation of $Q$ the whole computation takes about $9 n^3$ flops (Golub and
Van Loan's estimate for the symmetric QR algorithm), $\tfrac83 n^3$ of them in
the reduction.

**Accuracy.** Every transformation is orthogonal, so in exact arithmetic the
spectrum never changes, and rounding contributes a backward error of
$O(n u) \lVert A \rVert_2$. The thresholds contribute more. Setting $e_m$ to
zero perturbs $T$ by a symmetric matrix of 2-norm at most
$\tau(|d_m| + |d_{m+1}| + 1) \le \tau(2 \lVert A \rVert_2 + 1)$, and skipping a
reflection perturbs $A$ by entries whose absolute values sum to at most $\tau$
per row. Weyl's inequality, $|\lambda_i(A + E) - \lambda_i(A)| \le \lVert E \rVert_2$
for symmetric $A$ and $E$, then gives for the computed eigenvalues

$$
|\hat\lambda_i - \lambda_i| \lesssim O(n u)\,\lVert A \rVert_2 + c_n\, \tau\,\big(\lVert A \rVert_2 + 1\big)
$$

with a small $c_n$. With $\tau = 10^{-11}$ the second term dominates: absolute
accuracy is about $10^{-11}$ for $\lVert A \rVert$ of order one, and for a matrix
whose entries are all below $\tau$ the result is meaningless. Eigenvectors are
accurate in proportion to (backward error)$/\text{gap}$, where the gap is the
distance to the nearest other eigenvalue (the Davis–Kahan theorem).

**The $2 \times 2$ case.** For $A = \begin{pmatrix} a & b \\ c & d \end{pmatrix}$
the characteristic polynomial $\lambda^2 - (a + d)\lambda + (ad - bc)$ gives,
with $m = (a + d)/2$,

$$
\lambda_{1,2} = m \pm \sqrt{m^2 - (ad - bc)} .
$$

For $b \ne 0$ the vector $(b, \lambda - a)^{\mathsf T}$ is an eigenvector:

$$
\begin{pmatrix} a - \lambda & b \\ c & d - \lambda \end{pmatrix}
\begin{pmatrix} b \\ \lambda - a \end{pmatrix}
= \begin{pmatrix} 0 \\ bc - (\lambda - a)(\lambda - d) \end{pmatrix}
= 0 ,
$$

since $(\lambda - a)(\lambda - d) = \lambda^2 - (a + d)\lambda + ad = bc$ by the
characteristic equation. The code returns these vectors without normalizing
them, and $e_1, e_2$ when $b = c = 0$.

> [!WARNING]
> This closed form is less accurate than the general path, for three reasons
> that the code does not guard against. (1) For symmetric input the
> discriminant is $m^2 - (ad - b^2) = \big(\tfrac{a-d}{2}\big)^2 + b^2 \ge 0$,
> but it is computed as a difference of two numbers of size $m^2$, with an
> absolute error of about $u\, m^2$. For $m \approx 10^8$ that is about $1$,
> far above $\tau$, so the computed discriminant can be negative enough to
> trigger the "complex eigenvalues" abort on a symmetric, even diagonal,
> matrix. (2) A discriminant with $|\cdot| \le \tau$ is replaced by zero. Since
> $\lambda_1 - \lambda_2 = 2\sqrt{\text{discriminant}}$, every pair of
> eigenvalues closer than $2\sqrt{\tau} \approx 6.3 \times 10^{-6}$ is returned
> as a double eigenvalue $m$, an error up to $3 \times 10^{-6}$. (3) When the
> two eigenvalues are then equal and $b \ne 0$, both columns are
> $(b, m - a)^{\mathsf T}$, so the eigenvector matrix is singular. In addition,
> when $|\lambda_2| \ll |\lambda_1|$ the subtraction $m - \sqrt{\cdot}$ cancels
> and $\lambda_2$ loses relative accuracy. The stable formulation computes the
> discriminant as $\big(\tfrac{a-d}{2}\big)^2 + bc$, never thresholds it, takes
> $\lambda_2 = \det A / \lambda_1$, and chooses between the eigenvector forms
> $(b, \lambda - a)$ and $(\lambda - d, c)$ by size.

### Power method

The code starts from $x_0 = (1, \dots, 1)$, or, if
$\lVert A x_0 \rVert_\infty \le \tau$, from the first coordinate vector $e_k$
with $\lVert A e_k \rVert_\infty > \tau$; if there is none it returns `None`.
It then iterates

$$
y = A x_k, \qquad x_{k+1} = y / \lVert y \rVert_\infty, \qquad
\lambda_{k+1} = \frac{x_{k+1}^{\mathsf T} A x_{k+1}}{x_{k+1}^{\mathsf T} x_{k+1}} ,
$$

and stops when $\lVert A x_k - \lambda_k x_k \rVert_\infty \le \tau$; the
normalization makes $\lVert x_k \rVert_\infty = 1$.

**Convergence.** If $A$ is diagonalizable with eigenvalues
$|\lambda_1| > |\lambda_2| \ge \dots$ and eigenvectors $v_i$, and $x_0$ has a
component $c_1 \ne 0$ along $v_1$, then

$$
A^{k} x_0 = \lambda_1^{k}\Big(c_1 v_1 + \sum_{i \ge 2} c_i \big(\tfrac{\lambda_i}{\lambda_1}\big)^{k} v_i\Big),
$$

so the direction of $x_k$ converges to $v_1$ linearly with ratio
$r = |\lambda_2 / \lambda_1|$. For negative $\lambda_1$ the sign of $x_k$
alternates, which the Rayleigh quotient does not notice. For symmetric $A$
with orthonormal $v_i$, $x_k \propto \sum_i c_i (\lambda_i/\lambda_1)^k v_i$
gives

$$
\lambda_k = \frac{\sum_i c_i^2 \lambda_i (\lambda_i/\lambda_1)^{2k}}{\sum_i c_i^2 (\lambda_i/\lambda_1)^{2k}}
= \lambda_1 + O(r^{2k}),
$$

so the eigenvalue converges twice as fast as the vector. When
$|\lambda_1| = |\lambda_2|$ with $\lambda_1 \ne \lambda_2$ (for example
$\pm 1$) the direction oscillates and the residual test never passes, and when
$A$ is nilpotent the iterate reaches zero; both cases return `None`.

**What the stopping test guarantees.** For symmetric $A$, a residual
$r = Ax - \lambda x$ bounds the distance to the spectrum: expanding $x$ in the
orthonormal eigenbasis,
$\lVert r \rVert_2^2 = \sum_i c_i^2 (\lambda_i - \lambda)^2 \ge \min_i (\lambda_i - \lambda)^2 \lVert x \rVert_2^2$.
With $\lVert r \rVert_\infty \le \tau$ and $\lVert x \rVert_\infty = 1$ we have
$\lVert r \rVert_2 \le \sqrt n\, \tau$ and $\lVert x \rVert_2 \ge 1$, so some
eigenvalue lies within $\sqrt n\, \tau$ of the returned $\lambda$. The test is
absolute, so for $\lVert A \rVert \gg 1$ it may be unreachable in floating point
(the residual cannot drop below about $u \lVert A \rVert$), and for
$\lVert A \rVert \ll 1$ it passes before $x$ is accurate.

### Statistics

`variance` is the population variance computed in two passes: first the mean
$\bar a$, then $\tfrac1N \sum (a_i - \bar a)^2$. The one-pass formula
$\tfrac1N \sum a_i^2 - \bar a^2$ subtracts two nearly equal numbers when the
data have a large mean and a small spread, and can even return a negative
value. With $S = \sum (a_i - \bar a)^2$ and the condition number
$\kappa = \lVert a \rVert_2 / \sqrt S$ of the data, Chan, Golub and LeVeque
(1983) show that the relative error of $S$ is bounded by about $N \kappa^2 u$
for the one-pass formula and by about $N u + N^2 \kappa^2 u^2$ for the two-pass
one, which is $O(Nu)$ unless $\kappa$ is near $u^{-1/2}$. The count $N$ is
accumulated as a sum of ones in `T`, exact up to $2^{53}$ entries for `Double`
and $2^{24}$ for `Float`; beyond that the count stops growing and the mean is
wrong.

### Transpose views and products

`Transpose::mul` computes $A^{\mathsf T} B^{\mathsf T}$ as $(BA)^{\mathsf T}$ by
reusing the matrix kernel on the wrapped matrices. Entry by entry,

$$
\big(A^{\mathsf T} B^{\mathsf T}\big)_{ik} = \sum_j a_{ji} b_{kj}, \qquad
\big((BA)^{\mathsf T}\big)_{ik} = \sum_j b_{kj} a_{ji} ,
$$

which agree when the scalars commute. All scalar types with `Tolerance`
(`Float`, `Double`) commute, but `Transpose::mul` only requires
`AddMonoid + Mul`; for a non-commutative scalar type the result is the
product in the wrong order (see the [algebra design](algebra.md)).

## Correctness and invariants

- **Storage.** `data.length() == row * col` at all times; every public
  accessor checks the row and column separately.
- **Value-returning methods do not mutate.** Only `Unit`-returning methods,
  view writes and `reduce_row_elimination` change a matrix.
- **Checked/unchecked law.** `x.f() == Ok(x.unchecked_f())` whenever the
  precondition holds; `inverse` returns `Err(SingularMatrix)` exactly when
  `unchecked_inverse` returns `None`.
- **Determinant consistency.** For $n \ge 5$ and a matrix that is not
  triangular within $\tau$, `determinant` returns exactly `0` when the LU
  factorization reports a pivot below $\tau$, which is also when
  `is_invertible` returns `false` and `inverse` fails; otherwise it returns a
  product of pivots that are at least $\tau$ in magnitude, which can still
  underflow. For $n \le 4$ the closed formulas are used for `determinant`,
  while `is_invertible` still uses LU, so a matrix with a tiny non-zero
  determinant can be "not invertible" with a non-zero `determinant`.
- **Residual guarantees.** `cholesky_decomposition` returns a factor with
  backward error $O(nu)$ relative to $|\hat L|\,|\hat L^{\mathsf T}|$, except on
  the identity fast path; `eigen` for $n \ne 2$ returns eigenpairs with
  backward error $O(nu)\lVert A \rVert + O(\tau)(\lVert A \rVert + 1)$;
  `power_method` returns only pairs with residual at most $\tau$.
- **Complexity.** `*`: $2rcn$ flops; `determinant`: $\tfrac23 n^3$; `inverse`:
  $\tfrac83 n^3$; `rank`, `reduce_row_elimination`: $O(rc\min(r, c))$;
  `cholesky_decomposition`: $\tfrac13 n^3$; `eigen`: about $9n^3$;
  `power_method`: two matrix-vector products, $4n^2$ flops, per iteration;
  statistics: $O(rc)$.

## Alternatives rejected

- **A relative or norm-scaled tolerance.** More robust, but it would change the
  results of existing callers; deferred until a tolerance policy can be passed
  explicitly.
- **Returning complex eigenvalues.** Would make this package depend on a
  complex number type and change the signature for real symmetric input.
- **Copy-on-write views.** Would hide the cost of writes and break the
  in-place contract that views exist for.
- **A single portable kernel.** Measured to be slower on some targets; the
  per-target files trade code size for speed while sharing one specification.

## Boundaries

`mutable` does not provide linear solves for a right-hand side as a public
method (only the inverse), QR, SVD or least-squares solvers, eigenvalues of
non-symmetric matrices, sparse storage, condition number estimates, or
scale-aware tolerances. It does not implement the [`algebra`](algebra.md)
traits itself; [`backends/default`](backends/default.md) wraps it for that.
Domain workflows such as regression or optimization belong in downstream
packages.
