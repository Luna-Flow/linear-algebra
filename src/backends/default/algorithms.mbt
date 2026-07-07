///|
/// Returns the shape of any shaped object.
pub fn[M : @algebra.MatrixShape] shape_of(matrix : M) -> (Int, Int) {
  @algebra.MatrixShape::shape(matrix)
}

///|
/// Matrix multiplication through the backend-independent capability surface.
pub fn[M : @algebra.MatMulMatrix] matmul(left : M, right : M) -> M {
  left * right
}

///|
/// Transpose through the backend-independent capability surface.
pub fn[M : @algebra.TransposeMatrix] transpose(matrix : M) -> M {
  @algebra.TransposeMatrix::transpose(matrix)
}
