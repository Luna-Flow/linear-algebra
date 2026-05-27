# Benchmarking

This benchmark documentation reflects the current repository state and is
written for the upcoming `0.2.11` release line.

This repository ships a steady-state benchmark harness for comparing the
`mutable` package on the MoonBit native backend and, optionally, against a Rust
`nalgebra` public-API baseline with minimal local fallbacks for operations
without a direct one-call API.

The benchmark subsystem is split across three MoonBit packages:

- `src/perf`: the `moon bench` entry package.
- `src/perf_support`: public case metadata, runtime fixture loading, and case execution helpers.
- `src/perf_runner`: a single-case diagnostic and sampling runner used by the reporting pipeline.

Benchmark runs are intended for local execution and ad hoc comparison work
rather than a dedicated scheduled GitHub Actions workflow.

## Fixtures

- `bench/datasets/manifest.json` lists the dataset version and case metadata.
- `bench/datasets/cases/*.json` stores per-case literal inputs and is
  regenerated on demand.
- `bench/generate_fixtures.py` regenerates the JSON fixtures plus compact
  metadata registries for MoonBit and Rust.

Only `manifest.json` is intended to stay reviewable in git. The per-case JSON
files and generated MoonBit files are codegen outputs and are ignored.

## Why The Design Changed

- Runtime fixture loading keeps the benchmark binary small and isolates code-size effects from matrix payload size.
- Richer case metadata such as workload tier, structure, timing scope, input layout, mutation policy, size tier, and cost model lets the dashboard group performance changes by cause instead of only by operation name.
- Steady-state measurement intentionally excludes cold start so backend/kernel comparisons focus on repeated computation cost rather than process startup or fixture I/O.
- `scratch_per_sample` style mutation metadata exists because some operations mutate internal state and need per-sample fresh inputs to keep measurements comparable.

## Commands

Run a local smoke pass:

```bash
just bench-smoke
```

Run the full MoonBit matrix:

```bash
just bench
```

Include the optional Rust baseline:

```bash
BENCH_FLAGS="--include-rust" just bench
```

Launch the local benchmark dashboard:

```bash
just bench-web
```

Then open `http://127.0.0.1:8123`.

The benchmark runner now compiles only metadata into the MoonBit benchmark
binary. Matrix payloads stay in `bench/datasets/cases/*.json` and are loaded at
runtime by the native benchmark runner.

The benchmark runner builds MoonBit benchmarks with `moon bench --release` and
the Rust baseline with Cargo's `bench` profile inheriting `release`.
Use `just bench-clean` only when you explicitly want a cold rebuild.

## Output

- `bench/results/summary.md`
- `bench/results/summary.json`
- `bench/results/raw/summary.json`

`bench/results/summary.json` is the canonical benchmark exchange format. The
markdown summary and local web dashboard are derived from the same schema.

All reported rows are steady-state benchmark measurements. Cold-start timing is
not collected, stored, or rendered.

`src/perf_runner` remains available for single-case checksum diagnostics, but
its JSON payload is not part of the benchmark result schema.
