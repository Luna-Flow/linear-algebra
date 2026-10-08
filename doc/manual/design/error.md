# error design

## Design goal

Many matrix operations are partial: a product needs composable shapes, a
determinant needs a square matrix, an inverse needs a non-singular one. The
`error` package gives these failures one shared, structured representation, so
that every checked API of the repository can turn a partial operation into a
total one and callers can decide what to do on the failure path without
parsing text.

## Constraints

- MoonBit `Result` and pattern matching are the idiomatic way to return a
  failure as a value; the type must work with both.
- The error type sits below every package that reports failures, so it may
  depend on nothing in this repository.
- The aborting behaviour of releases before `0.4.0` had to stay available
  under some name for existing callers.

## Design decisions

### A struct with a kind, not a `suberror`

**Options.** (a) A MoonBit `suberror` raised with `raise`. (b) A plain enum.
(c) A struct holding a kind and a message, returned in `Result`.

**Decision.** (c), following the Luna-Flow convention: `pub struct
LinearAlgebraError { kind, message }` with `pub enum LinearAlgebraErrorKind`.

**Why.** A `Result` is an ordinary value: it can be stored, mapped and
combined, and its presence is visible in the signature. The kind is the
contract for control flow; the message is free to change and carries details
such as which index was wrong. Keeping the enum read-only outside the package
and exposing snake_case constructors (`LinearAlgebraError::singular_matrix`)
lets the package add fields later without breaking callers.

### Predicates beside the enum

Every kind has an `is_*` predicate. Most callers only need a yes/no question
("was it singular?"), and a predicate keeps working when a kind gains a payload
in a future version, where an exhaustive `match` would not.

### Unchecked forms keep their old behaviour

Before `0.4.0` the matrix methods aborted or returned `Option`. Those
behaviours are preserved under explicit `unchecked_*` names
(`unchecked_inverse` still returns `Option`), and the short names became the
checked forms. A reader of `m.inverse()` therefore sees the safe form by
default, and the unsafe one announces itself.

### Reserved kinds

`InvalidLength`, `RaggedRows`, `NonConvergence` and `ArithmeticFailure` are not
produced by any API in this release; the corresponding operations
(`from_array`, `from_2d_array`, `eigen`) still abort. The kinds exist so that
downstream checked wrappers and future checked constructors can report these
failures in the shared vocabulary without a breaking change to the enum.

### No `Show` or `Debug`

The error implements only `Eq`. Formatting and localization are presentation
policy, which this package leaves to applications; `message` is the
diagnostic text.

## Mathematical background

### Partial functions

A partial function $f : X \rightharpoonup Y$ is a function defined on a subset
$\operatorname{dom} f \subseteq X$. Matrix operations are partial in the shape
or in the values:

| Operation | Domain |
| --- | --- |
| $(A, B) \mapsto AB$ | $\operatorname{cols}(A) = \operatorname{rows}(B)$ |
| $A \mapsto \operatorname{tr} A$, $A \mapsto \det A$ | $A$ square |
| $(A, k) \mapsto A^{k}$ | $A$ square, $k \ge 0$ |
| $A \mapsto A^{-1}$ | $A$ square and $\det A \ne 0$ |
| $A \mapsto \operatorname{mean}(A)$ | $A$ has at least one entry |

### Two ways to make them total

A program must do *something* on every input. There are two honest choices.

The **checked** form extends $f$ to all of $X$ with an error value:

$$
\hat f : X \to Y + E, \qquad
\hat f(x) = \begin{cases}
\mathrm{Ok}\,(f(x)) & x \in \operatorname{dom} f, \\
\mathrm{Err}\,(\varepsilon(x)) & \text{otherwise.}
\end{cases}
$$

The **unchecked** form keeps the type $X \to Y$ and makes membership in the
domain a precondition: on $x \notin \operatorname{dom} f$ it aborts (or, for
some routines documented as such, returns an unspecified value).

The two forms are related by the law that the repository maintains for every
checked/unchecked pair:

$$
x \in \operatorname{dom} f \;\Longrightarrow\;
\mathtt{checked}(x) = \mathrm{Ok}\,(\mathtt{unchecked}(x)),
\qquad
x \notin \operatorname{dom} f \;\Longrightarrow\;
\mathtt{checked}(x) = \mathrm{Err}\,(\_).
$$

In the code, almost every checked method is literally "validate, then call the
unchecked method", which makes the first implication hold by construction.

### Composition

Checked operations compose in the Kleisli category of the error monad: given
$\hat f : X \to Y + E$ and $\hat g : Y \to Z + E$,

$$
(\hat g \circ_K \hat f)(x) =
\begin{cases}
\hat g(y) & \hat f(x) = \mathrm{Ok}\,(y), \\
\mathrm{Err}\,(e) & \hat f(x) = \mathrm{Err}\,(e),
\end{cases}
$$

and the domain of the composite is
$\{x \in \operatorname{dom} f : f(x) \in \operatorname{dom} g\}$. In MoonBit
this is a `match` that returns early on `Err`, or `Result::bind`. A single
error type across the repository is what makes this composition possible
without conversions.

## Correctness and invariants

- **Kind determines the predicate.** For every error `e` exactly one `is_*`
  predicate returns `true`, the one named after `e.kind`.
- **Checked/unchecked law.** For every pair in `immut` and `mutable`, the law of
  the background section holds; the [`consistency`](consistency.md) and package
  tests exercise both paths.
- **Deterministic error choice.** When an input violates several
  preconditions, the checks run in a fixed order, so the reported kind is a
  function of the input. For example `pow` checks squareness before the sign of
  the exponent: a non-square matrix with a negative exponent always reports
  `NonSquareMatrix`.
- **No partial effects.** Checked operations of the immutable package never
  modify their arguments; checked operations of the mutable package validate
  before they write, so an `Err` result leaves the arguments unchanged.

## Alternatives rejected

- **Error codes as strings** (an older `E_`-prefixed convention mentioned in
  contributor notes). Strings cannot be matched exhaustively and invite parsing.
- **`Option` for every failure.** It loses the reason; `None` from an inverse
  cannot say whether the matrix was non-square or singular.
- **Separate error types per package.** Composition across `immut`, `mutable`
  and `container` would need conversions at every boundary.

## Boundaries

`error` defines values only. It implements no matrix algorithm, no recovery
strategy for singular or ill-conditioned input, no logging and no formatting.
It does not decide which operations are checked; that is the responsibility of
each package that returns a `LinearAlgebraError`.
