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

## Mathematical background

Throughout, $u$ is the unit roundoff ($2^{-53}$ for `Double`, $2^{-24}$ for
`Float`), $\mathrm{fl}(x \circ y) = (x \circ y)(1 + \delta)$ with
$|\delta| \le u$, and $\gamma_n = n u / (1 - n u)$. Inequalities between
matrices hold entry-wise, and $|A|$ is the matrix of absolute values.

### Matrix product

$(AB)_{ik} = \sum_j a_{ij} b_{jk}$ costs $rcn$ multiply-adds. The kernels sum
in different orders (four partial products per step in the unrolled kernels;
a packed copy of the columns of $B$ for products of at least
$4 \times 16 \times 16$), but every order satisfies

$$
\big|\mathrm{fl}(AB) - AB\big| \le \gamma_n |A|\,|B| ,
$$

so results on different targets agree to that accuracy, not bit for bit.

### LU factorization with partial pivoting

For square $A$, Gaussian elimination with partial pivoting computes a
permutation $P$, a unit lower triangular $L$ and an upper triangular $U$ with

$$
PA = LU .
$$

At step $k$ it chooses the row $p \ge k$ with the largest $|a^{(k)}_{pk}|$,
swaps it into position $k$, and for $i > k$ stores the multiplier
$l_{ik} = a^{(k)}_{ik} / a^{(k)}_{kk}$ and updates
$a^{(k+1)}_{ij} = a^{(k)}_{ij} - l_{ik} a^{(k)}_{kj}$. Pivoting guarantees
$|l_{ik}| \le 1$. The cost is $\tfrac23 n^3$ flops.

**Determinant.** Taking determinants of $PA = LU$ with $\det L = 1$ and
$\det P = (-1)^{s}$ for $s$ exchanges,

$$
\det A = (-1)^{s} \prod_{k} u_{kk} .
$$

**Solving.** $Ax = b$ becomes $L y = P b$ (forward substitution) and
$U x = y$ (back substitution), each $n^2$ flops per right-hand side. The
inverse is the solution for the $n$ columns of $I$:
$\tfrac23 n^3 + n \cdot 2n^2 = \tfrac83 n^3$ flops.

**Stability.** The computed factors satisfy the backward error bound
(Wilkinson; Higham, Theorem 9.3)[^higham]

$$
\hat L \hat U = P(A + \Delta A), \qquad |\Delta A| \le \gamma_n |\hat L|\,|\hat U| .
$$

With $|l_{ik}| \le 1$ this gives
$\lVert \Delta A \rVert_\infty \le n \gamma_n \rho_n \lVert A \rVert_\infty$,
where $\rho_n = \max_{i,j,k} |a^{(k)}_{ij}| / \max_{i,j} |a_{ij}|$ is the growth
factor. Partial pivoting bounds $\rho_n \le 2^{n-1}$; the bound is attained only
by contrived matrices, and in practice $\rho_n$ is small, so the method is
backward stable in practice. The *forward* error of a solve is then governed
by the condition number:
$\lVert \hat x - x \rVert / \lVert x \rVert \lesssim \kappa(A)\, n \gamma_n \rho_n$.

[^higham]: N. J. Higham, *Accuracy and Stability of Numerical Algorithms*,
2nd ed., SIAM, 2002, chapters 9 (LU), 10 (Cholesky) and 8 (triangular
systems).

### Closed forms for small determinants

For $n \le 4$ the determinant is evaluated by formulas instead of LU: the rule
$ad - bc$, cofactor expansion along the first row for $n = 3$, and for $n = 4$
Laplace's expansion along the first two rows into six products of
complementary $2 \times 2$ minors,

$$
\det A = \sum_{p<q} (-1)^{p+q+1} \det A_{\{0,1\},\{p,q\}} \det A_{\{2,3\},\overline{\{p,q\}}} .
$$

They use no division and no pivoting decision, which avoids the tolerance test
for tiny matrices. They are not backward stable in the LU sense: for
ill-conditioned input the cancellation in $ad - bc$ can lose all relative
accuracy, exactly as the determinant itself is ill-conditioned there.

### Rank and reduced row echelon form

