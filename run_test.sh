#!/usr/bin/env bash
set -euo pipefail

moon_test() {
  moon test "$@"
}

moon_test -p immut "$@"
moon_test -p consistency "$@"

for target in wasm-gc js native wasm; do
  moon_test src/container --target "$target" "$@"
  moon_test src/container/adapters --target "$target" "$@"
  moon_test src/backends/default --target "$target" "$@"
  moon_test -p mutable --target "$target" "$@"
done

if [ "${LINEAR_ALGEBRA_TEST_BENCH:-0}" = "1" ]; then
  moon_test -p perf_support "$@"
  moon_test -p perf_runner "$@"
fi
