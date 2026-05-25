set shell := ["bash", "-cu"]

bench-target-dir := env_var_or_default("BENCH_TARGET_DIR", "/private/tmp/la-bench")

default:
  @just --list

bench-generate:
  python3 bench/generate_fixtures.py

bench:
  just bench-generate
  moon clean --target-dir "{{bench-target-dir}}"
  BENCH_FLAGS="--target-dir {{bench-target-dir}} ${BENCH_FLAGS:-}" python3 bench/run.py

bench-smoke:
  just bench-generate
  moon clean --target-dir "{{bench-target-dir}}"
  BENCH_FLAGS="--smoke --target-dir {{bench-target-dir}} ${BENCH_FLAGS:-}" python3 bench/run.py

bench-web:
  just bench-generate
  python3 bench/web/server.py

bench-python-check:
  PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile bench/run.py bench/generate_fixtures.py bench/web/server.py
