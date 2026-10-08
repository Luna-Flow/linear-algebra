# perf_runner API

## Purpose

`Luna-Flow/linear-algebra/perf_runner` is an executable that runs one
benchmark case and prints a JSON record: either a diagnostic checksum or a list
of timing samples. It has no public library items.

Source: [`src/perf_runner/main.mbt`](../../../src/perf_runner/main.mbt). The
measurement method is in the [perf_runner design](../design/perf_runner.md).

## Importing

Nothing to import: the package is an executable, run with `moon run src/perf_runner`.

## Public items

None; the package is `pkgtype(kind: "executable")`.

## Command line

```sh
moon run src/perf_runner --target native <case-id> [--case-file <path>] [--repeat <n>] [--samples <n>] [--warmup <n>]
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `<case-id>` | required | a case id registered in [`perf_support`](perf_support.md) |
| `--case-file <path>` | `bench/datasets/cases/<case-id>.json` | fixture file; regenerated if missing |
| `--repeat <n>` | `1` | calls per timed sample, $n > 0$ |
| `--samples <n>` | `0` | number of timed samples; `0` selects diagnostic mode |
| `--warmup <n>` | `0` | untimed warm-up rounds before sampling |

Invalid or missing arguments abort with a usage message.

## Output

**Diagnostic mode** (`--samples 0`) runs the case `repeat` times and prints
`case_diagnostic_payload`: `{"kind":"diagnostic", ..., "checksum":"<u64>"}`.
The checksum of `repeat` runs is the fold of the individual checksums.

**Sampling mode** prints
`{"kind":"benchmark", ..., "repeat":<n>, "samples":[t1, t2, ...]}` where each
$t_i$ is the elapsed wall-clock time of one sample divided by `repeat`, in
nanoseconds.

For cases with `mutation_policy = "scratch_per_sample"`, the inputs are copied
for each call before the timer starts.
