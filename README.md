# AETHER

**A low-level x86-64 ELF inspection toolkit written in NASM assembly.**

AETHER is a Linux command-line utility that inspects native ELF64 binaries directly from assembly. It validates the ELF identity and machine type, checks table bounds before dereferencing offsets, and reports executable metadata plus program and section header records.

## Current capabilities

- Linux x86-64 syscall-only executable (no libc dependency)
- ELF magic, class, byte order, version, and machine validation
- ELF type and entry point inspection
- Program-header and section-header table bounds validation
- Program header fields: type, flags, file offset, virtual address, file size, memory size
- Section header fields: name offset, type, flags, address, offset, size
- Fixed-width hexadecimal and decimal formatting
- NASM + GNU ld build
- Smoke tests and GitHub Actions workflow

## Requirements

- Linux x86-64
- NASM
- GNU binutils (ld, make)

## Build

    make

Run against an ELF64 executable:

    ./build/aether ./build/aether

Run smoke tests:

    make test

## Design

AETHER uses Linux x86-64 system calls directly. It reads a bounded input file into a static buffer, validates the ELF header and table extents, then walks the program and section header tables using their declared entry sizes.

The current implementation supports little-endian ELF64 for the x86-64 machine architecture. Input files are limited to 16 MiB. It is an inspection utility, not a debugger or disassembler yet.

See ROADMAP.md and docs/design.md.

## License

MIT.

Smoke tests include malformed program-header and section-header offsets, in addition to non-ELF and oversized-input rejection.

The inspector also rejects a non-undefined section-name string-table index that falls outside the declared section-header table. Section-name resolution and symbol/relocation inspection remain future work.
