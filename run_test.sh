#!/usr/bin/env bash
set -euo pipefail

moon_test() {
  moon test "$@"
}

moon_test -p immut "$@"
moon_test -p consistency "$@"
moon_test -p perf_support "$@"
moon_test -p perf_runner "$@"
moon_test -p mutable --target wasm-gc "$@"
moon_test -p mutable --target js "$@"
moon_test -p mutable --target native "$@"
moon_test -p mutable --target wasm "$@"
