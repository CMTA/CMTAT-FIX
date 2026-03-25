// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

/* ==== OpenZeppelin === */
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
/* ==== FixEngine === */
import {IFixDescriptorEngine} from "./engine/interfaces/IFixDescriptorEngine.sol";

/**
 * @title FixDescriptorEngineModule
 * @notice CMTAT module for integrating FixDescriptorEngine with CMTAT tokens
 * @dev Uses ERC-7201 namespaced storage to avoid conflicts
 */
abstract contract FixDescriptorEngineModule is Initializable {
    /* ============ ERC-7201 ============ */
    // keccak256(abi.encode(uint256(keccak256("CMTAT.storage.FixDescriptorEngineModule")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FIX_DESCRIPTOR_ENGINE_MODULE_STORAGE_LOCATION =
        0xc09aa28957960c2b82e3fad477567fe122f23bca69560181151331ec7041c600;

    /* ==== ERC-7201 State Variables === */
    struct FixDescriptorEngineModuleStorage {
        address _fixDescriptorEngine;
    }

    /// @notice Role for setting descriptor engine
    bytes32 public constant DESCRIPTOR_ENGINE_ROLE = keccak256("DESCRIPTOR_ENGINE_ROLE");

    /// @notice Emitted when descriptor engine is set
    event FixDescriptorEngineSet(address indexed engine);

    /**
     * @notice Initialize the FixDescriptorEngineModule
     * @dev Optional internal hook for integrators who want to bind an engine during token initialization.
     *      Default deployment flow can leave this unset and call `setFixDescriptorEngine` later.
     * @param engine_ Address of the FixDescriptorEngine contract (can be address(0))
     */
    function __fixDescriptorEngineModuleInitUnchained(address engine_) internal virtual onlyInitializing {
        if (engine_ != address(0)) {
            FixDescriptorEngineModuleStorage storage $ = _getFixDescriptorEngineModuleStorage();
            $._fixDescriptorEngine = engine_;
            require(
                IFixDescriptorEngine(engine_).token() == address(this),
                "FixDescriptorEngineModule: Engine not bound to this CMTAT"
            );
            emit FixDescriptorEngineSet(engine_);
        }
    }

    /**
     * @notice Set the FIX descriptor engine address
     * @param engine Address of the FixDescriptorEngine contract
     */
    function setFixDescriptorEngine(address engine) external virtual {
        _authorizeSetDescriptorEngine();
        FixDescriptorEngineModuleStorage storage $ = _getFixDescriptorEngineModuleStorage();
        require($._fixDescriptorEngine != engine, "FixDescriptorEngineModule: Same engine");
        require(engine != address(0), "FixDescriptorEngineModule: Invalid engine address");
        $._fixDescriptorEngine = engine;
        require(
            IFixDescriptorEngine(engine).token() == address(this),
            "FixDescriptorEngineModule: Engine not bound to this CMTAT"
        );
        emit FixDescriptorEngineSet(engine);
    }

    /**
     * @notice Authorize descriptor engine setting operation
     */
    function _authorizeSetDescriptorEngine() internal virtual;

    /**
     * @notice Get the descriptor engine address
     * @return engine Address of the FixDescriptorEngine contract, or address(0) if not set
     */
    function getDescriptorEngine() external view virtual returns (address engine) {
        FixDescriptorEngineModuleStorage storage $ = _getFixDescriptorEngineModuleStorage();
        return $._fixDescriptorEngine;
    }

    /**
     * @notice Get the FIX descriptor engine address
     * @return engine Address of the FixDescriptorEngine contract, or address(0) if not set
     */
    function fixDescriptorEngine() public view returns (address engine) {
        FixDescriptorEngineModuleStorage storage $ = _getFixDescriptorEngineModuleStorage();
        return $._fixDescriptorEngine;
    }

    /* ============ ERC-7201 ============ */
    function _getFixDescriptorEngineModuleStorage() private pure returns (FixDescriptorEngineModuleStorage storage $) {
        assembly {
            $.slot := FIX_DESCRIPTOR_ENGINE_MODULE_STORAGE_LOCATION
        }
    }
}
