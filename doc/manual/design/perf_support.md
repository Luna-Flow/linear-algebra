# perf_support design

## Design goal

Benchmarks of numerical kernels are only useful if they are reproducible and
comparable: the same inputs on every run and every machine, measurements of
the computation rather than of setup, and a guarantee that the measured code
actually ran. `perf_support` provides those guarantees for the benchmark
subsystem of this repository.

## Constraints

- Inputs must be identical on every run and machine, without storing large
  arrays in the repository's source code.
- The measured work must stay observable, so that the compiler cannot remove
  it.
- The package serves only this repository's benchmark tools and the `native`
  target.

## Design decisions

### Fixtures at runtime, registry in code

The case list is generated into MoonBit code (`generated_registry.mbt`) from
`bench/datasets/manifest.json`, while the large input arrays live in JSON files
that are loaded at runtime. This keeps the benchmark binary small, so that code
size does not distort the measurements, and lets the Rust baseline consume the
same fixtures.

### Self-healing fixtures

When a fixture file is missing, it is regenerated from the registry seed and
written out, so a clean checkout can run any case. When a file exists but its
version, metadata or shape disagrees with the registry, the run aborts: a
silently mismatched input would make the numbers meaningless.

### Mutation policy

Some operations change their input (for example `reduce_row_elimination`).
Cases with `mutation_policy = "scratch_per_sample"` therefore run on fresh
copies, so every sample measures the same work.

### Unchecked kernels

The benchmarks call the `unchecked_*` methods, because the inputs are known to
satisfy the preconditions and the cost of validation is not what is being
measured.

## Mathematical background

### Deterministic inputs

Inputs are generated from a per-case seed with the SplitMix64 generator and
mapped to a target distribution (for example uniform on $[-0.9, 0.9]$, from
the top 53 bits of each 64-bit draw). Structured
families are built from such draws by construction, for example a symmetric
positive definite matrix as $M^{\mathsf T} M + \alpha I$, which is SPD for any
$\alpha > 0$ because $x^{\mathsf T}(M^{\mathsf T}M + \alpha I)x = \lVert Mx \rVert^2 + \alpha\lVert x\rVert^2 > 0$
for $x \ne 0$. The same seed always gives the same bits, so a fixture can be
regenerated instead of stored.

### Checksums

Each run folds the bit patterns of its result into a 64-bit value with an
FNV-style mix,

$$
h_0 = 1469598103934665603, \qquad
h_{k+1} = (h_k \oplus w_k) \cdot 1099511628211 \bmod 2^{64},
$$

where $w_k$ is the IEEE bit pattern of the $k$-th output value (shape first for
matrices). The checksum serves two purposes: it keeps the compiler from
removing the computation as dead code, and it detects a change of result bits
between runs, targets or versions. It is not a cryptographic hash.

## Correctness and invariants

- For a fixed dataset version, `prepare_case(c)` yields bit-identical inputs on
  every run.
- `run_prepared_case_inplace(p, true)` leaves `p` unchanged.
- The checksum depends on every output value and on the output shape.

## Alternatives rejected

- **Embedding all inputs in code.** Large literal arrays inflate the binary and
  compile time.
- **Random inputs per run.** Results would not be comparable across runs.

## Boundaries

`perf_support` measures nothing itself; timing and statistics are in
[`perf_runner`](perf_runner.md), [`perf`](perf.md) and `bench/run.py`. It
covers only the `@mutable` package with `Double` inputs, and it is not part of
the default test gate.
