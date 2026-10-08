// Explicit trait-method promotions (see core AGENTS.md "Trait-method promotion").

///|
pub extend DenseVector with Add::{add}

///|
pub extend DenseVector with Sub::{sub}

///|
pub extend DenseVector with Mul::{mul}

///|
pub extend DenseVector with Neg::{neg}

///|
pub extend ImmutableDenseVector with Add::{add}

///|
pub extend ImmutableDenseVector with Sub::{sub}

///|
pub extend ImmutableDenseVector with Mul::{mul}

///|
pub extend ImmutableDenseVector with Neg::{neg}

///|
pub extend DenseMatrix with Add::{add}

///|
pub extend DenseMatrix with Sub::{sub}

///|
pub extend DenseMatrix with Mul::{mul}

///|
pub extend DenseMatrix with Neg::{neg}

///|
pub extend DenseMatrix with @algebra.MatrixShape::{shape}

///|
pub extend DenseMatrix with @algebra.TransposeMatrix::{transpose}

///|
pub extend ImmutableDenseMatrix with Add::{add}

///|
pub extend ImmutableDenseMatrix with Sub::{sub}

///|
pub extend ImmutableDenseMatrix with Mul::{mul}

///|
pub extend ImmutableDenseMatrix with Neg::{neg}

///|
pub extend ImmutableDenseMatrix with @algebra.MatrixShape::{shape}

///|
pub extend ImmutableDenseMatrix with @algebra.TransposeMatrix::{transpose}
