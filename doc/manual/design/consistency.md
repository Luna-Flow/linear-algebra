# consistency design

## Design goal

`immut` and `mutable` implement the same core operations twice, with
different storage and different kernels, and `MatrixFn` implements them a
third time lazily. The `consistency` package checks that these implementations
denote the same mathematics, so that users can switch representations without
changing results, and so that a kernel optimization in one package cannot
silently change semantics.

## Constraints

- `immut` and `mutable` must not depend on each other.
- Comparisons must be exact, so that a failing test always means a real
  disagreement and never rounding noise.
- The checks must run in the default test gate without slowing it down.

## Design decisions

### A separate package

The checks need both `immut` and `mutable`, and neither package should depend
on the other. A third package that imports both for tests only keeps the
dependency graph clean. Its tests are whitebox tests (`*_wbtest.mbt`) so that
they can use unqualified helper names.

### Documented differences are tested too

Where the packages intentionally differ (for example `set` mutates in
`mutable` and returns a new value in `immut`), a test pins the difference down,
so that it stays a decision rather than an accident.

## Mathematical background

### Agreement as a homomorphism property

Let $\iota : \texttt{@immut.Matrix[T]} \to \texttt{@mutable.Matrix[T]}$ be the
conversion that keeps shape and entries. The packages agree on an operation
$\omega$ when $\iota$ commutes with it:

$$
\iota\big(\omega_{\text{immut}}(A, B)\big) = \omega_{\text{mutable}}\big(\iota A, \iota B\big).
$$

The tests compare both sides through a common observation (`to_array`,
`to_2d_array` or `to_string`), which is injective on matrices of a known shape.

### Laws instead of examples

Besides agreement, the tests check algebraic laws in both packages: the
identity laws, $(AB)^{\mathsf T} = B^{\mathsf T} A^{\mathsf T}$, associativity
of the product, distributivity, and $\operatorname{tr}(A^{\mathsf T}) = \operatorname{tr}(A)$.
The transpose product law needs commuting scalars; the tests use `Int`.

### Why small integers

All checks use `Int`. Integer arithmetic is the exact ring
$\mathbb{Z}/2^{32}\mathbb{Z}$, even on overflow, so every law can be tested
with `==` and every failure is a real disagreement. With `Double`, different
summation orders legitimately differ by rounding (see the
[mutable design](mutable.md)), and the tests would need tolerances that could
hide real bugs. The property-based tests draw random $2 \times 2$ integer
matrices with quickcheck and check the laws on each sample.

## Correctness and invariants

The package asserts, for all tested inputs: equal results for `+`, `*`,
transpose, trace, `pow`, determinant (integer inputs), constructors and
conversions; the semiring laws of matrix arithmetic; and the documented
behaviour of degenerate shapes such as $2 \times 0$.

## Alternatives rejected

- **Floating-point agreement tests.** They would need tolerances and test
  rounding rather than semantics; numerical accuracy is tested inside
  `mutable` instead.
- **Testing only examples.** Random inputs find disagreements on values the
  author did not think of, such as negative entries and zeros.

## Boundaries

The package has no public API and is not published for use. It does not test
numerical routines that exist in only one package (inverse, Cholesky,
eigenvalues) or performance.
