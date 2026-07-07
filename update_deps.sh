#!/usr/bin/env bash
set -euo pipefail

moon update
moon add --upgrade moonbitlang/x
moon add --upgrade Luna-Flow/arithmetic
moon add --upgrade Luna-Flow/luna-generic
moon add --upgrade moonbitlang/quickcheck
moon build
