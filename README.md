# CMTAT-FIX

Integration of FIX descriptor support for CMTAT (Capital Markets Technology Architecture Token) contracts. This repository provides a modular engine system that enables CMTAT tokens to store, manage, and verify FIX (Financial Information eXchange) protocol descriptors on-chain.

## Overview

CMTAT-FIX extends CMTAT tokens with FIX descriptor capabilities through a dedicated engine architecture. The system allows tokens to:

- Store FIX descriptor data using SBE (Simple Binary Encoding) format
- Commit to descriptor structures via Merkle roots
- Verify field values against committed descriptors using Merkle proofs
- Deploy descriptor data efficiently using SSTORE2 pattern

## Security Notice

⚠️ **WARNING**: The contracts in this repository are **unaudited** and should be used with caution. They have not undergone formal security audits. Use at your own risk.

## Architecture

The project follows CMTAT's modular engine pattern:

### Components

1. **FixDescriptorEngine** - Main engine contract bound to a single token
   - Manages descriptor storage and verification
   - Implements `IFixDescriptor` interface
   - Uses AccessControl for permission management

2. **FixDescriptorEngineBase** - Abstract base for engine mechanics
   - Exposes public/external API (`getFixDescriptor`, `setFixDescriptor`, etc.)
   - Delegates authorization to hook functions implemented by subclasses
   - Inherits `FixDescriptorModule` and `VersionModule`

3. **FixDescriptorEngineModule** - CMTAT module for token integration
   - Provides standard way to reference a FixDescriptorEngine
   - Uses ERC-7201 namespaced storage
   - Stores engine address in token contract

4. **FixDescriptorModule** - Core descriptor management logic
   - Handles SBE data deployment via SSTORE2
   - Manages descriptor storage and retrieval
   - Provides Merkle proof verification

5. **CMTATWithFixDescriptor** - Example token implementation
   - Demonstrates integration pattern
   - Forwards `IFixDescriptor` calls to bound engine
   - Provides convenience functions for descriptor management

### Design Principles

- **One Engine Per Token**: Each `FixDescriptorEngine` instance is bound to a single token at construction
- **Modular Architecture**: Engine can be attached/detached from tokens via module system
- **Gas Efficient**: Uses SSTORE2 for efficient on-chain data storage
- **Verifiable**: Merkle tree commitments enable cryptographic verification of descriptor fields

## Dependencies

- **CMTAT** [v3.2.0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0) - Core token framework
- **@fixdescriptorkit/contracts** ^1.0.2 - FIX descriptor library
- **@openzeppelin/contracts-upgradeable** [5.6.0](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/v5.6.0) - Upgradeable contracts

### Foundry configuration

See `foundry.toml`

