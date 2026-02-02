#!/bin/bash

# Get the target backend from argument
# Get the target backend from argument
TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <backend_name>"
    echo "Available backends: wasm, js, native, wasm-gc (or 'all' to run everything)"
    exit 1
fi

if [ "$TARGET" == "all" ]; then
    echo "🌟 Running benchmarks for ALL backends..."
    for t in wasm wasm-gc js native; do
        $0 $t
    done
    echo "🧹 Cleaning up and processing results..."
    cd bench
    python clean_up.py && python proc.py
    cd ..
    echo "🎉 All benchmarks completed."
    exit 0
fi

# Determine if we should use --release (recommended for benchmarks)
RELEASE_FLAG=""
if [[ "$TARGET" == "wasm" || "$TARGET" == "native" || "$TARGET" == "js" || "$TARGET" == "wasm-gc" ]]; then
    RELEASE_FLAG="--release"
fi

# Define output filename
# Note: The user asked for "bench_backendname.txt"
OUTPUT_FILE="bench/bench_${TARGET}.txt"

echo "🚀 Starting benchmark for [${TARGET}] with flags [${RELEASE_FLAG}]..."

# Execute moon test from project root and redirect output
# We assume this script is either run from root or it handles paths correctly.
# To be safe, we use full path for output.
moon test src/benchmark --target "$TARGET" $RELEASE_FLAG > "$OUTPUT_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Benchmark completed. Results saved to: $OUTPUT_FILE"
else
    echo "❌ Benchmark failed for backend: $TARGET. Check $OUTPUT_FILE for details."
fi
