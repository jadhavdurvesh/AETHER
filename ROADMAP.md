# AETHER roadmap

## M0 — ELF inspection
- [x] NASM x86-64 executable and syscall I/O
- [x] ELF64 identity validation
- [x] ELF header version and minimum header-size validation
- [x] Reject program/section tables overlapping the ELF header
- [x] x86-64 machine validation
- [x] Entry point and ELF type display
- [x] Program header parsing and bounds checks
- [x] Section header parsing and bounds checks
- [x] Hexadecimal and decimal formatting
- [x] Smoke test and CI workflow

## M1 — ELF intelligence
- [ ] Section-name string table resolution
- [ ] Symbol table and dynamic symbol inspection
- [ ] Relocation table inspection
- [ ] PT_LOAD segment permission and overlap analysis
- [ ] Extended ELF numbering support
- [ ] Large-file streaming rather than fixed input buffer

## M2 — Instruction analysis
- [ ] x86-64 instruction decoder
- [ ] Linear disassembly of executable sections
- [ ] Symbol-aware disassembly
- [ ] Branch target annotation
- [ ] Basic control-flow graph generation

## M3 — Debugging
- [ ] ptrace attach and launch
- [ ] Register inspection
- [ ] Software breakpoints
- [ ] Single-step execution
- [ ] Memory and stack inspection
- [ ] Execution trace export

- [x] Handle short reads and enforce the 16 MiB input ceiling

- [x] Smoke test for files exceeding the 16 MiB input ceiling
