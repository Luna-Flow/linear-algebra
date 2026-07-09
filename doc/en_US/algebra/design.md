# algebra Design

## Responsibilities

- Represent semantic mathematical structures used by linear algebra.
- Keep structure-level traits separate from operation-only arithmetic traits.
- Avoid treating approximate floating-point behavior as exact algebraic law.
- Keep shape, additive operations, Hadamard multiplication, matrix
  multiplication, and scalar-valued mappings as separate capabilities.
- Express object-level linear algebra operations by composing existing operator
  traits such as `Add`, `Mul`, `Neg`, and `Sub` only when a trait actually needs
  those operations.
- Keep shared upstream scalar abstractions outside this package; import them
  directly in user code when an algorithm really needs them.

## Non-Responsibilities

- Do not import dense backend types.
- Do not define storage, mutability, or algorithm execution traits.
- Do not place inner product, norm, or other scalar-valued functors in the core
  structure layer.
- Do not introduce `Module` or `VectorSpace` without an explicit scalar-action
  model.
- Do not introduce a package-local shape-dependent zero in place of upstream
  `Zero`.
- Do not put partial operations such as dynamic rectangular matrix
  multiplication in the minimum matrix shape trait.

## Maintenance Notes

If a future trait needs scalar association, design it explicitly instead of
encoding a fixed scalar such as `Double` into a public trait.
