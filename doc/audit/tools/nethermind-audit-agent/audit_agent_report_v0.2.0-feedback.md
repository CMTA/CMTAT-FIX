# Nethermind Audit Agent Feedback (v0.2.0)

Source report: [`audit_agent_report_v0.2.0.pdf`](./audit_agent_report_v0.2.0.pdf)

## Scope

- Repository: `CMTAT-FIX` (NethermindEth)
- Scan date: 2026-03-25
- Commit (report): `fddd0254…18f17542` (`main`)
- Findings: 3 (Low: 1, Info: 2)

## Finding-by-finding feedback

### 1) Initialization hook for engine binding is “dead code” (Low)

**Verdict:** Valid by design / documentation & tooling artifact; not a protocol defect.

`__fixDescriptorEngineModuleInitUnchained` is an **optional** hook for integrators who subclass the token and wire the engine inside their own `initialize()` chain. The shipped example `CMTATWithFixDescriptor` intentionally does **not** call it, matching the broader CMTAT pattern where optional engines are often linked **after** base initialization (same rationale as other CMTAT engine modules).

**Action taken / posture:**

- README documents the post-`initialize` `setFixDescriptorEngine` flow and the optional init hook.
- Slither may still flag the hook as unused when analyzing only the example contract; that reflects **library surface area**, not a missing call in core CMTAT.

**Integrator guidance:** Either call `setFixDescriptorEngine` after deployment, or override initialization and invoke `__fixDescriptorEngineModuleInitUnchained` if atomic binding is required.

---

### 2) Descriptor engine cannot be detached once set (Info)

**Verdict:** Acknowledged; documentation was misleading.

`setFixDescriptorEngine` rejects `address(0)` by design: once an engine is bound, the token may **replace** it with another bound engine but cannot return to an “unset” engine slot via this API.

**Action taken:**

- README “Design Principles” wording updated: **attach / replace**, not “detach,” to match the code.

**Operational note:** To stop using FIX descriptor features in practice, operators can replace the engine with a new `FixDescriptorEngine` under their control and leave descriptor data unused; a true “uninstall” would require a token upgrade or a different module design.

---

### 3) Stale SBE pointer contracts after `setFixDescriptorWithSBE` (Info)

**Verdict:** Acknowledged; inherent to the SSTORE2 pattern, not a security issue.

Each SBE update deploys a new bytecode contract for the payload; the descriptor’s `fixSBEPtr` moves to the new deployment. Older deployments remain on-chain and are not erased (post-Dencun `selfdestruct` constraints; SSTORE2 does not rely on destruction).

**Action taken:** None required in-contract. Off-chain systems should treat **`fixSBEPtr` / `fixSBELen` from the current descriptor** (and emitted events) as authoritative; older pointers are historical blobs unless explicitly tracked.
