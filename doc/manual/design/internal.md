# internal design

## Design goal

`immut` and `mutable` check the same preconditions (squareness, bounds,
compatible shapes) and must report them identically. `internal` keeps one
implementation of each check, so the two packages cannot drift apart, without
exposing the helpers to downstream code.

## Constraints

- `immut` and `mutable` must report every precondition failure with the same
  kind and in the same order.
- The helpers must not become public API, and the concrete packages must not
  depend on the experimental `algebra` layer for the shape method.

## Design decisions

### An internal package

MoonBit's internal-package rule restricts imports of
`Luna-Flow/linear-algebra/internal` to packages of this module. The helpers
can therefore change freely, while their effects are specified on the public
methods.

### `HasShape` separate from `MatrixShape`

`@algebra.MatrixShape` has the same method, but `algebra` is experimental and
the concrete packages should not depend on it. `HasShape` gives the guards a
bound that `immut` and `mutable` implement locally. The repetition is the cost
of keeping the stable concrete packages independent of the experimental layer.

### Row before column

`ensure_index_in_bounds` checks the row first, then the column, and each
against its own dimension. Checking the flat offset $r c' + c$ against $rc'$
instead would accept a column index that spills into the next row.

## Mathematical background

Each guard is the characteristic test of a domain from the
[error design](error.md): $\operatorname{dom}(\operatorname{tr}) = \{A : r = c\}$,
$\operatorname{dom}(\cdot) = \{(A, B) : c_A = r_B\}$, and so on. Writing the
test once as a total function $\chi : X \to \mathrm{Unit} + E$ gives both
forms of a partial operation:

$$
\mathtt{checked}(x) = \chi(x) \mathbin{>\!\!>\!\!=} (\_ \mapsto \mathrm{Ok}(f(x))),
\qquad
\mathtt{unchecked}(x) = \begin{cases} f(x) & \chi(x) = \mathrm{Ok}(()) \\ \text{abort} & \text{otherwise.} \end{cases}
$$

Deriving the aborting guard from the checked one (`ensure_x` matches on
`ensure_x_checked`) makes the two agree on every input by construction.

## Correctness and invariants

- `ensure_x(m)` aborts if and only if `ensure_x_checked(m)` returns `Err`.
- Each checked guard returns the error kind listed on the [API page](../api/internal.md),
  with a fixed message.
- All guards run in $O(1)$ and only call `shape`.

## Alternatives rejected

- **Duplicating the checks in each package**, which is how bounds behaviour
  diverged before the `0.4` line.
- **Public helpers.** They would become API that downstream code depends on.

## Boundaries

`internal` checks shapes and indices only. It contains no arithmetic, no
storage, and no checks that depend on values (singularity, emptiness of data,
convergence).
