# arithmetic Design

## Responsibilities

- Keep low-level computable operations separate from semantic algebraic laws.
- Reuse existing ecosystem scalar traits instead of redefining them locally.
- Add only small operation traits when linear-algebra-facing code needs a
  stable name.

## Non-Responsibilities

- Do not define vector-space, module, matrix, or backend capabilities here.
- Do not make floating-point types claim exact algebraic laws.
- Do not import `immut`, `mutable`, or `backends/default`.

## Maintenance Notes

When adding a new trait, name the operation directly and document that it
represents availability of an operation, not a mathematical structure.
