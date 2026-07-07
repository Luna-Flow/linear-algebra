#!/usr/bin/env bash
set -euo pipefail

moon update
awk '
  $1 == "import" && $2 == "{" { in_import = 1; next }
  in_import && $1 == "}" { in_import = 0; next }
  in_import {
    gsub(/[",]/, "", $1)
    sub(/@.*/, "", $1)
    if ($1 != "") print $1
  }
' moon.mod | while IFS= read -r dep; do
  moon add --upgrade --no-update "$dep"
done
moon build
