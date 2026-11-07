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

# Reject a file that exceeds the documented 16 MiB input ceiling.
oversized="$ROOT/build/oversized.bin"
truncate -s 16777217 "$oversized"
if "$BIN" "$oversized" > "$ROOT/build/oversized.txt" 2>&1; then
  echo "expected oversized input to fail" >&2
  exit 1
fi
grep -q "exceeds 16 MiB limit" "$ROOT/build/oversized.txt"

# Corrupt e_phoff to an out-of-file offset; the parser must reject table bounds.
bad_ph="$ROOT/build/bad-phoff.elf"
cp "$BIN" "$bad_ph"
printf '\\377\\377\\377\\377\\377\\377\\377\\177' | dd of="$bad_ph" bs=1 seek=32 conv=notrunc status=none
if "$BIN" "$bad_ph" > "$ROOT/build/bad-phoff.txt" 2>&1; then
  echo "expected malformed program-header bounds to fail" >&2
  exit 1
fi
grep -q "malformed ELF table bounds" "$ROOT/build/bad-phoff.txt"

# Corrupt e_shoff similarly, retaining the valid program-header table.
bad_sh="$ROOT/build/bad-shoff.elf"
cp "$BIN" "$bad_sh"
printf '\\377\\377\\377\\377\\377\\377\\377\\177' | dd of="$bad_sh" bs=1 seek=40 conv=notrunc status=none
if "$BIN" "$bad_sh" > "$ROOT/build/bad-shoff.txt" 2>&1; then
  echo "expected malformed section-header bounds to fail" >&2
  exit 1
fi
grep -q "malformed ELF table bounds" "$ROOT/build/bad-shoff.txt"

# Reject a section-name string table index outside the section table.
bad_names="$ROOT/build/bad-shstrndx.elf"
cp "$BIN" "$bad_names"
printf '\\377\\377' | dd of="$bad_names" bs=1 seek=62 conv=notrunc status=none
if "$BIN" "$bad_names" > "$ROOT/build/bad-shstrndx.txt" 2>&1; then
  echo "expected invalid section-name table index to fail" >&2
  exit 1
fi
grep -q "malformed ELF table bounds" "$ROOT/build/bad-shstrndx.txt"
echo "AETHER smoke tests passed"
