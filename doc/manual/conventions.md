# Repository conventions

These rules extend the Luna-Flow documentation standard for linear-algebra. The manual describes the current implementation on the branch; the current documentation baseline is **`0.5.0`**.

## Pages and chapters

- The [overview](index.md) describes the current release baseline: what the release contains, where to start reading, and how the packages are positioned. `CHANGELOG.md` owns the historical release timeline and older release notes.
- The `immut` and `mutable` packages are documented per type rather than per package: `api/immut/matrix.md` and `api/immut/vector.md`, and the same under `api/mutable/`, `design/` and `tutorial/`.
- The `integration/` chapter explains how external types join the `algebra` and `container` capability layers.
- Keep API references specification-oriented, tutorials usage-oriented, and design docs responsibility- and tradeoff-oriented
- Backend wrapper packages should document platform constraints, conversion boundaries, and whether behavior is implemented locally or delegated to an external library kernel
- Prefer short, direct sentences over rhetorical or release-note-style prose

## Shared rules for `mutable` and `immutable`

### API alignment

- `mutable` and `immutable` should expose the same public API whenever practical
- When both packages support the same capability, keep function names, parameter order, return semantics, and error conventions aligned
- If full alignment is not possible, the docs must state the difference, the reason, and the recommended usage
- Every new public API should be evaluated for both packages by default

### Design principles for `immutable`

- Prefer functional, declarative, and composable interface design
- Prefer returning new values instead of exposing in-place mutation semantics
- Avoid making callers reason about hidden state, shared mutable state, or timing-sensitive behavior
- The docs should emphasize value semantics, referential transparency, and composition patterns
- Even when there is a performance tradeoff, preserve clear and stable external semantics first

### Design principles for `mutable`

- Prioritize performance, memory reuse, and low-level execution efficiency
- Internal mutable state, in-place updates, and other side effects are acceptable inside the library
- Those side effects should remain encapsulated in the implementation rather than leaking into the caller's mental model
- The public API should still feel pure, stable, and function-oriented instead of exposing internal mutability as a contract
- Introduce package-specific deviations from `immutable` only when the performance benefit is concrete and necessary

### Documentation requirements

- Use the same section structure and terminology across `mutable` and `immutable` API docs whenever possible
- Cross-reference corresponding APIs so readers can compare semantics and cost models easily
- Clearly separate external semantics from internal implementation strategy
- Performance details such as caching, reuse, and in-place computation belong in design pages or the `performance/` chapter, not in the API semantic contract.
- If a `mutable` API has observable behavior due to a performance-oriented design choice, document that behavior explicitly rather than only describing the internal implementation

## Translations

- Chinese translations should read like natural written technical Chinese, not word-for-word English translation.
- Japanese translations should read like natural technical Japanese, not a literal structural copy of Chinese or English phrasing.
