# perf_support API

## Purpose

`Luna-Flow/linear-algebra/perf_support` is the shared library of the benchmark
subsystem. It holds the registry of benchmark cases, loads or regenerates
their input fixtures, prepares `@mutable` inputs, and runs one case, returning
a checksum of the result. [`perf`](perf.md) and [`perf_runner`](perf_runner.md)
are built on it.

Source: [`src/perf_support`](../../../src/perf_support/perf_support.mbt). The
benchmark method is described in the [perf_support design](../design/perf_support.md)
and in `bench/README.md`.

> [!NOTE]
> This package is tooling for this repository. Its API is public so that the
> runner and the bench package can share it; it is not a stable interface for
> other libraries. It needs file-system access (`moonbitlang/x/fs`) and is
> meant for the `native` target.

## Importing

Inside this repository, import it in `moon.pkg`:

```moonbit nocheck
///|
import {
  "Luna-Flow/linear-algebra/perf_support" @support,
}
```

The examples on this page write every name with the `@support.` prefix.

## Types

### `Case`

`Case` is the metadata of one benchmark case.

```mbti
pub struct Case {
  id : String
  operation : String
  family : String
  workload_tier : String
  structure : String
  timing_scope : String
  input_layout : String
  mutation_policy : String
  size_tier : String
  cost_model : String
  rows : Int
  cols : Int
  rhs_cols : Int
}
```

`operation` is one of `mul`, `mul_vec`, `determinant`, `inverse`, `rank`,
`reduce_row_elimination`, `cholesky_decomposition`, `eigen`, `power_method`.
The other string fields classify the workload (for example
`structure = "dense"`, `mutation_policy = "reusable_input"` or
`"scratch_per_sample"`) so that reports can group results by cause.

### `PreparedCase`

`PreparedCase` is a case with its inputs loaded into `@mutable` values.

```mbti
pub struct PreparedCase {
  case_item : Case
  matrix_a : @mutable.Matrix[Double]
  matrix_b : @mutable.Matrix[Double]
  vector_b : @mutable.Vector[Double]
}
```

## Registry

### `cases`

`cases` is the list of all registered cases, generated from
`bench/datasets/manifest.json`.

```mbti
pub let cases : Array[Case]
```

### `dataset_version`

`dataset_version` names the fixture format; fixture files with another
version are rejected.

```mbti
pub let dataset_version : String
```

### `case_names`, `sample_case_names`

`case_names()` returns every case id; `sample_case_names()` returns one
representative baseline case per operation, preferring medium sizes.

```mbti
pub fn case_names() -> Array[String]
pub fn sample_case_names() -> Array[String]
```

### `find_case`, `find_prepared_case`

Look up a case by id, optionally preparing its inputs.

```mbti
pub fn find_case(String) -> Case?
pub fn find_prepared_case(String) -> PreparedCase?
```

## Preparation

### `prepare_case`, `prepare_case_from_fixture`

`prepare_case(c)` loads `bench/datasets/cases/<id>.json`;
`prepare_case_from_fixture(c, path)` loads the given file.

```mbti
pub fn prepare_case(Case) -> PreparedCase
pub fn prepare_case_from_fixture(Case, String) -> PreparedCase
```

A missing fixture file is regenerated deterministically from the case's seed
and written to the path. A fixture whose version, id, metadata or shape does
not match the case aborts the program.

### `clone_prepared_case`

`clone_prepared_case(p)` deep-copies the inputs, for cases that mutate them.

```mbti
pub fn clone_prepared_case(PreparedCase) -> PreparedCase
```

## Execution

### `run_prepared_case_inplace`

`run_prepared_case_inplace(p, scratch)` runs the case's operation once and
returns a checksum of its result. With `scratch = true` it first copies the
inputs.

```mbti
pub fn run_prepared_case_inplace(PreparedCase, Bool) -> UInt64
```

The operations call the unchecked `@mutable` methods (`unchecked_matmul`,
`unchecked_determinant`, ...); `power_method` runs with 80 iterations.
`None` results map to fixed sentinel checksums.

### `run_prepared_case_once`, `run_case_once`

`run_prepared_case_once(p)` uses the case's own mutation policy to choose
`scratch`; `run_case_once(c)` prepares from the default fixture path and runs.

```mbti
pub fn run_prepared_case_once(PreparedCase) -> UInt64
pub fn run_case_once(Case) -> UInt64
```

### `case_diagnostic_payload`

`case_diagnostic_payload(c, checksum)` renders a one-line JSON record with the
case metadata and the checksum, used by the reporting scripts.

```mbti
pub fn case_diagnostic_payload(Case, UInt64) -> String
```

## Example

```moonbit nocheck
let c = @perf_support.find_case("mul_baseline_dense_64").unwrap()
let checksum = @perf_support.run_case_once(c)
println(@perf_support.case_diagnostic_payload(c, checksum))
```
