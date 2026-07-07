#!/usr/bin/env bash
set -euo pipefail

moon fmt
moon check
moon info
moon clean
moon coverage clean
moon test --enable-coverage
if moon coverage report -f summary > coverage_summary.txt 2>/dev/null; then
  moon coverage report -f html 2>/dev/null
else
  printf '%s\n' "coverage report generation failed with the current MoonBit toolchain" > coverage_summary.txt
  printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2
fi
