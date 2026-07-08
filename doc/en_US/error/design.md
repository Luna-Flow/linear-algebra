# error Design

## Responsibilities

- Provide the shared error vocabulary for checked linear-algebra APIs.
- Keep a stable machine-readable `kind` beside a human-readable `message`.
- Let callers branch on common failure categories without parsing text.
- Preserve arithmetic errors from lower-level scalar operations through
  `ArithmeticFailure`.

## Non-Responsibilities

- Do not implement matrix, vector, or backend algorithms here.
- Do not define recovery policies for singular matrices, non-convergence, or
  arithmetic failures.
- Do not decide logging, localization, or presentation formatting.
- Do not use the text message as the semantic contract for control flow.

## Maintenance Notes

Add a new error kind only when checked public APIs need to expose a distinct
class of failure. Keep constructors and predicate methods aligned with the enum
so callers can create and inspect errors without destructuring values directly.
