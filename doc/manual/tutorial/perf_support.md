# perf_support tutorial

This page shows contributors how to list benchmark cases, run one case and
check its result from MoonBit code, for example when investigating a kernel
change. The method is described in the [perf_support design](../design/perf_support.md)
and in `bench/README.md`.

| I want to | Use |
| --- | --- |
| list the benchmark cases | `@support.case_names` |
| run one case and get a checksum | `@support.run_case_once`, or `prepare_case` and `run_prepared_case_once` |
| regenerate a fixture | delete it; the loader rebuilds it from the seed |

## Quick start

`perf_support` is used inside this repository. Its tests run with:

```sh
LINEAR_ALGEBRA_TEST_BENCH=1 ./run_test.sh
```

or directly:

```sh
moon test -p perf_support --target native
```

## Everyday tasks

### List the cases

```moonbit nocheck
for name in @support.sample_case_names() {
  println(name)
}
```

`case_names()` lists all registered cases.

### Run one case and compare checksums

```moonbit nocheck
let prepared = @support.find_prepared_case("chol_baseline_spd_64").unwrap()
let before = @support.run_prepared_case_once(prepared)
// ... change a kernel, rebuild ...
let after = @support.run_prepared_case_once(prepared)
assert_eq(before, after) // the result bits did not change
```

Equal checksums mean the result is bit-for-bit unchanged; different checksums
after a kernel change are expected when the summation order changed, and then
the results must be compared numerically.

### Regenerate fixtures

Delete `bench/datasets/cases/<id>.json` or run
`python3 bench/generate_fixtures.py`; the next run recreates the inputs from
the registry.

## Going further

To add an operation, add cases to the manifest, regenerate the registry with
`bench/generate_fixtures.py`, and extend the `match` in
`run_prepared_case_inplace`.

## Common pitfalls

- **Running on non-native targets.** Fixture loading needs file-system access.
- **Editing `generated_registry.mbt` by hand.** It is generated; change the
  manifest and regenerate.
- **Comparing checksums across targets.** Kernels differ per target, so result
  bits may differ.

## Next steps

- [perf_support API](../api/perf_support.md).
- [perf_runner tutorial](perf_runner.md) for timed runs.
- [mutable design](../design/mutable.md) for the measured algorithms.
