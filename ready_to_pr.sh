#!/usr/bin/env bash
set -euo pipefail

moon fmt
moon check --target all
moon info
./run_test.sh
moon clean
moon coverage clean
moon test --enable-coverage
tmp_summary="$(mktemp)"
generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if moon coverage report -f summary > "$tmp_summary" 2>/dev/null; then
  {
    printf '%s\n' "# Coverage Summary"
    printf '\n'
    printf '%s\n' "- Generated at: $generated_at"
    printf '%s\n' "- Scope: default host-target coverage snapshot from \`moon test --enable-coverage\`."
    printf '%s\n' "- This file does not certify the multi-target \`wasm\`, \`wasm-gc\`, \`js\`, or \`native\` release matrix."
    printf '%s\n' "- Default release validation comes from \`moon check --target all\` and \`./run_test.sh\`."
    printf '%s\n' "- Toolchain:"
    moon version --all | sed 's/^/  /'
    printf '\n'
    cat "$tmp_summary"
  } > coverage_summary.txt
  moon coverage report -f html 2>/dev/null || true
else
  {
    printf '%s\n' "# Coverage Summary"
    printf '\n'
    printf '%s\n' "- Generated at: $generated_at"
    printf '%s\n' "- Scope: default host-target coverage snapshot from \`moon test --enable-coverage\`."
    printf '%s\n' "- This file does not certify the multi-target \`wasm\`, \`wasm-gc\`, \`js\`, or \`native\` release matrix."
    printf '%s\n' "- Default release validation comes from \`moon check --target all\` and \`./run_test.sh\`."
    printf '%s\n' "- Toolchain:"
    moon version --all | sed 's/^/  /'
    printf '\n'
    printf '%s\n' "coverage report generation failed with the current MoonBit toolchain"
  } > coverage_summary.txt
  printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2
fi
rm -f "$tmp_summary"