`rank` runs elimination with partial pivoting on a copy and counts pivots
whose magnitude is at least the tolerance. This is the *numerical rank* with
an absolute threshold $\tau$: the number of pivots $\ge \tau$. It is exact for
matrices whose pivots are well separated from $\tau$ and otherwise depends on
scaling. (The singular value decomposition gives the reliable numerical rank,
$\#\{\sigma_i > \tau\}$; it is not implemented.)

`reduce_row_elimination` is Gauss–Jordan elimination: each pivot row is scaled
to make the pivot one, and the pivot column is cleared above and below. It
costs about $r c \min(r, c)$ flops and works in place.

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

The code evaluates these row by row (the Cholesky–Banachiewicz order), $\tfrac13 n^3$
flops. The radicand at step $j$ equals the pivot of Gaussian elimination
without pivoting, which is the ratio of leading principal minors
$\det M_{j+1} / \det M_j$. By Sylvester's criterion, $A$ is SPD exactly when
all leading principal minors are positive, so the factorization succeeds
exactly for SPD matrices; this is why `is_positive_definite` is implemented
by attempting it. Cholesky needs no pivoting: from
$a_{jj} = \sum_k l_{jk}^2$ every $|l_{jk}| \le \sqrt{a_{jj}}$, so entries cannot
grow, and the computed factor satisfies
$\hat L \hat L^{\mathsf T} = A + \Delta A$ with
$|\Delta A| \le \gamma_{n+1} |\hat L|\,|\hat L^{\mathsf T}|$ (Higham,
Theorem 10.3).

### Symmetric eigenvalue problem

For real symmetric $A$ the spectral theorem gives $A = Q \Lambda Q^{\mathsf T}$
with $Q$ orthogonal and $\Lambda$ real diagonal. `eigen` computes it in two
phases.

**Householder tridiagonalization.** A Householder reflector
$H = I - 2 v v^{\mathsf T} / v^{\mathsf T} v$ is symmetric and orthogonal and
can map a vector onto a multiple of a coordinate vector. Applying $n - 2$
reflectors from both sides,

$$
Q_1^{\mathsf T} A Q_1 = T, \qquad Q_1 = H_1 H_2 \cdots H_{n-2},
$$

where $T$ is symmetric tridiagonal with diagonal $d$ and off-diagonal $e$. The
code accumulates $Q_1$ explicitly; together about $\tfrac83 n^3$ flops. Each
row is scaled by the sum of its absolute values before the reflector is formed,
which avoids overflow and underflow in $\lVert x \rVert_2$.

**Implicit QL with Wilkinson shifts.** The tridiagonal $T$ is diagonalized by
plane rotations. Before each sweep on the unreduced block starting at $l$, the
shift $\sigma$ is the eigenvalue of the leading $2 \times 2$ block
$\begin{pmatrix} d_l & e_l \\ e_l & d_{l+1} \end{pmatrix}$ closer to $d_l$.
With $g = (d_{l+1} - d_l)/(2 e_l)$ that block has eigenvalues

$$
\lambda_\pm = d_l + e_l \big(g \pm \sqrt{g^2 + 1}\big),
$$

and the one closer to $d_l$ is

$$
\sigma = d_l + e_l\big(g - \operatorname{sgn}(g)\sqrt{g^2+1}\big)
       = d_l - \frac{e_l}{g + \operatorname{sgn}(g)\sqrt{g^2 + 1}} ,
$$

the second form, used by the code, avoids cancellation. A sweep applies
Givens rotations that chase the resulting bulge and update $Q$ with the same
rotations. An off-diagonal entry is treated as zero when

$$
|e_m| \le \tau\,\big(|d_m| + |d_{m+1}| + 1\big),
$$

a test that is relative for large diagonal entries and absolute near zero.
Convergence with the Wilkinson shift is cubic for symmetric tridiagonal
matrices in practice and is never observed to fail on finite input; the code
nevertheless aborts after 60 sweeps for one eigenvalue. The whole procedure is
a product of orthogonal transformations and is backward stable: the computed
eigenvalues are exact for $A + \Delta A$ with
$\lVert \Delta A \rVert_2 = O(u)\lVert A \rVert_2$, so by Weyl's inequality

$$
|\hat\lambda_i - \lambda_i| \le \lVert \Delta A \rVert_2 = O(u)\,\lVert A \rVert_2 .
$$

Eigenvectors are accurate in proportion to $u\lVert A \rVert / \text{gap}$,
where the gap is the distance to the nearest other eigenvalue.

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
them. When $|\lambda_2| \ll |\lambda_1|$, the subtraction $m - \sqrt{\cdot}$
cancels and $\lambda_2$ loses relative accuracy; $\lambda_2 = \det A / \lambda_1$
would be the stable alternative.

### Power method

Starting from $x_0 = (1, \dots, 1)$ (or a coordinate vector if $A x_0 = 0$),
the method iterates

$$
y = A x_k, \qquad x_{k+1} = y / \lVert y \rVert_\infty, \qquad
\lambda_k = \frac{x_k^{\mathsf T} A x_k}{x_k^{\mathsf T} x_k} ,
$$

and stops when $\lVert A x_k - \lambda_k x_k \rVert_\infty \le \tau$. If
$A$ is diagonalizable with eigenvalues $|\lambda_1| > |\lambda_2| \ge \dots$ and
$x_0$ has a component $c_1 \ne 0$ along the eigenvector $v_1$, then

$$
A^{k} x_0 = \lambda_1^{k}\Big(c_1 v_1 + \sum_{i \ge 2} c_i \big(\tfrac{\lambda_i}{\lambda_1}\big)^{k} v_i\Big),
$$

so the direction converges linearly with ratio $|\lambda_2 / \lambda_1|$, and
for symmetric $A$ the Rayleigh quotient converges with ratio
$|\lambda_2 / \lambda_1|^2$. When $|\lambda_1| = |\lambda_2|$ with
$\lambda_1 \ne \lambda_2$ (for example $\pm 1$) the direction oscillates and
the residual test never passes, and when $A$ is nilpotent the iterate reaches
zero; both cases return `None`.

### Statistics

`variance` is the population variance computed in two passes: first the mean
$\bar a$, then $\tfrac1N \sum (a_i - \bar a)^2$. The one-pass formula
$\tfrac1N \sum a_i^2 - \bar a^2$ subtracts two nearly equal numbers when the
data have a large mean and a small spread, and can even return a negative
value; the two-pass form sums non-negative terms whose rounding error is
relative to the variance itself (Chan, Golub and LeVeque, 1983). The count
$N$ is accumulated as a sum of ones in `T`, exact up to $2^{53}$ entries for
`Double` and $2^{24}$ for `Float`.

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

Elimination must decide when a computed pivot "is zero". The package uses one
absolute threshold $\tau$ = `Tolerance::tolerance()` = $10^{-11}$ for `Double`
and `Float`, applied as follows:

| Routine | Test |
| --- | --- |
| LU (`determinant` for $n \ge 5$, `inverse`, `is_invertible`) | pivot $\lvert u_{kk}\rvert < \tau$ means singular |
| `rank` | largest remaining $\lvert a_{ik}\rvert < \tau$ means no pivot |
| `reduce_row_elimination` | entries $\le \tau$ are set to zero |
| `cholesky_decomposition` | radicand $\le \tau$ means not positive definite |
| `is_symmetric`, fast-path detection (identity, diagonal, permutation, triangular) | $\lvert a_{ij} - b_{ij}\rvert \le \tau$ |
| `eigen` deflation | $\lvert e_m\rvert \le \tau(\lvert d_m\rvert + \lvert d_{m+1}\rvert + 1)$ |
| `power_method` | residual $\lVert Ax - \lambda x\rVert_\infty \le \tau$ |

An absolute threshold is simple and predictable, but it is not scale
invariant. Scaling $A$ by $10^{-12}$ makes every pivot fall below $\tau$, so a
perfectly conditioned matrix is reported singular; scaling by $10^{12}$ lets a
numerically singular matrix pass. Scale data to order one before calling
these routines. For `Float`, $\tau = 10^{-11}$ is far below the unit roundoff
$\approx 6 \times 10^{-8}$, so the tests effectively check for exact zeros, and
nearly singular `Float` matrices are not detected. The trait is closed
(`pub`, not `pub(open)`), so these two instances are the only ones; a
scale-aware tolerance policy is future work and would be a breaking change.

### Fast paths

`inverse` recognizes the identity (returns a copy), diagonal matrices
(inverts the diagonal) and permutation matrices (returns the transpose, since
$P^{\mathsf T} P = I$ for a matrix whose columns are distinct coordinate
vectors). `determinant` recognizes triangular matrices for $n \ge 5$ and
multiplies the diagonal. Each test costs $O(n^2)$ and saves an $O(n^3)$
factorization. The tests use the tolerance, so a matrix that is diagonal up to
$\tau$ is treated as exactly diagonal.

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

## Correctness and invariants

- **Storage.** `data.length() == row * col` at all times; every public
  accessor checks the row and column separately.
- **Value-returning methods do not mutate.** Only `Unit`-returning methods,
  view writes and `reduce_row_elimination` change a matrix.
- **Checked/unchecked law.** `x.f() == Ok(x.unchecked_f())` whenever the
  precondition holds; `inverse` returns `Err(SingularMatrix)` exactly when
  `unchecked_inverse` returns `None`.
- **Determinant consistency.** For $n \ge 5$ and a matrix that is not
  triangular within $\tau$, `determinant` returns `0` exactly
  when the LU factorization reports a pivot below $\tau$, which is also when
  `is_invertible` returns `false` and `inverse` fails. For $n \le 4$ the closed
  formulas are used for `determinant`, while `is_invertible` still uses LU, so
  a matrix with a tiny non-zero determinant can be "not invertible" with a
  non-zero `determinant`.
- **Residual guarantees.** `cholesky_decomposition` and `eigen` return factors
  whose reconstruction error is $O(u)\lVert A \rVert$; `power_method` returns
  only pairs with residual at most $\tau$.
- **Complexity.** `*`: $rcn$; `determinant`, `inverse`: $O(n^3)$; `rank`,
  `reduce_row_elimination`: $O(rc\min(r, c))$; `cholesky_decomposition`:
  $n^3/3$; `eigen`: $O(n^3)$; `power_method`: $O(n^2)$ per iteration;
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
