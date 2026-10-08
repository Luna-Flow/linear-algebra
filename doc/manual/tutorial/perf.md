# perf tutorial

This page shows contributors how to benchmark the `@mutable` kernels with
`moon bench` and how to read the result. The method is in the
[perf design](../design/perf.md); the full pipeline is in `bench/README.md`.

| I want to | Use |
| --- | --- |
| benchmark every kernel | `moon bench -p perf --target native --release` |
| compare a kernel change | run the benchmark before and after |
| get a full report with statistics | `bench/run.py` |

## Quick start

```sh
moon bench -p perf --target native --release
```

Each line of the output is one case, named `<operation>/<case id>`, with the
time per call.

## Everyday tasks

### Compare a kernel change

1. Run the benchmark on the unchanged code and keep the output.
2. Apply the change, run again, and compare the same case names.
3. Check that the result bits did not change with the
   [perf_support tutorial](perf_support.md) checksum comparison, or that they
   changed only by rounding.

### Run the full report

```sh
just bench
```

This builds the benchmarks in release mode, runs them, and writes
`bench/results/summary.md` and `summary.json` with median, p90 and MAD per
case.

## Going further

Add the Rust `nalgebra` baseline with `BENCH_FLAGS="--include-rust" just bench`,
and open the local dashboard with `just bench-web`.

## Common pitfalls

- **Benchmarking debug builds.** Always pass `--release`.
- **Comparing runs from different machines.** Compare on one machine, under
  similar load.

## Next steps

- [perf_runner tutorial](perf_runner.md) for raw samples of one case.
- [perf_support API](../api/perf_support.md).