- Solidity version: [0.8.34](https://www.soliditylang.org/blog/2026/02/18/solidity-0.8.34-release-announcement) 

- EVM version: `Prague`

## Installation

### Prerequisites

- Foundry (for development and testing)
- Node.js (for npm dependencies)

### Setup

1. Clone the repository with submodules:

```bash
git clone git@github.com:CMTA/CMTAT-FIX.git --recurse-submodules
cd CMTAT-FIX
```

2. Install npm dependencies:

```bash
npm install
```

3. Install Foundry dependencies:

```bash
forge install
```

## Architecture

### CMTATWithFixDescriptor

![surya_inheritance_CMTATWithFixDescriptor.sol](./doc/surya/surya_inheritance/surya_inheritance_CMTATWithFixDescriptor.sol.png)

#### Contracts Description Table


|          Contract          |             Type              |                            Bases                             |                |               |
| :------------------------: | :---------------------------: | :----------------------------------------------------------: | :------------: | :-----------: |
|             └              |       **Function Name**       |                        **Visibility**                        | **Mutability** | **Modifiers** |
|                            |                               |                                                              |                |               |
| **CMTATWithFixDescriptor** |        Implementation         | CMTATBaseRuleEngine, FixDescriptorEngineModule, IFixDescriptor |                |               |
|             └              |         <Constructor>         |                           Public ❗️                           |       🛑        |      NO❗️      |
|             └              |       getFixDescriptor        |                          External ❗️                          |                |      NO❗️      |
|             └              |          getFixRoot           |                          External ❗️                          |                |      NO❗️      |
|             └              |          verifyField          |                          External ❗️                          |                |      NO❗️      |
|             └              |        getFixSBEChunk         |                          External ❗️                          |                |      NO❗️      |
|             └              |      getDescriptorEngine      |                          External ❗️                          |                |      NO❗️      |
|             └              | _authorizeSetDescriptorEngine |                          Internal 🔒                          |       🛑        |   onlyRole    |
|             └              |       supportsInterface       |                           Public ❗️                           |                |      NO❗️      |
|             └              |     setDescriptorWithSBE      |                          External ❗️                          |       🛑        |   onlyRole    |
|             └              |         setDescriptor         |                          External ❗️                          |       🛑        |   onlyRole    |


##### Legend

| Symbol | Meaning                   |
| :----: | ------------------------- |
|   🛑    | Function can modify state |
|   💵    | Function is payable       |

### FixDescriptorEngine

![surya_inheritance_FixDescriptorEngine.sol](./doc/surya/surya_inheritance/surya_inheritance_FixDescriptorEngine.sol.png)

![surya_inheritance_FixDescriptorEngineBase.sol](./doc/surya/surya_inheritance/surya_inheritance_FixDescriptorEngineBase.sol.png)

See more in [./doc/surya](./doc/surya)

## API Reference

### FixDescriptorEngine

Main engine contract. One instance is bound to one token at construction time. Inherits `FixDescriptorEngineBase`, `AccessControl`.

#### State Variables

| Name | Type | Description |
|------|------|-------------|
| `token` | `address` (immutable) | Address of the token this engine is bound to |
| `DESCRIPTOR_ADMIN_ROLE` | `bytes32` (constant) | Role required to set/update descriptors |

#### Functions

| Function | Signature | Access | Description |
|----------|-----------|--------|-------------|
| `constructor` | `(address token_, address admin, bytes sbeData_, FixDescriptor descriptor_)` | — | Binds engine to `token_`, grants `DEFAULT_ADMIN_ROLE` to `admin`. Optionally initializes descriptor from `sbeData_` / `descriptor_`. |
| `hasRole` | `(bytes32 role, address account) → bool` | public view | Override: `DEFAULT_ADMIN_ROLE` holders implicitly hold all roles. |
| `getFixDescriptor` | `() → FixDescriptor` | external view | Returns the stored FIX descriptor struct. |
| `getFixRoot` | `() → bytes32` | external view | Returns the Merkle root commitment of the descriptor. |
| `verifyField` | `(bytes pathCBOR, bytes value, bytes32[] proof, bool[] directions) → bool` | external view | Verifies a single FIX field value against the committed Merkle root. |
| `getFixSBEChunk` | `(uint256 start, uint256 size) → bytes` | external view | Reads a chunk of SBE-encoded data from SSTORE2 storage. |
| `setFixDescriptor` | `(FixDescriptor descriptor)` | external | Sets/updates the descriptor. Requires `DESCRIPTOR_ADMIN_ROLE` or caller is the bound token. |
| `setFixDescriptorWithSBE` | `(bytes sbeData, FixDescriptor descriptor) → address sbePtr` | external | Deploys SBE data via SSTORE2 and atomically updates the descriptor. Returns the deployed data contract address. Requires `DESCRIPTOR_ADMIN_ROLE` or caller is the bound token. |
| `version` | `() → string` | external pure | Returns the version string (e.g. `"1.0.0"`). |

---

### FixDescriptorEngineModule

CMTAT module that stores a reference to a `FixDescriptorEngine` on the token contract. Uses ERC-7201 namespaced storage.

#### State Variables

| Name | Type | Description |
|------|------|-------------|
| `DESCRIPTOR_ENGINE_ROLE` | `bytes32` (constant) | Role required to set the engine address on the token |

#### Functions

| Function | Signature | Access | Description |
|----------|-----------|--------|-------------|
| `setFixDescriptorEngine` | `(address engine)` | external | Sets the engine address. Verifies the engine is bound to this token (`engine.token() == address(this)`). Authorization is implementation-defined via `_authorizeSetDescriptorEngine()`. |
| `getDescriptorEngine` | `() → address` | external view | Returns the stored engine address, or `address(0)` if not set. |
| `fixDescriptorEngine` | `() → address` | public view | Alias for `getDescriptorEngine`. Used internally by `CMTATWithFixDescriptor`. |

---

### CMTATWithFixDescriptor

Example token implementation combining `CMTATBaseRuleEngine` with `FixDescriptorEngineModule`. All `IFixDescriptor` calls are forwarded to the bound engine.

#### State Variables

| Name | Type | Description |
|------|------|-------------|
| `DESCRIPTOR_ADMIN_ROLE` | `bytes32` (constant) | Role required to call descriptor write helpers on the token |

#### Functions

| Function | Signature | Access | Description |
|----------|-----------|--------|-------------|
| `getFixDescriptor` | `() → FixDescriptor` | external view | Forwarded to `FixDescriptorEngine.getFixDescriptor()`. Reverts if engine is not set. |
| `getFixRoot` | `() → bytes32` | external view | Forwarded to `FixDescriptorEngine.getFixRoot()`. Reverts if engine is not set. |
| `verifyField` | `(bytes pathCBOR, bytes value, bytes32[] proof, bool[] directions) → bool` | external view | Forwarded to `FixDescriptorEngine.verifyField()`. Reverts if engine is not set. |
| `getFixSBEChunk` | `(uint256 start, uint256 size) → bytes` | external view | Forwarded to `FixDescriptorEngine.getFixSBEChunk()`. Reverts if engine is not set. |
| `getDescriptorEngine` | `() → address` | external view | Returns the engine address (overrides both `FixDescriptorEngineModule` and `IFixDescriptor`). |
| `setDescriptorWithSBE` | `(bytes sbeData, FixDescriptor descriptor) → address sbePtr` | external | Convenience helper: calls `engine.setFixDescriptorWithSBE()`. Requires `DESCRIPTOR_ADMIN_ROLE`. |
| `setDescriptor` | `(FixDescriptor descriptor)` | external | Convenience helper: calls `engine.setFixDescriptor()`. Requires `DESCRIPTOR_ADMIN_ROLE`. |
| `supportsInterface` | `(bytes4 interfaceId) → bool` | public view | ERC-165 support. Returns `true` for `IFixDescriptor` in addition to inherited interfaces. |

## Usage

### Basic Integration

#### 1. Deploy the Token

```solidity
CMTATWithFixDescriptor implementation = new CMTATWithFixDescriptor();
ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");
CMTATWithFixDescriptor token = CMTATWithFixDescriptor(address(proxy));
token.initialize(admin, erc20Attrs, extraInfo, engines);
```

#### 2. Deploy FixDescriptorEngine

**Option A: With Constructor Initialization**

```solidity
bytes memory sbeData = hex"...";
bytes32 merkleRoot = bytes32(...);
bytes32 schemaHash = keccak256("your-dictionary");

IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
    schemaHash: schemaHash,
    fixRoot: merkleRoot,
    fixSBEPtr: address(0),
    fixSBELen: 0,
    schemaURI: "ipfs://..."
});

FixDescriptorEngine engine = new FixDescriptorEngine(
    address(token),
    admin,
    sbeData,
    descriptor
);
```

**Option B: Post-Deployment Initialization**

```solidity
FixDescriptorEngine engine = new FixDescriptorEngine(
    address(token),
    admin,
    "",
    IFixDescriptor.FixDescriptor({
        schemaHash: bytes32(0),
        fixRoot: bytes32(0),
        fixSBEPtr: address(0),
        fixSBELen: 0,
        schemaURI: ""
    })
);

engine.setFixDescriptorWithSBE(sbeData, descriptor);
```

#### 3. Link Engine to Token

```solidity
// Caller must be authorized by token policy (typically DEFAULT_ADMIN_ROLE holder)
token.setFixDescriptorEngine(address(engine));
```

#### 4. Query Descriptor Information

```solidity
IFixDescriptor.FixDescriptor memory desc = token.getFixDescriptor();
bytes32 root = token.getFixRoot();
```

#### 5. Verify Field Values

```solidity
bytes calldata pathCBOR; // CBOR-encoded field path
bytes calldata value;   // Raw FIX value bytes
bytes32[] calldata proof; // Merkle proof
bool[] calldata directions; // Direction array

bool isValid = token.verifyField(pathCBOR, value, proof, directions);
```

### Advanced Usage

#### Updating Descriptors

```solidity
// Grant DESCRIPTOR_ADMIN_ROLE on engine
engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin);

// Update descriptor
IFixDescriptor.FixDescriptor memory newDescriptor = ...;
engine.setFixDescriptor(newDescriptor);

// Or deploy new SBE data and update
engine.setFixDescriptorWithSBE(newSbeData, newDescriptor);
```

#### Reading SBE Data

```solidity
// Read chunk of SBE data
bytes memory chunk = engine.getFixSBEChunk(startOffset, size);
```

## Project Structure

```
CMTAT-FIX/
├── src/
│   ├── FixDescriptorEngine.sol          # Main engine contract
│   ├── FixDescriptorEngineBase.sol       # Abstract base with public API and auth hooks
│   ├── FixDescriptorEngineModule.sol     # CMTAT module for integration
│   ├── interfaces/
│   │   └── IFixDescriptorEngine.sol      # Engine interface
│   ├── modules/
│   │   ├── FixDescriptorModule.sol       # Core descriptor logic
│   │   └── VersionModule.sol             # Version tracking
│   └── examples/
│       └── CMTATWithFixDescriptor.sol    # Example token implementation
├── lib/
│   └── CMTAT/                            # CMTAT submodule
├── test/
│   ├── CMTATWithFixDescriptor.t.sol      # Token integration tests
│   ├── FixDescriptorEngine.t.sol         # Engine unit tests
│   ├── FixDescriptorEngineBase.t.sol     # Engine base unit tests
│   └── FixDescriptorEngineModule.t.sol   # Module unit tests
├── scripts/
│   └── DeployCMTATWithFixDescriptor.s.sol # Deployment script
├── foundry.toml                          # Foundry configuration
└── package.json                          # npm dependencies
```

## Testing

Run the test suite using Foundry:

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/CMTATWithFixDescriptor.t.sol
```

## Deployment

Use the provided deployment script:

```bash
forge script scripts/DeployCMTATWithFixDescriptor.s.sol:DeployCMTATWithFixDescriptor \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

Set environment variables:
- `PRIVATE_KEY` - Deployer private key
- `ADMIN_ADDRESS` - Admin address for roles
- `TOKEN_ADDRESS` - Deployed token/proxy address to bind the engine to

## Access Control

### Roles

- **DESCRIPTOR_ADMIN_ROLE** (on engine): Can set/update descriptors
- **DESCRIPTOR_ENGINE_ROLE** (on token): Can set the engine address
- **DEFAULT_ADMIN_ROLE** (on engine): Has all roles

### Permission Flow

1. Token caller authorized by token policy sets engine address (`DESCRIPTOR_ENGINE_ROLE` path)
2. Engine writes are allowed for `DESCRIPTOR_ADMIN_ROLE` and the bound token caller
3. Default admin on engine has all permissions

## Interface Compliance

The system implements the `IFixDescriptor` interface from `@fixdescriptorkit/contracts`, providing:

- `getFixDescriptor()` - Retrieve complete descriptor
- `getFixRoot()` - Get Merkle root commitment
- `verifyField()` - Verify field values with Merkle proofs
- `getDescriptorEngine()` - Get engine address

## Security Considerations

- Engine is bound to token at construction (immutable)
- Descriptor updates are authorized for `DESCRIPTOR_ADMIN_ROLE` and the bound token caller
- Merkle proofs enable cryptographic verification without revealing full descriptor
- SSTORE2 pattern ensures efficient and secure data storage



### Tools

### Tools

#### Slither

Report performed with [Slither](https://github.com/crytic/slither):

```bash
slither .  --checklist --filter-paths "openzeppelin-contracts|test|CMTAT|forge-std|mocks" > slither-report.md
```

| File | Report | Feedback |
|------|--------|----------|
| [`slither-report.md`](doc/audit/tools/slither-report.md) | No findings captured | - |

#### Aderyn

Report performed with [Aderyn](https://github.com/Cyfrin/aderyn):

```bash
aderyn -x mocks --output aderyn-report.md
```

| File | Report | Feedback |
|------|--------|----------|
| [`aderyn-report.md`](doc/audit/tools/aderyn-report.md) | 2 High, 5 Low | [`aderyn-report-feedback.md`](doc/audit/tools/aderyn-report-feedback.md) |

**Finding summary:**

| ID | Title | Aderyn Severity | Verdict |
|----|-------|-----------------|---------|
| H-1 | Contract Name Reused in Different Files | High | False Positive |
| H-2 | Reentrancy: State change after external call | High | Low — CEI, require privileged caller. |
| L-1 | Centralization Risk | Low | Valid by Design / Acknowledge |
| L-2 | Unspecific Solidity Pragma | Low | Valid by Design / Acknowledge |
| L-3 | PUSH0 Opcode | Low | Conditional / N/A (Prague target) |
| L-4 | Empty Block | Low | False Positive |
| L-5 | Unchecked Return | Low | False Positive |



## License

Mozilla Public License 2.0 (MPL-2.0). See `LICENSE`.

## Contributing

Contributions are welcome! Please ensure:

- Code follows existing patterns and style
- Tests are added for new features
- Documentation is updated accordingly

## References

- [CMTAT Documentation](https://github.com/CMTA/CMTAT)
- [FIX Protocol](https://www.fixtrading.org/)
- [FixDescriptorKit](https://github.com/NethermindEth/fix-descriptor)
