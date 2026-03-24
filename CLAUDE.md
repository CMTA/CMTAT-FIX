# AGENTS/CLAUDE

- `CMTAT-FIX` adds on-chain FIX descriptor support to CMTAT tokens.
- Core pattern: a token-bound `FixDescriptorEngine` stores descriptor commitment data (`fixRoot`, SBE pointer/length) and verifies Merkle proofs.
- `CMTATWithFixDescriptor` forwards IFixDescriptor reads/writes to the configured engine.
- `CLAUDE.md` and `AGENTS.md`must always be identical

## Main code
- `src/engine/FixDescriptorEngine.sol`: role-gated engine, bound to one token.
- `src/engine/FixDescriptorEngineBase.sol`: descriptor storage + verification primitives.
- `src/engine/modules/FixDescriptorModule.sol`: FIX/SBE descriptor handling.
- `src/FixDescriptorEngineModule.sol`: token-side module holding engine address (ERC-7201 storage).
- `src/CMTAT/CMTATWithFixDescriptor.sol`: CMTAT integration contract.

## Tests and scripts
- `test/*.t.sol`: Foundry tests for engine/module/integration.
- `scripts/DeployCMTATWithFixDescriptor.s.sol`: deployment flow example.

## Toolchain
- Foundry project (`foundry.toml`)
- Solidity `0.8.34`, EVM `prague`
- Dependencies: `@fixdescriptorkit/contracts`, `@openzeppelin/contracts-upgradeable`, CMTAT submodule

## Common commands
```bash
npm install
forge test
forge build
forge script scripts/DeployCMTATWithFixDescriptor.s.sol:DeployCMTATWithFixDescriptor --rpc-url $RPC_URL --broadcast
```

## Notes
- Contracts are marked unaudited in `README.md`; treat changes as security-sensitive.
- Keep token/engine binding invariant: `engine.token() == address(token)`.
