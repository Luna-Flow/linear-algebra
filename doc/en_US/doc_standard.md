# Documentation Standard

The documentation in this repository describes the **current implementation on
the branch**. As of `2026-07-09`, the active documentation baseline is
**`0.4.2`**.

## Document Types and Organization

### Main Document Types

1. **API Reference Documentation (api.md)** - Detailed specifications for each public interface
2. **User Guide (tutorial.md)** - User-oriented tutorials and best practices
3. **Design Documentation (design.md)** - Architecture and algorithm descriptions for developers
4. **Performance Reports** - Reserved for future performance and measurement documentation

### Documentation Organization Principles

- Organized by package/file, for example:

  ```txt
  doc/
    |- en_US
    |- ja_JP
    |- zh_CN
        |- immut
        |   |- matrix
        |   |   |- api.md
        |   |   |- tutorial.md
        |   |   |- design.md
        |   |- ...
        |- mutable
        |   |- matrix
        |   |   |- ...
        |   |- ...
        |- ...
  ```

- Further subdivided into `vector`, `matrix`, and similar files under each package
- Maintain consistency between documentation and code structure
- Do not document unreleased APIs unless they already exist in the repository implementation

## Shared Rules For `mutable` And `immutable`

### API Alignment

- `mutable` and `immutable` should expose the same public API whenever practical
- When both packages support the same capability, keep function names, parameter order, return semantics, and error conventions aligned
- If full alignment is not possible, the docs must state the difference, the reason, and the recommended usage
- Every new public API should be evaluated for both packages by default

### Design Principles For `immutable`

- Prefer functional, declarative, and composable interface design
- Prefer returning new values instead of exposing in-place mutation semantics
- Avoid making callers reason about hidden state, shared mutable state, or timing-sensitive behavior
- The docs should emphasize value semantics, referential transparency, and composition patterns
- Even when there is a performance tradeoff, preserve clear and stable external semantics first

### Design Principles For `mutable`

- Prioritize performance, memory reuse, and low-level execution efficiency
- Internal mutable state, in-place updates, and other side effects are acceptable inside the library
- Those side effects should remain encapsulated in the implementation rather than leaking into the caller's mental model
- The public API should still feel pure, stable, and function-oriented instead of exposing internal mutability as a contract
- Introduce package-specific deviations from `immutable` only when the performance benefit is concrete and necessary

### Documentation Requirements

- Use the same section structure and terminology across `mutable` and `immutable` API docs whenever possible
- Cross-reference corresponding APIs so readers can compare semantics and cost models easily
- Clearly separate external semantics from internal implementation strategy
- Performance details such as caching, reuse, and in-place computation belong in design docs or future performance reports, not in the API semantic contract
- If a `mutable` API has observable behavior due to a performance-oriented design choice, document that behavior explicitly rather than only describing the internal implementation
