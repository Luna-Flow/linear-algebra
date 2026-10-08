// Explicit trait-method promotions (see core AGENTS.md "Trait-method promotion").

///|
pub extend BlasVector with Add::{add}

///|
pub extend BlasVector with Sub::{sub}

///|
pub extend BlasVector with Neg::{neg}

///|
pub extend BlasVector with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend BlasVector with Eq::{not_equal}

///|
pub extend BlasVector with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend BlasVector with Show::{output}

///|
pub extend BlasMatrix with Add::{add}

///|
pub extend BlasMatrix with Sub::{sub}

///|
pub extend BlasMatrix with Mul::{mul}

///|
pub extend BlasMatrix with Neg::{neg}

///|
pub extend BlasMatrix with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend BlasMatrix with Eq::{not_equal}

///|
pub extend BlasMatrix with @algebra.MatrixShape::{shape}

///|
pub extend BlasMatrix with @algebra.TransposeMatrix::{transpose}

///|
pub extend BlasMatrix with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend BlasMatrix with Show::{output}
