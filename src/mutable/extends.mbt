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
pub extend Transpose with Add::{add}

///|
pub extend Transpose with Sub::{sub}

///|
pub extend Transpose with Mul::{mul}

///|
pub extend Transpose with Neg::{neg}

///|
pub extend Transpose with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Transpose with Eq::{not_equal}

///|
pub extend Transpose with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend Transpose with Show::{output}

///|
pub extend RowView with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend RowView with Show::{output}

///|
pub extend ColView with Show::{to_string}

///|
#deprecated("Use string interpolation or `Show::output` instead", skip_current_package=true)
#doc(hidden)
pub extend ColView with Show::{output}

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
