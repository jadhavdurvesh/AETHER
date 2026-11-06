# AETHER design notes

## Platform contract

The initial implementation targets Linux x86-64, ELFCLASS64, little-endian binaries, and EM_X86_64. It uses direct Linux syscalls and NASM syntax. It does not depend on a C runtime.

## Input bounds

The input is capped at 16 MiB and stored in a static buffer. Before table iteration, the program checks the entry size, multiplication overflow, addition overflow, and end offset against the bytes read. The current implementation intentionally rejects malformed table extents instead of attempting recovery.

## ELF structures

The ELF64 header is 64 bytes. Program headers are expected to be at least 56 bytes and section headers at least 64 bytes. The program and section header loops advance using the entry sizes declared by the file.

## Current limitations

- ELF extended numbering is not implemented.
- Section names are not resolved yet; name offsets are printed.
- Symbol and relocation records are not decoded.
- The input buffer has a fixed 16 MiB ceiling.
- This is not yet a disassembler or debugger.
- The current table report is a raw numeric view, not a semantic security audit.

## Safety and correctness

AETHER does not execute the inspected file. It opens the input read-only and parses metadata. It should still be treated as an early-stage parser: use test fixtures and fuzzing before relying on it for untrusted binaries.
