#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/aether"
"$BIN" "$BIN" > "$ROOT/build/inspect.txt"
grep -q "ELF64 file:" "$ROOT/build/inspect.txt"
grep -q "PROGRAM HEADERS" "$ROOT/build/inspect.txt"
grep -q "SECTION TABLE" "$ROOT/build/inspect.txt"
if "$BIN" "$ROOT/README.md" > /dev/null 2>&1; then
  echo "expected non-ELF input to fail" >&2
  exit 1
fi
if "$BIN" > /dev/null 2>&1; then
  echo "expected missing argument to fail" >&2
  exit 1
fi
echo "AETHER smoke tests passed"
