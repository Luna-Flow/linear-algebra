# perf_runner design

## Design goal

`moon bench` reports summaries; the repository's report pipeline needs raw
per-sample timings of a single case, under its own control of repetition and
warm-up, and a way to replay a case and check its result. `perf_runner` is that
single-case tool.

## Constraints

- The report pipeline needs raw samples of one case per process, with
  control over repetition and warm-up.
- The executable may not depend on a serialization library.

## Design decisions

### Scratch copies outside the timer

For cases that mutate their inputs, `repeat` copies are prepared *before*
`monotonic_clock_start`, so copying is not measured and every call sees the
same input.

### Checksums in every mode

Each call's checksum is folded into a running value, so the work stays
observable and the diagnostic mode can verify bit-identical results.

### Plain JSON lines

The output is one JSON object per run, assembled by string concatenation, which
keeps the runner free of serialization dependencies and easy to parse from
Python.

## Mathematical background

A sample is the mean time of `repeat` consecutive calls,
$t = \tfrac1{\text{repeat}} \sum_{j=1}^{\text{repeat}} T_j$. Averaging inside a
sample reduces timer resolution error, which is fixed per measurement, by the
factor `repeat`, and reduces independent per-call noise by
$1/\sqrt{\text{repeat}}$. Across samples the pipeline uses order statistics
(median, p90) and the MAD, which are robust to outliers caused by scheduling.
Warm-up rounds discard the transient of the first calls (cache, branch
predictors, lazy initialization).

## Correctness and invariants

- In diagnostic mode, the printed checksum equals the FNV-style fold of the
  per-call checksums, which the package's whitebox tests verify.
- Copies made for scratch cases never alias the prepared inputs.

## Alternatives rejected

- **Timing each call separately.** Sub-microsecond calls are below the clock
  resolution; `repeat` amortizes it.

## Boundaries

The runner measures one case per process, computes no statistics itself and
supports only cases registered in `perf_support`.
