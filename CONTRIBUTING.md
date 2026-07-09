# Contribution Guidelines

This guide matches the current repository workflow and the same documentation
baseline as the rest of the repository: **`0.4.2`**.

## To Contributors

Contributions of all sizes are welcome. If you work on numerical methods,
scientific computing, compiler-facing performance work, documentation, or test
infrastructure, there is likely a useful way to help here. The project is also
a good place to learn: we try to keep the code, tests, and docs readable enough
for new contributors to trace behavior back to concrete examples.

Thank you for spending time on the repository. Code changes, documentation
improvements, review feedback, bug reports, and reproducible benchmarks all
move the project forward.

## Table of Contents

1. [Code Style](#1-code-style)
2. [Naming Conventions](#2-naming-conventions)
   2.1 [Variable Naming](#21-variable-naming)
   2.2 [Function Naming](#22-function-naming)
   2.3 [Struct and Trait Naming](#23-struct-and-trait-naming)
   2.4 [Constant Naming](#24-constant-naming)
   2.5 [Result Err Construction and Err Code](#25-result-err-construction-and-err-code)
3. [Comments](#3-comments)
4. [File Standards](#4-file-standards)
   4.1 [Folder Naming](#41-folder-naming)
   4.2 [File Organization](#42-file-organization)
5. [Commit Guidelines](#5-commit-guidelines)
   5.1 [Commit Messages](#51-commit-messages)
   5.2 [Commit Frequency](#52-commit-frequency)
6. [Code Review](#6-code-review)

## 1. Code Style

- The project follows the formatting style enforced by the MoonBit toolchain.
  Format your code with:

  ```bash
  moon fmt
  ```

  Run `moon fmt` before committing to keep formatting consistent.

  You can also use `ready_to_pr.sh` to format the code, run the default
  multi-target checks, regenerate `.mbti` files, and refresh the tracked
  host-target coverage snapshot in one pass.

- Prefer `using`-imported names over fully-qualified package calls when the imported names are used repeatedly in a file.

  Preferred:

  ```moonbit
  using @internal { ensure_square, ensure_mul_compatible, trait HasShape }
  ```

  Avoid repeated forms such as:

  ```moonbit
  @internal.ensure_square(self)
  @internal.ensure_mul_compatible(a, b)
  ```

- Avoid introducing new direct dependencies on `moonbitlang/core/immut/array` helpers when an equivalent `immut/vector`-level helper or local wrapper already exists. Prefer the project-level abstraction over the raw package helper.

## 2. Naming Conventions

### 2.1 Variable Naming

- Use **lowercase letters with underscores** as separators (e.g., `my_var`).
- Variable names should be descriptive and clearly indicate their purpose.

### 2.2 Function Naming

- Use **lowercase letters with underscores** as separators (e.g., `calc_total_price()`).
- Function names should be concise and descriptive, clearly expressing their functionality.

### 2.3 Struct and Trait Naming

- Use **PascalCase** (e.g., `MyStruct`, `MyTrait`).
- Names should intuitively reflect the function or role of the struct or trait, avoiding overly abstract or non-descriptive names.

### 2.4 Constant Naming

- **Note:** In the MoonBit context, "variables" are typically referred to as "bindings" and are immutable by default unless marked with `mut`. Thus, there is no strict distinction between constant and variable naming.
- Use **lowercase letters with underscores** as separators (e.g., `machine_dbl_epsilon`).
- Prefix constants with a descriptive category where applicable (e.g., `machine_dbl_epsilon`, where `machine` indicates a machine-related constant).
- Constant names should be concise and descriptive to facilitate understanding.

### 2.5 Result Err Construction and Err Code

- Use **uppercase letters with underscores** as separators (e.g., `E_MAX_ITER`).
- Err codes should be prefixed with `E` to indicate an error-related construct.
- Err codes should be concise and descriptive for easy comprehension.

## 3. Comments

- **Conciseness**: Comments should be clear and to the point, avoiding unnecessary verbosity.
- **Consistency**: Use uniform terminology and style across the codebase.
- **Clarity**: Ensure comments are easy to understand, avoiding complex jargon or ambiguous wording.
- **Accuracy**: Comments must accurately reflect the functionality and purpose of the code.
- **Up-to-date**: Comments should be updated alongside code changes to maintain relevance.

Developers are encouraged to use MoonBit LSP’s AI-generated code comments to improve efficiency, but AI-generated comments should be reviewed to ensure correctness.

## 4. File Standards

### 4.1 Folder Naming

- Use **lowercase letters** for folder names.
- Folder names should be concise, descriptive, and separated using underscores (`_`). Avoid numbers and special characters.

  Examples:

  - For differentiation-related functionality: `diff`
  - For derivative-related functionality: `deriv`

### 4.2 File Organization

- Files should be organized based on functionality, with each file focusing on a specific feature. Use **lowercase letters with underscores** for file names.
- File names should be descriptive and clearly indicate the core functionality they implement.

  Examples:

  - `gauss_kronrod.mbt`: Implements Gaussian quadrature with Kronrod extension.
  - `adaptive_quadrature_gk.mbt`: Implements adaptive quadrature using Gaussian quadrature with Kronrod extension.

- **Note:** Avoid overly generic or vague file names such as `utils.mbt`. Instead, ensure file names correspond to their function or module.

## 5. Commit Guidelines

### 5.1 Commit Messages

- Use the `ready_to_pr.sh` script before committing to format code, run the default multi-target checks, refresh the host-target coverage snapshot, and create `.mbti` files.
- Each commit should have a clear description of the changes made.
- Commit messages should be in **English**, concise, and precise.
- Use prefixes such as `fix:`, `feat:`, `refactor:`, and `docs:` to indicate the type of change.

  Examples:

  ```text
  fix: fix bug in something
  feat: add feature for something
  refactor: refactor something
  docs: add docs for something
  ```

### 5.2 Commit Frequency

- Keep commits small and focused on a single feature or fix.
- Avoid large, monolithic commits that include multiple unrelated changes.

## 5.3 Release Checklist

- Before publishing to mooncakes, make sure `moon.mod` has already been bumped to the intended unreleased version.
- Update `README.md` if the current package summary or release notes no longer match the repository state.
- Run `moon check --target all` and `./run_test.sh` locally before publishing.
- If the change touches benchmark fixtures, fixture recovery, or diagnostic runners, also run `LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh`.
- The GitHub Actions publish workflow reads the release version directly from `moon.mod`.
- If mooncakes reports a duplicate version, do not retry the same version. Bump the version first.

## 6. Code Review

- If you are not a maintainer or collaborator, contact them before modifying dependencies or version numbers in `moon.mod`.
- All code submissions must undergo **code review**.
- Code reviews should focus on code quality, style, performance, and security.
- Reviewers should provide constructive feedback to improve the code.
