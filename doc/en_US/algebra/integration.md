# Algebra Ecosystem Integration

The `algebra` package is for mathematical capabilities of whole vector and
matrix objects. External libraries should implement only the traits whose
operation meaning, closure, and ownership behavior match their types.

## Choose an Algebra Level

Vector and matrix traits form separate capability paths:

| Path | Trait | Prerequisites | Mathematical commitment |
|---|---|---|---|
| Shape | `VectorShape` | None | Reports a vector length |
| Vector 1 | `AdditiveVector` | `VectorShape + Add + Neg + Sub` | Closed vector addition, negation, and subtraction |
| Vector 2 | `VecMulVector` | `AdditiveVector + Mul` | `Mul` means element-wise/Hadamard multiplication |
| Shape | `MatrixShape` | None | Reports matrix dimensions |
| Matrix 1 | `TransposeMatrix` | `MatrixShape` | Transpose returns the same matrix type |
| Matrix 2 | `AdditiveMatrix` | `TransposeMatrix + Add + Neg + Sub` | Closed matrix addition, negation, and subtraction |
| Matrix 3 | `MatMulMatrix` | `AdditiveMatrix + Mul` | `Mul` means matrix multiplication |

Stop at the smallest level required by downstream algorithms. Shape traits do
not imply element access. `TransposeMatrix` does not imply matrix
multiplication. `AdditiveVector` does not imply dot product, norm, scalar
action, or element-wise multiplication.

## Important Operator Boundary

The stronger traits reuse MoonBit operators and return `Self`, not `Result`.
Before implementing one, confirm all of the following:

- The operator already has the documented meaning for the type. In particular,
  `Mul` must not mean Hadamard multiplication on a `MatMulMatrix`.
- Results remain in the same concrete type.
- Runtime shape preconditions and failure behavior are clearly documented.
- The operation does not silently switch storage backends or ownership models.

Dynamic rectangular matrix multiplication may be invalid for some shape pairs.
`MatMulMatrix` does not standardize a checked error channel for that case. A
backend that needs a checked public operation should retain its checked method
and implement `MatMulMatrix` only when its operator contract is acceptable.

## Algebra and Container Are Independent

| Need | Use |
|---|---|
| Observe elements or convert storage | `container` read/build dictionaries |
| Express closed whole-object mathematics | `algebra` traits |
| Do both | Implement the relevant algebra traits and publish container dictionaries |

`MatrixShape` is a semantic shape capability; it is not checked element access.
`MatrixReadOps` includes shape plus checked indexed reads. Algebra transpose is
same-type and closed; container transpose may build a different target type.

Do not implement broad scalar traits merely to make a container type appear
more algebraic. Import `Luna-Flow/luna-generic` and `Luna-Flow/arithmetic`
directly only for scalar laws and operations the backend genuinely supports.

## Where Implementations Belong

Public operator and algebra implementations should normally live in the package
that owns the concrete type. This keeps method/trait resolution predictable and
lets the type owner define the operation semantics.

If a separate interoperability package is necessary, prefer an owned wrapper
type in that package and implement the algebra traits for the wrapper. Do not
assume a bridge package can safely redefine the meaning of operators on an
unowned external type.

## Complete Same-Type Example

This is deliberately a `1x1` matrix type, not a scalar pretending to be an
arbitrary dynamic matrix. For `1x1` matrices, transpose is the identity,
entry-wise addition is matrix addition, and multiplying the single entries is
exactly standard matrix multiplication. The fixed shape makes every operation
closed and removes runtime shape failure from the example.

```moonbit check
///|
struct EcosystemScalarMatrix {
  value : Int
}

///|
impl @algebra.MatrixShape for EcosystemScalarMatrix with fn shape(_) {
  (1, 1)
}

///|
impl @algebra.TransposeMatrix for EcosystemScalarMatrix with fn transpose(self) {
  self
}

///|
impl Add for EcosystemScalarMatrix with fn add(left, right) {
  { value: left.value + right.value }
}

///|
impl Neg for EcosystemScalarMatrix with fn neg(value) {
  { value: -value.value }
}

///|
impl Sub for EcosystemScalarMatrix with fn sub(left, right) {
  left + -right
}

///|
impl Mul for EcosystemScalarMatrix with fn mul(left, right) {
  { value: left.value * right.value }
}

///|
impl @algebra.AdditiveMatrix for EcosystemScalarMatrix

///|
impl @algebra.MatMulMatrix for EcosystemScalarMatrix

///|
fn[M : @algebra.MatMulMatrix] ecosystem_gram(matrix : M) -> M {
  matrix.transpose() * matrix
}

///|
test "external algebra type participates by capability" {
  let matrix : EcosystemScalarMatrix = { value: 3 }
  let other : EcosystemScalarMatrix = { value: 4 }
  inspect((matrix + other).value, content="7")
  inspect(matrix.transpose().value, content="3")
  inspect(ecosystem_gram(matrix).value, content="9")
}
```

An external library may stop after `MatrixShape`, `TransposeMatrix`, or
`AdditiveMatrix`; the final two implementations are not mandatory. A dynamic
matrix backend must additionally define what its operators do for incompatible
shapes rather than copying the fixed-shape assumptions from this example.

## Integration Checklist

- Select the smallest trait that matches the algorithm and the type.
- Confirm the existing `Add`, `Neg`, `Sub`, or `Mul` meaning matches the algebra
  trait before declaring conformance.
- Test closure, shape behavior, transpose shape reversal, and representative
  algebraic laws supported by the type.
- Test invalid dynamic shape behavior wherever an operator has runtime
  preconditions.
- Document whether operations allocate, share storage, or mutate hidden state.
- Keep dot product, norm, scalar action, decomposition, and solvers outside
  these traits unless a future dedicated capability defines them.
- Add container dictionaries separately when element-level interoperability is
  also required.
