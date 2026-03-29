# Changelog

All notable changes to this project are documented in this file.

## [0.2.0] - 2026-03-25

### Added
- Added `doc/audit/tools/nethermind-audit-agent/audit_agent_report_v0.1.0-feedback.md` with finding-by-finding feedback for the Nethermind Audit Agent report.
- `doc/audit/tools/nethermind-audit-agent/audit_agent_report_v0.2.0-feedback.md` for Nethermind Audit Agent report `audit_agent_report_v0.2.0.pdf` (commit `fddd025`).

### Changed
- Bumped engine version string from `0.1.0` to `0.2.0`.
- Documented intentional post-initialization engine linking flow (Finding 1 acknowledged as valid by design).
- Emit `FixDescriptorEngineSet` when engine is set via `__fixDescriptorEngineModuleInitUnchained(...)` to improve indexer/audit-trail completeness.
- Replaced `this.token()` with immutable `TOKEN` in engine authorization hooks to remove unnecessary external self-calls.
- README: Nethermind Audit Agent reports and feedback; clarified modular architecture wording (set/replace vs detach).

### Fixed
- Corrected `FixDescriptorEngineModule` ERC-7201 storage slot constant to match `keccak256(abi.encode(uint256(keccak256("CMTAT.storage.FixDescriptorEngineModule")) - 1)) & ~bytes32(uint256(0xff))` (the previous literal did not match the documented formula).

## [0.1.0] - 2026-03-25

### Added
- Initial release of CMTAT-FIX: on-chain FIX descriptor support for CMTAT tokens.
- `FixDescriptorEngine` architecture bound per token, with role-gated descriptor management and verification.
- Descriptor commitment flow with `fixRoot` storage, SBE pointer/length handling, and Merkle proof field verification.
- CMTAT integration via `FixDescriptorEngineModule` and `CMTATWithFixDescriptor` forwarding implementation.
- Foundry tests and deployment script for engine/module/integration coverage and deployment workflow.
