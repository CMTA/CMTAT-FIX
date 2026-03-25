# Changelog

All notable changes to this project are documented in this file.

## [0.1.0] - 2026-03-25

### Added
- Initial release of CMTAT-FIX: on-chain FIX descriptor support for CMTAT tokens.
- `FixDescriptorEngine` architecture bound per token, with role-gated descriptor management and verification.
- Descriptor commitment flow with `fixRoot` storage, SBE pointer/length handling, and Merkle proof field verification.
- CMTAT integration via `FixDescriptorEngineModule` and `CMTATWithFixDescriptor` forwarding implementation.
- Foundry tests and deployment script for engine/module/integration coverage and deployment workflow.
