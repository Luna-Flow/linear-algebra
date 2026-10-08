// Explicit trait-method promotions (see core AGENTS.md "Trait-method promotion").

///|
pub extend Matrix with Add::{add}

///|
pub extend Matrix with Sub::{sub}

///|
pub extend Matrix with Mul::{mul}

///|
pub extend Matrix with Neg::{neg}

///|
pub extend Matrix with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Matrix with Eq::{not_equal}

///|
pub extend Matrix with @internal.HasShape::{shape}

///|
pub extend Matrix with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend Matrix with Show::{output}

///|
pub extend MatrixFn with Add::{add}

///|
pub extend MatrixFn with Sub::{sub}

///|
pub extend MatrixFn with Neg::{neg}

///|
pub extend MatrixFn with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend MatrixFn with Eq::{not_equal}

///|
pub extend MatrixFn with @internal.HasShape::{shape}

///|
pub extend MatrixFn with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend MatrixFn with Show::{output}

///|
pub extend Vector with Add::{add}

///|
pub extend Vector with Mul::{mul}

///|
pub extend Vector with Neg::{neg}

///|
pub extend Vector with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Vector with Eq::{not_equal}

///|
pub extend Vector with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend Vector with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Vector with @debug.Debug::{to_repr}

///|
#deprecated("Use `@qc_core.Arbitrary::arbitrary` (quickcheck) instead", skip_current_package=true)
#doc(hidden)
pub extend Vector with @qc_core.Arbitrary::{arbitrary}
