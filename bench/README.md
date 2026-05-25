# Benchmarking

This repository ships a benchmark harness for comparing the `mutable` package
across MoonBit backends and, optionally, against a Rust `nalgebra` baseline.

## Fixtures

- `bench/datasets/manifest.json` lists the dataset version and case metadata.
- `bench/datasets/cases/*.json` stores per-case literal inputs and is
  regenerated on demand.
- `bench/generate_fixtures.py` regenerates both the JSON fixtures and the
  MoonBit registry files in `src/perf_support/generated_*.mbt`.

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

## Output

- `bench/results/summary.md`
- `bench/results/summary.json`
- `bench/results/raw/summary.json`
