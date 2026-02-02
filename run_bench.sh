#!/bin/bash

# Get the target backend and group from arguments
TARGET=$1
GROUP=$2

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <backend_name> [group_name]"
    echo "Available backends: wasm, js, native, wasm-gc (or 'all' to run everything)"
    echo "Available groups: defined in bench/bench_groups.json (or 'all' to run everything)"
    exit 1
fi

# Define output filename
OUTPUT_FILE="bench/bench_${TARGET}.txt"

if [ "$TARGET" == "all" ]; then
    echo "🌟 Running benchmarks for ALL backends..."
    # Clear output files first
    for t in wasm wasm-gc js native; do
        > "bench/bench_${t}.txt"
    done
    
    for t in wasm wasm-gc js native; do
        SKIP_CLEANUP=1 $0 $t $GROUP
    done
    echo "🧹 Cleaning up and processing results..."
    cd bench
    python clean_up.py && python proc.py
    cd ..
    echo "🎉 All benchmarks completed."
    exit 0
fi

# Determine if we should use --release
RELEASE_FLAG=""
if [[ "$TARGET" == "wasm" || "$TARGET" == "native" || "$TARGET" == "js" || "$TARGET" == "wasm-gc" ]]; then
    RELEASE_FLAG="--release"
fi

# Handle groups
if [ -z "$GROUP" ] || [ "$GROUP" == "all" ]; then
    # Run all mbt files in src/benchmark that end with _test.mbt
    FILES=$(ls src/benchmark/*_test.mbt)
else
    # Extract files from bench_groups.json
    FILES=$(python3 -c "import json, sys; g=json.load(open('bench/bench_groups.json')); print(' '.join(['src/benchmark/'+f for f in g.get('$GROUP', [])]))" 2>/dev/null)
    if [ -z "$FILES" ]; then
        echo "❌ Group '$GROUP' not found in bench/bench_groups.json or files missing."
        exit 1
    fi
fi

if [ -z "$SKIP_CLEANUP" ]; then
    echo "🚀 Starting benchmark for [${TARGET}] group [${GROUP:-all}]..."
    # Clear the output file if we are running from scratch
    > "$OUTPUT_FILE"
fi

# Execute moon test for each file individually to ensure GC between blocks
for f in $FILES; do
    TEST_NAME=$(basename "$f" _test.mbt)
    echo "  - Running tests matching [$TEST_NAME] from $(basename $f)..."
    moon test src/benchmark --target "$TARGET" $RELEASE_FLAG -F "$TEST_NAME" >> "$OUTPUT_FILE" 2>&1
done

if [ $? -eq 0 ]; then
    echo "✅ Benchmark completed. Results saved to: $OUTPUT_FILE"
    if [ -z "$SKIP_CLEANUP" ]; then
        echo "🧹 Cleaning up and processing results..."
        cd bench
        python clean_up.py && python proc.py
        cd ..
    fi
else
    echo "❌ Benchmark failed for backend: $TARGET. Check $OUTPUT_FILE for details."
fi
