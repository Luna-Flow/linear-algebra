# perf API

## Purpose

`Luna-Flow/linear-algebra/perf` is the entry package for `moon bench`. It has
no public items: its only content is a benchmark test that runs every
registered case of [`perf_support`](perf_support.md) through
`@bench.T::bench`.

Source: [`src/perf/perf_bench.mbt`](../../../src/perf/perf_bench.mbt). The
measurement method is in the [perf design](../design/perf.md).

## Importing

Nothing to import: the package is run with `moon bench -p perf`.

## Public items

None.

## Benchmarks

The package defines one benchmark test. For each case it prepares the inputs
once, outside the timed region, and registers a benchmark named
`<operation>/<case id>` whose body is one call of
`@support.run_prepared_case_once`, with the checksum passed to `b.keep` so that
the work cannot be optimized away.

```sh
moon bench -p perf --target native --release
```
