///|
/// Matrix shape capability for objects with observable row/column dimensions.
///
/// `shape` deliberately lives below algebraic operations. Dynamic matrices can
/// expose dimensions without claiming closed addition or multiplication laws.
pub(open) trait MatrixShape {
  fn shape(Self) -> (Int, Int)
}

///|
/// Vector shape capability.
pub(open) trait VectorShape {
  fn length(Self) -> Int
}

///|
/// Vector object with additive linear structure.
///
/// This is the smallest useful generic vector object trait. It does not require
/// element-wise multiplication, dot product, norm, or a global zero.
pub(open) trait AdditiveVector: VectorShape + Add + Neg + Sub {}

///|
/// Vector object with element-wise/Hadamard multiplication.
pub(open) trait VecMulVector: AdditiveVector + Mul {}

///|
/// Vector object with a lawful global additive group structure.
///
/// Dynamic vectors whose zero depends on runtime length should implement
/// `AdditiveVector` only. Fixed-size vectors or dimension-indexed vector types can
/// implement this stronger trait when `Zero` is a real additive identity for
/// every value of the type.
pub(open) trait AdditiveVectorGroup: AdditiveVector + AddGroup {}

///|
/// Vector object whose element-wise multiplication forms a semiring.
pub(open) trait VecMulSemiringVector: VecMulVector + Semiring {}

///|
/// Vector object whose element-wise multiplication forms a ring.
pub(open) trait VecMulRingVector: VecMulVector + Ring {}

///|
/// Matrix object with observable shape and transpose.
///
/// This trait intentionally does not require matrix multiplication. Dynamic
/// rectangular matrix multiplication is a partial operation whose validity
/// depends on runtime shape.
pub(open) trait TransposeMatrix: MatrixShape {
  fn transpose(Self) -> Self
}

///|
/// Matrix object with closed additive operations.
pub(open) trait AdditiveMatrix: TransposeMatrix + Add + Neg + Sub {}

///|
/// Matrix object with a closed `*` operation.
///
/// This is appropriate for types whose multiplication is total at the type
/// level, or for dynamic matrix types whose implementation documents runtime
/// shape preconditions.
pub(open) trait MatMulMatrix: AdditiveMatrix + Mul {}

///|
/// Matrix object with lawful square matrix addition and multiplication
/// semiring structure.
///
/// This is appropriate for square fixed-size matrices or other matrix carriers
/// that can provide a real global `Zero` and `One`. Dynamic rectangular
/// matrices should usually stay at `AdditiveMatrix` or `MatMulMatrix`.
pub(open) trait SquareMatrixSemiring: MatMulMatrix + Semiring {}

///|
/// Matrix object with lawful ring structure.
pub(open) trait SquareMatrixRing: MatMulMatrix + Ring {}

///|
/// Floating scalar operation capability for numerical backends.
///
/// The inherited `Field` member is an operation dependency from the existing
/// Luna Flow ecosystem. This trait should be read as floating scalar operations,
/// not as a claim that IEEE floating-point values satisfy exact field laws.
pub(open) trait FloatingScalarOps: Field + Num + ApproxEq {}

///|
pub impl FloatingScalarOps for Float

///|
pub impl FloatingScalarOps for Double
