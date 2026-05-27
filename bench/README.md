# Benchmarking

This benchmark documentation reflects the current repository state and stays
aligned with the current package baseline.

This repository ships a steady-state benchmark harness for comparing the
`mutable` package on the MoonBit native backend and, optionally, against a Rust
`nalgebra` public-API baseline with minimal local fallbacks for operations
without a direct one-call API.

A scheduled GitHub Actions workflow at `.github/workflows/benchmark.yml` runs
the benchmark matrix in CI and uploads the generated result artifacts.

## Fixtures

- `bench/datasets/manifest.json` lists the dataset version and case metadata.
- `bench/datasets/cases/*.json` stores per-case literal inputs and is
  regenerated on demand.
- `bench/generate_fixtures.py` regenerates the JSON fixtures plus compact
  metadata registries for MoonBit and Rust.

Only `manifest.json` is intended to stay reviewable in git. The per-case JSON
files and generated MoonBit files are codegen outputs and are ignored.

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
