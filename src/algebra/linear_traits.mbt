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
