# Contribution Guidelines

<br>

## To Contributors

We warmly welcome developers familiar with various scientific computing libraries related to numerical calculus to join the project, contribute code, and share their valuable experiences. At the same time, we encourage beginners to learn and master numerical methods related to calculus by participating in development and improving documentation. In this project, we hope that both experienced developers and beginners can find contribution goals that interest them by reviewing the project's documentation, tables, and code examples.

We sincerely thank all the developers who have contributed to this project. Whether through submitting code, improving documentation, or providing valuable feedback, every effort you make helps to make this project better. Your enthusiasm and wisdom in the development process continually drive the project forward, and bring more opportunities for collaboration within the community. We appreciate your support and dedication, and we look forward to achieving more together, driving this project toward an even brighter future!

<br>

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

   4.3 [Generating .mbti Files](#43-generating-mbti-files)

5. [Commit Guidelines](#5-commit-guidelines)

   5.1 [Commit Messages](#51-commit-messages)

   5.2 [Commit Frequency](#52-commit-frequency)

6. [Code Review](#6-code-review)

<br>

## 1. Code Style
<br>

- The project follows the formatting style enforced by the MoonBit Toolchain. Format your code automatically using the following command:
  
  ```
  moon fmt
  ```
  
  Ensure that you run `moon fmt` before committing your code to maintain consistency.
  
  Alternatively, you can use the `ready_to_pr.sh` script to automatically format the code, run checks, generate test coverage files, and create `.mbti` files.

<br>

## 2. Naming Conventions
<br>

### 2.1 Variable Naming

- Use **lowercase letters with underscores** as separators (e.g., `my_var`).
- Variable names should be descriptive and clearly indicate their purpose.

<br>

### 2.2 Function Naming

- Use **lowercase letters with underscores** as separators (e.g., `calc_total_price()`).
- Function names should be concise and descriptive, clearly expressing their functionality.

<br>

### 2.3 Struct and Trait Naming

- Use **PascalCase** (e.g., `MyStruct`, `MyTrait`).
- Names should intuitively reflect the function or role of the struct or trait, avoiding overly abstract or non-descriptive names.

<br>

### 2.4 Constant Naming

- **Note:** In the MoonBit context, "variables" are typically referred to as "bindings" and are immutable by default unless marked with `mut`. Thus, there is no strict distinction between constant and variable naming.
- Use **lowercase letters with underscores** as separators (e.g., `machine_dbl_epsilon`).
- Prefix constants with a descriptive category where applicable (e.g., `machine_dbl_epsilon`, where `machine` indicates a machine-related constant).
- Constant names should be concise and descriptive to facilitate understanding.

<br>

### 2.5 Result Err Construction and Err Code

- Use **uppercase letters with underscores** as separators (e.g., `E_MAX_ITER`).
- Err codes should be prefixed with `E` to indicate an error-related construct.
- Err codes should be concise and descriptive for easy comprehension.

<br>

## 3. Comments
<br>

- **Conciseness**: Comments should be clear and to the point, avoiding unnecessary verbosity.
- **Consistency**: Use uniform terminology and style across the codebase.
- **Clarity**: Ensure comments are easy to understand, avoiding complex jargon or ambiguous wording.
- **Accuracy**: Comments must accurately reflect the functionality and purpose of the code.
- **Up-to-date**: Comments should be updated alongside code changes to maintain relevance.

Developers are encouraged to use MoonBit LSP’s AI-generated code comments to improve efficiency, but AI-generated comments should be reviewed to ensure correctness.

<br>

## 4. File Standards
<br>

### 4.1 Folder Naming

- Use **lowercase letters** for folder names.
- Folder names should be concise, descriptive, and separated using underscores (`_`). Avoid numbers and special characters.

  Examples:

  - For differentiation-related functionality: `diff`
  - For derivative-related functionality: `deriv`

<br>

### 4.2 File Organization

- Files should be organized based on functionality, with each file focusing on a specific feature. Use **lowercase letters with underscores** for file names.
- File names should be descriptive and clearly indicate the core functionality they implement.

  Examples:

  - `gauss_kronrod.mbt`: Implements Gaussian quadrature with Kronrod extension.
  - `adaptive_quadrature_gk.mbt`: Implements adaptive quadrature using Gaussian quadrature with Kronrod extension.

- **Note:** Avoid overly generic or vague file names such as `utils.mbt`. Instead, ensure file names correspond to their function or module.

<br>

## 5. Commit Guidelines
<br>

### 5.1 Commit Messages

- Use the `ready_to_pr.sh` script before committing to format code, run checks, generate test coverage files, and create `.mbti` files.
- Each commit should have a clear description of the changes made.
- Commit messages should be in **English**, concise, and precise.
- Use prefixes such as `fix:`, `feat:`, `refactor:`, and `doc:` to indicate the type of change.

  Examples:
  
  ```
  fix: fix bug in something
  feat: add feature for something
  refactor: refactor something
  doc: add docs for something
  ```

<br>

### 5.2 Commit Frequency

- Keep commits small and focused on a single feature or fix.
- Avoid large, monolithic commits that include multiple unrelated changes.

<br>

## 6. Code Review
<br>
- If you are not a maintainer or collaborator, contact them before modifying dependencies or version numbers in `moon.mod.json`.
- All code submissions must undergo **code review**.
- Code reviews should focus on code quality, style, performance, and security.
- Reviewers should provide constructive feedback to improve the code.

