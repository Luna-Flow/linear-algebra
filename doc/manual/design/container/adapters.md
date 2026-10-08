# container/adapters design

## Design goal

The [`container`](../container.md) package defines capabilities without
depending on any concrete type. Somebody has to provide the dictionaries for
the repository's own types, and that code needs to see both the capability
records and every concrete package. `container/adapters` is that place: a leaf
package that depends on everything it adapts, so that nothing else has to.

## Mathematical background

An adapter is the evidence that a concrete type *represents* the abstract
objects of the container model (see the [container design](../container.md)).
For a type `V` it supplies the denotation $\llbracket\cdot\rrbracket : V \to ([n] \to T)$
through `length` and `get`, and, where possible, a section of it through
`tabulate`:

$$
\llbracket \mathtt{tabulate}(n, f) \rrbracket = f|_{[n]} .
$$

For a view, the denotation is computed from the underlying matrix $A$ of shape
$(r, c)$:

$$
\llbracket \mathrm{row}_i(A) \rrbracket(j) = A_{ij}, \qquad
\llbracket \mathrm{col}_j(A) \rrbracket(i) = A_{ij}, \qquad
\llbracket A^{\mathsf T}_{\text{view}} \rrbracket(i, j) = A_{ji} .
$$

A view has no `tabulate`: building would have to create an underlying matrix,
and the result would no longer be a view of anything the caller holds. The
mutable edit of a view writes through to $A$, which is exactly what a view is
for.

## Design decisions

### A separate leaf package

**Problem.** If `container` contained the adapters, it would depend on
`immut`, `mutable` and `backends/default`, and every external library that
only wants the capability records would pull in all concrete types.

**Decision.** The records and algorithms stay in `container`, which depends
only on `error`. The adapters live in `container/adapters`, which depends on
`container`, `immut`, `mutable` and `backends/default`. No package of the
repository depends on the adapters.

**Why.** Dependencies then point from specific to general. External libraries
publish their own dictionaries against `container` alone, following the
[integration guide](../../integration/container.md).

### One factory per type and capability

Each factory has a name of the form `<type>_<capability>_ops` and returns a new
record. Generic functions cannot be stored as values with free type
parameters, so a factory function is the way to provide "the read dictionary
for `@immut.Matrix[T]`, for every `T`". The factories have no constraints on
`T`, because reading, building and editing never inspect elements.

### Editing model follows ownership

Immutable types and wrappers get persistent edits; mutable types, views and
the mutable wrappers get mutable edits. Offering a persistent edit for a
mutable matrix would require a full copy per `set`, which hides an $O(rc)$ cost
behind an $O(1)$-looking call; offering a mutable edit for an immutable matrix
is impossible without breaking its value semantics.

### Validate before delegating

The concrete types abort on bad indices. Each adapter checks the index or
shape first and returns the error value, so the dictionaries satisfy the
panic-free contract of `container` even though the methods they call do not.

## Correctness and invariants

- Every read adapter satisfies $\mathtt{get}(v, i) = \mathrm{Ok}(v[i])$ on
  valid indices and `IndexOutOfBounds` elsewhere; builders satisfy the
  `tabulate`/`get` law above.
- Builders call the initializer exactly once per entry, in row-major order.
- Persistent edits never modify their argument: `@immut` updates are path
  copies of a persistent vector.
- Mutable edits of views modify the underlying matrix and nothing else.
- Every factory runs in $O(1)$; the dictionary calls cost what the underlying
  method costs ($O(1)$ for `@mutable` reads, $O(\log_{32} n)$ for `@immut`).

## Alternatives rejected

- **Adapters inside each concrete package.** `immut` and `mutable` would then
  depend on the experimental `container` layer, which would make the stable
  concrete APIs inherit its instability.
- **Adapters for external types.** This repository contains adapters only for
  the types it maintains; external libraries own theirs.

## Boundaries

The package adds no capability and no algorithm, only evidence for existing
types. It provides no build dictionaries for views, no persistent edits for
mutable types, and no adapters for types outside this repository. The
withdrawn OpenBLAS backend's adapters are preserved with it in
`contrib/openblas_backend` and are not part of this package.
