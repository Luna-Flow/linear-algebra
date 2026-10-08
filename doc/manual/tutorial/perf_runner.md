# perf_runner tutorial

This page shows contributors how to replay one benchmark case and collect raw
timing samples. The method is in the [perf_runner design](../design/perf_runner.md).

| I want to | Use |
| --- | --- |
| check that a change keeps results identical | diagnostic mode, `--samples 0` |
| collect raw timing samples | `--samples`, `--repeat`, `--warmup` |
| run a case on my own input | `--case-file` |

## Quick start

```sh
moon run src/perf_runner --target native mul_baseline_dense_64
```

The output is a diagnostic record with the case metadata and a checksum.

## Everyday tasks

### Check that a change keeps results identical

Run the diagnostic mode before and after the change and compare the
`checksum` fields. Equal checksums mean identical result bits.

### Collect timing samples

```sh
moon run src/perf_runner --target native det_baseline_shifted_16 --repeat 50 --warmup 3 --samples 20
```

This prints 20 samples, each the mean of 50 calls in nanoseconds, after three
untimed warm-up rounds.

### Use a custom fixture

```sh
moon run src/perf_runner --target native det_baseline_shifted_16 --case-file /tmp/my_case.json
```

The file must match the case's metadata and dataset version.

## Going further

`bench/run.py` drives the runner for every case and computes the median, p90
and MAD of the samples.

## Common pitfalls

- **`--repeat 0`.** Rejected; use a positive value.
- **Interpreting one sample.** Look at the median and spread of many samples.

## Next steps

- [perf_runner API](../api/perf_runner.md) for all arguments.
- [perf tutorial](perf.md) for `moon bench`.
