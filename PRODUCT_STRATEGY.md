# AETHER — Independent Product Strategy

## Product identity
AETHER is a binary-format inspection and executable-analysis toolkit. Its first implementation targets ELF64 on Linux x86-64; broader formats and architectures are explicit future extensions.

## Product boundary
- **Core:** bounded binary readers, format validation, ELF metadata parsing, diagnostics, and machine-readable reports.
- **Adapters:** additional binary formats, architecture-specific decoders, CI systems, and package metadata.
- **Applications:** CLI inspection, artifact validation, and analysis workflows.

The core must not depend on FireBot or treat FireBot firmware/package conventions as universal.

## Independent use cases
1. Validate Linux executable artifacts in CI before packaging.
2. Inspect compiler/linker output while learning or debugging binary layouts.
3. Audit executable metadata in software supply-chain workflows.

## Product requirements
- Strict bounds checking and malformed-input handling.
- Explicit supported-format/architecture matrix.
- Stable machine-readable output alongside human-readable CLI output.
- Streaming/large-file strategy rather than silently trusting fixed-size buffers.
- Negative fixtures and differential tests against trusted platform tools.
- Clear separation between static metadata inspection and claims about runtime safety.

## Non-goals
AETHER is not a debugger, disassembler, malware verdict engine, or proof that an executable is safe. Those capabilities require separate design and validation.

## FireBot adapter
An optional CI profile may validate Linux edge-computer artifacts. Microcontroller firmware formats remain out of scope until separately specified.

## Readiness gates
- [ ] Parser library/API separated from CLI presentation.
- [ ] Documented format and architecture support.
- [ ] Machine-readable output schema.
- [ ] Malformed corpus and differential tests.
- [ ] Two non-FireBot artifact-validation examples.
