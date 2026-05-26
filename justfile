set shell := ["bash", "-cu"]

bench-target-dir := env_var_or_default("BENCH_TARGET_DIR", "/private/tmp/la-bench")

default:
  @just --list

bench-generate:
  python3 bench/generate_fixtures.py

bench:
  just bench-generate
  BENCH_FLAGS="--target-dir {{bench-target-dir}} ${BENCH_FLAGS:-}" python3 bench/run.py

bench-smoke:
  just bench-generate
  BENCH_FLAGS="--smoke --target-dir {{bench-target-dir}} ${BENCH_FLAGS:-}" python3 bench/run.py

bench-web:
  just bench-generate
  python3 bench/web/server.py

bench-clean:
  moon clean --target-dir "{{bench-target-dir}}"

bench-python-check:
  PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile bench/run.py bench/generate_fixtures.py bench/web/server.py
