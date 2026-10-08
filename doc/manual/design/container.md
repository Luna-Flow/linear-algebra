# container design

## Design goal

Generic code often needs to move data between matrix and vector
representations, or to look at individual entries, without caring about
storage: dense arrays, persistent vectors, views, lazy functions, foreign
buffers. `container` describes those structural capabilities separately from
the mathematical ones of [`algebra`](algebra.md), so that a type can take part
in data movement without claiming algebraic laws, and the other way round.

## Constraints

- MoonBit traits have one `Self` parameter and no associated types, so a
  trait cannot relate a container type to its element type.
- The package must not import any concrete type, so that external libraries
  can publish dictionaries against it alone.
- Generic algorithms cannot know how a container reacts to a bad index, so the
  contract must make failure a value.

## Design decisions

### Operation dictionaries instead of traits

**Problem.** A capability such as "read elements of type `T` from container
`V`" relates two types. MoonBit traits have one `Self` parameter and no
associated types.

**Options.** (a) A trait on `V` that fixes the element type, for example
through a generic method. (b) A trait on `V` per element type. (c) A record of
functions parametrized by both types.

**Decision.** (c): `VectorReadOps[V, T]` and its siblings are plain structs of
closures, built with `new` and passed explicitly.

**Why.** A record expresses the two-parameter relation directly. It also lets
one container type publish several dictionaries, for example a checked and a
clamping read, or dictionaries for different element types of a polymorphic
foreign handle, which a trait instance (unique per type) could not. The cost is
explicit passing; the algorithms take the dictionaries as arguments.

### Read and build are separate

A view can be read but not built; a write-only sink can be built but not read;
a foreign handle may allow only reads. Combining read and build into one
capability would force every such type either to fake the missing half or to
stay out. The algorithms state exactly which half they need on each side:
source read, target build.

### Two editing models

Persistent editing returns a new value; mutable editing changes the argument
and returns `Unit`. They are different contracts: generic code written for the
persistent form may keep the old value and expect it unchanged, which a mutable
implementation would violate. So they are separate records, and a type
provides the one matching its ownership model. Neither implies resizing,
insertion or deletion.

### Read everything, then build

The algorithms read the whole source into a temporary array before calling
`tabulate`. This costs $O(n)$ memory, but it makes failure atomic: if any read
fails, the algorithm returns that error before the target exists, so callers
never see a half-built container. It also calls the user's mapping function
exactly once per element, in row-major order, which matters when the function
has effects or is expensive.

### Checked everywhere

Every dictionary function returns a `Result`. A generic algorithm cannot know
the bounds behaviour of an arbitrary container, so the contract requires each
implementation to report bad indices and shapes as values instead of aborting.
The repository adapters validate before they touch storage.

## Mathematical background

### A container is a representation of a function

Abstractly, a vector of length $n$ with elements in $T$ is a function
$v : [n] \to T$, where $[n] = \{0, \dots, n-1\}$, and an $r \times c$ matrix is a
function $m : [r] \times [c] \to T$. A concrete container type `V` *represents*
such functions. Two capabilities connect the representation with the function
it denotes:

- **read** gives the denotation: $\llbracket v \rrbracket(i) = \mathtt{get}(v, i)$
  for $i < \mathtt{length}(v)$;
- **build** goes the other way: $\mathtt{tabulate}(n, f)$ is some
  representation of $f$ restricted to $[n]$.

The basic law tying them together is that building and then reading returns
the function you started from:

$$
\mathtt{length}(\mathtt{tabulate}(n, f)) = n, \qquad
\mathtt{get}(\mathtt{tabulate}(n, f), i) = \mathrm{Ok}\,(f(i)) \quad (0 \le i < n).
$$

Reading and then building gives a container that is *observationally* equal to
the original: indistinguishable through `get`, though perhaps a different
value in memory.

### Generic algorithms as compositions

With these two maps, the generic algorithms are compositions of functions on
the denotations:

$$
\begin{aligned}
\llbracket \mathtt{vector\_map}(v, g) \rrbracket &= g \circ \llbracket v \rrbracket, \\
\llbracket \mathtt{matrix\_transpose}(m) \rrbracket(i, j) &= \llbracket m \rrbracket(j, i).
\end{aligned}
$$

Two laws follow directly and are what the tests check:

$$
\begin{aligned}
\mathtt{map}(v, \mathrm{id}) &\simeq \mathtt{convert}(v), &
\mathtt{map}(\mathtt{map}(v, g), h) &\simeq \mathtt{map}(v, h \circ g), \\
\mathtt{transpose}(\mathtt{transpose}(m)) &\simeq \mathtt{convert}(m), &
\operatorname{shape}(\mathtt{transpose}(m)) &= (c, r),
\end{aligned}
$$

where $\simeq$ is observational equality. The first pair are the functor laws:
on denotations, `map` is post-composition, and post-composition preserves
identities and composition.

### Editing as a lens

A persistent edit $\mathtt{set}(v, i, x)$ and a read $\mathtt{get}(v, i)$ form
a lens on position $i$, and a correct implementation satisfies the three lens
laws for every valid index:

$$
\begin{aligned}
\mathtt{get}(\mathtt{set}(v, i, x), i) &= x
  && \text{(you get what you set)} \\
\mathtt{get}(\mathtt{set}(v, i, x), j) &= \mathtt{get}(v, j), \quad j \ne i
  && \text{(nothing else changes)} \\
\mathtt{set}(v, i, \mathtt{get}(v, i)) &\simeq v
  && \text{(setting what is there changes nothing)}
\end{aligned}
$$

and, being persistent, it leaves $v$ itself unchanged. A mutable edit satisfies
the same equations with "the state of $v$ after the call" in place of the
returned value.

## Correctness and invariants

- **Shape preservation.** `map` and `convert` preserve $(r, c)$ exactly,
  including $0 \times n$ and $n \times 0$; `transpose` produces $(c, r)$. The
  algorithms never call `get` on an empty dimension.
- **Index mapping of the transpose.** The source is buffered in row-major
  order, so source entry $(j, i)$ sits at offset $j c + i$. The target
  initializer at $(i, j)$ reads that offset, which is exactly
  $\llbracket m \rrbracket(j, i)$.
- **Error precedence.** A negative reported shape gives `NegativeDimension`
  before any read; otherwise the first failing read (in row-major order) is
  returned; otherwise the result of `tabulate` is returned unchanged.
- **Complexity.** $n$ reads, one `tabulate` that evaluates the initializer $n$
  times, and $n$ calls of the mapping function, for $n = r c$.

## Alternatives rejected

- **Generic `insert`, `delete`, `create` or `remove`.** Removing a sparse
  entry, setting it to zero, deleting a row and resizing a matrix are different
  operations; one name for all of them would have no clear law.
- **Optimized kernel operations in the read dictionary** (row swaps, scaled row
  additions). Requiring them would exclude simple containers. A future
  `MatrixKernelOps`-style dictionary may be added beside read and build as an
  optional capability.
- **Streaming algorithms without the buffer.** They would save memory but give
  up failure atomicity for targets that are built incrementally.

## Boundaries

`container` defines no storage, no arithmetic and no algebraic laws. It
provides no sparse or lazy containers itself, no resizing or structural
editing, and no high-performance kernels; the algorithms are $O(n)$ copies
through closures and are meant for interchange, not inner loops. Concrete
dictionaries for this repository's types live in
[`container/adapters`](container/adapters.md).
