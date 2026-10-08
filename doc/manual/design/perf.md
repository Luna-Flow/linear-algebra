# perf design

## Design goal

`perf` lets the standard `moon bench` tool measure the steady-state cost of the
`@mutable` numerical kernels on every registered case, with no extra
infrastructure, so that a kernel change can be compared before and after.

## Mathematical background

`moon bench` repeats each benchmark body many times and reports statistics of
the per-iteration time. A steady-state measurement estimates the expected cost
$\mathbb{E}[T]$ of one call after warm-up, excluding process start, fixture
I/O and first-call effects. The repository's report scripts summarize samples
with robust statistics: the median, the nearest-rank 90th percentile, and the
median absolute deviation $\operatorname{MAD} = \operatorname{median}_i |t_i - \operatorname{median}(t)|$.
Unlike the mean and the standard deviation, the median and the MAD have a
breakdown point of 50%: a few samples disturbed by the operating system cannot
move them arbitrarily.

## Design decisions

### Preparation outside the timed region

Inputs are prepared once per case before registering the benchmark. Only the
kernel call and the checksum fold are inside the timed closure.

### Keep the checksum

Passing the checksum to `b.keep` makes the result observable, so the compiler
cannot eliminate the call, while costing only one 64-bit fold per output value.

### Not part of the default gate

Benchmarks depend on the machine and take long; they are excluded from
`run_test.sh` unless `LINEAR_ALGEBRA_TEST_BENCH=1` is set.

## Correctness and invariants

Every registered case is benchmarked exactly once per run, under a name that
identifies operation and case.

## Alternatives rejected

- **A hand-written timing loop.** `moon bench` already handles iteration
  counts and reporting; [`perf_runner`](perf_runner.md) covers the cases where
  raw samples are needed.

## Boundaries

`perf` does not compute or store statistics, does not compare against
baselines, and does not include cold-start timing.
