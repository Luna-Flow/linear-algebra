# Luna-Flow/linear-algebra

This documentation tracks the current repository baseline for **v0.3.0**.

The `mutable` numerical APIs use the shared `Luna-Flow/arithmetic.Sqrt`
capability, while integral embeddings follow
`Luna-Flow/luna-generic.IntegralHomomorphism`. `Tolerance` remains local to the
`mutable` package in this release.

## Repository Positioning

Matrix and vector infrastructure with mutable and immutable execution models.

## Documentation Layout

- `README.md` for the repository narrative and release baseline.
- `doc_standard.md` for the documentation contract.
- Module or subsystem folders with `api.md`, `tutorial.md`, and `design.md`.

## Module Overview

- **`immut/matrix`**: Implemented around `src/immut`.
- **`immut/vector`**: Implemented around `src/immut`.
- **`mutable/matrix`**: Implemented around `src/mutable`.
- **`mutable/vector`**: Implemented around `src/mutable`.

## Documentation Entry Points

- API Reference: [immut/matrix](./immut/matrix/api.md)
- API Reference: [immut/vector](./immut/vector/api.md)
- API Reference: [mutable/matrix](./mutable/matrix/api.md)
- API Reference: [mutable/vector](./mutable/vector/api.md)
