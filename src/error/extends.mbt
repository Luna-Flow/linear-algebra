// Explicit trait-method promotions (see core AGENTS.md "Trait-method promotion").

///|
pub extend LinearAlgebraErrorKind with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend LinearAlgebraErrorKind with Eq::{not_equal}

///|
pub extend LinearAlgebraError with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend LinearAlgebraError with Eq::{not_equal}
