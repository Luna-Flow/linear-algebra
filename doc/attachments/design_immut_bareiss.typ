#set document(title: "Bareiss elimination: exactness and correctness")
#set page(paper: "a4", margin: 2.2cm)
#set text(size: 10.5pt)
#set par(justify: true)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[Bareiss elimination: exactness and correctness]

  Luna-Flow/linear-algebra · `immut` determinant
]

This note proves the two facts that `@immut.Matrix::determinant` relies on for
$n >= 5$: every intermediate value of the fraction-free recurrence is a minor
of the input, so all divisions are exact in an integral domain, and the last
value is the determinant. Indices are zero-based, as in the code.

= Setting

Let $R$ be a commutative ring and $A = (a_(i j)) in R^(n times n)$. For
$0 <= k <= n$ let $M_k$ be the leading $k times k$ block of $A$ (rows and
columns $0, dots, k-1$), with $det M_0 = 1$. For $i, j >= k$ define the
*bordered minor*

$ d^((k))_(i j) = det mat(M_k, c_j^((k)); r_i^((k)), a_(i j)) , $

where $c_j^((k)) = (a_(0 j), dots, a_(k-1, j))^T$ and
$r_i^((k)) = (a_(i 0), dots, a_(i, k-1))$. In particular
$d^((0))_(i j) = a_(i j)$, $d^((k))_(k k) = det M_(k+1)$, and
$d^((n-1))_(n-1, n-1) = det A$.

The algorithm computes $b^((0))_(i j) = a_(i j)$ and, for $k = 0, dots, n-2$
and $i, j > k$,

$ b^((k+1))_(i j) = (b^((k))_(k k) b^((k))_(i j) - b^((k))_(i k) b^((k))_(k j)) / b^((k-1))_(k-1, k-1) , $

with the convention $b^((-1))_(-1, -1) = 1$.

= Sylvester's identity

*Theorem.* For all $k$ and all $i, j > k$,

$ d^((k+1))_(i j) dot det M_k = d^((k))_(k k) d^((k))_(i j) - d^((k))_(i k) d^((k))_(k j) . $

*Proof.* Both sides are polynomials with integer coefficients in the entries of
$A$. It therefore suffices to prove the identity over the field of rational
functions $QQ(a_(00), dots, a_(n-1, n-1))$ in independent indeterminates; it
then holds in every commutative ring by specialization. Over that field every
$M_k$ is invertible.

For invertible $M_k$, block elimination gives

$ det mat(M_k, c; r, x) = det M_k dot (x - r M_k^(-1) c) . $

Write $s^((k))_(i j) = a_(i j) - r_i^((k)) M_k^(-1) c_j^((k))$, the entries of
the Schur complement $A slash M_k$. Then $d^((k))_(i j) = det M_k dot s^((k))_(i j)$.

The quotient property of Schur complements states that eliminating one more row
and column is one step of Gaussian elimination on the Schur complement:

$ s^((k+1))_(i j) = s^((k))_(i j) - (s^((k))_(i k) s^((k))_(k j)) / s^((k))_(k k) , $

and $det M_(k+1) = det M_k dot s^((k))_(k k)$. Substituting,

$
d^((k+1))_(i j)
  &= det M_(k+1) dot s^((k+1))_(i j) \
  &= det M_k (s^((k))_(k k) s^((k))_(i j) - s^((k))_(i k) s^((k))_(k j)) \
  &= (d^((k))_(k k) d^((k))_(i j) - d^((k))_(i k) d^((k))_(k j)) / det M_k ,
$

which is the claim after multiplying by $det M_k$. #h(1fr) $square$

= Consequences

*Corollary 1 (the recurrence computes minors).* $b^((k))_(i j) = d^((k))_(i j)$
whenever the divisions are defined.

By induction on $k$: the case $k = 0$ is the definition, and the step is the
theorem, because $b^((k-1))_(k-1, k-1) = d^((k-1))_(k-1, k-1) = det M_k$.

*Corollary 2 (exact division).* If $R$ is an integral domain and
$det M_k != 0$, the numerator of the recurrence is divisible by $det M_k$ in
$R$, and the quotient is the minor $d^((k+1))_(i j) in R$. In an integral
domain the quotient by a non-zero element is unique, so integer division in
`Int` or `BigInt` returns exactly this value (absent overflow).

*Corollary 3 (result).* $b^((n-1))_(n-1, n-1) = d^((n-1))_(n-1, n-1) = det A$.

= Pivoting

Row $i$ of $b^((k))$ depends only on row $i$ of $A$ and on rows
$0, dots, k-1$. Exchanging two rows with indices $>= k$ before step $k$
therefore yields exactly the values of the algorithm run on $A$ with those rows
exchanged, whose determinant is $-det A$. The code multiplies the result by
$-1$ for every exchange.

If every candidate pivot $b^((k))_(i k)$, $i >= k$, is zero, then all bordered
minors $d^((k))_(i k)$ vanish. Since $det M_k != 0$ at this point (it is the
previous pivot), this means $s^((k))_(i k) = 0$ for all $i >= k$: the $k$-th
column of the Schur complement is zero, so the Schur complement is singular and

$ det A = det M_k dot det(A slash M_k) = 0 , $

which is what the code returns.

= Size bound

Every $b^((k))_(i j)$ is a $(k+1) times (k+1)$ minor of $A$, so Hadamard's
inequality gives $|b^((k))_(i j)| <= product_r norm("row"_r)_2$ over the rows
involved, at most $H = product_r max(1, norm("row"_r)_2)$. The numerator of the
recurrence is a difference of two products of such minors, hence bounded by
$2 H^2$. For fixed-width integers, no intermediate value overflows when
$2 H^2$ is below the largest representable integer.
