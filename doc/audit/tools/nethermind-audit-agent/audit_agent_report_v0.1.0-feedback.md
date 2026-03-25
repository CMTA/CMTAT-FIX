# Nethermind Audit Agent Feedback (v0.1.0)

Source report: [`audit_agent_report_v0.1.0.pdf`](./audit_agent_report_v0.1.0.pdf)

## Scope

- Repo: `CMTAT-FIX`
- Report date: 2026-03-25
- Findings: 3 (Info: 1, Best Practices: 2)

## Finding-by-finding feedback

### 1) `__fixDescriptorEngineModuleInitUnchained` is never called (Info)

**Verdict:** Valid by design / acknowledged.

`CMTATWithFixDescriptor` intentionally does not bind the descriptor engine in `initialize()` by default. This matches the broader CMTAT deployment model where engines can be set post-initialization for standardized deployment flows.

Action taken:
- Documented this behavior in code comments (`FixDescriptorEngineModule`) and in `README.md` deployment guidance.
- Kept the current behavior unchanged.

### 2) Missing `FixDescriptorEngineSet` emission in module init hook (Best Practices)

**Verdict:** Accepted and fixed.

Action taken:
- Added `emit FixDescriptorEngineSet(engine_)` in `__fixDescriptorEngineModuleInitUnchained(...)` when `engine_ != address(0)`.
- Added a test assertion to verify the event is emitted during initializer-based binding.

### 3) Use of `this.token()` in auth hooks instead of immutable `TOKEN` (Best Practices)

**Verdict:** Accepted and fixed.

Action taken:
- Replaced `msg.sender == this.token()` with `msg.sender == TOKEN` in:
  - `_authorizeSetFixDescriptor()`
  - `_authorizeSetFixDescriptorWithSBE()`

This removes the unnecessary external self-call and keeps behavior equivalent.

## Notes

These changes preserve the token/engine binding invariant (`engine.token() == address(token)`) while improving observability and reducing avoidable gas overhead.
