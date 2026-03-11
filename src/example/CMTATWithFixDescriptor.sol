// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ==== CMTAT === */
import {CMTATBaseRuleEngine} from "CMTAT/contracts/modules/2_CMTATBaseRuleEngine.sol";
/* ==== FixEngine === */
import {FixDescriptorEngineModule} from "../FixDescriptorEngineModule.sol";
import {IFixDescriptorEngine} from "../engine/interfaces/IFixDescriptorEngine.sol";
import {FixDescriptorEngine} from "../engine/FixDescriptorEngine.sol";
/* ==== FixDescriptorKit === */
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

/**
 * @title CMTATWithFixDescriptor
 * @notice CMTAT token contract with integrated FIX descriptor support via FixDescriptorEngine
 * @dev Forwards IFixDescriptor calls to the bound FixDescriptorEngine
 */
contract CMTATWithFixDescriptor is CMTATBaseRuleEngine, FixDescriptorEngineModule, IFixDescriptor {
    /// @notice Role for managing descriptor writes through token helper functions.
    bytes32 public constant DESCRIPTOR_ADMIN_ROLE = keccak256("DESCRIPTOR_ADMIN_ROLE");
    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                        IFixDescriptor IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the complete FIX descriptor for this token
     * @return descriptor The FixDescriptor struct
     */
    function getFixDescriptor() external view override returns (IFixDescriptor.FixDescriptor memory descriptor) {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        return IFixDescriptor(engine).getFixDescriptor();
    }

    /**
     * @notice Get the Merkle root commitment for this token
     * @return root The fixRoot for verification
     */
    function getFixRoot() external view override returns (bytes32 root) {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        return IFixDescriptor(engine).getFixRoot();
    }

    /**
     * @notice Verify a specific field against the committed descriptor
     * @param pathCBOR CBOR-encoded bytes of the field path
     * @param value Raw FIX value bytes
     * @param proof Merkle proof (sibling hashes)
     * @param directions Direction array (true=right child, false=left child)
     * @return valid True if the proof is valid
     */
    function verifyField(
        bytes calldata pathCBOR,
        bytes calldata value,
        bytes32[] calldata proof,
        bool[] calldata directions
    ) external view override returns (bool valid) {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        return IFixDescriptor(engine).verifyField(pathCBOR, value, proof, directions);
    }

    /**
     * @notice Get SBE data chunk from SSTORE2 storage
     * @param start Start offset (in the data, not including STOP byte)
     * @param size Number of bytes to read
     * @return chunk The requested SBE data
     */
    function getFixSBEChunk(uint256 start, uint256 size) external view returns (bytes memory chunk) {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        return FixDescriptorEngine(engine).getFixSBEChunk(start, size);
    }

    /**
     * @notice Get the descriptor engine address
     * @return engine Address of the FixDescriptorEngine contract, or address(0) if not set
     */
    function getDescriptorEngine()
        external
        view
        override(FixDescriptorEngineModule, IFixDescriptor)
        returns (address engine)
    {
        return fixDescriptorEngine();
    }

    /**
     * @notice Authorize descriptor engine setting operation
     */
    function _authorizeSetDescriptorEngine() internal virtual override onlyRole(DESCRIPTOR_ENGINE_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                        ERC165 SUPPORT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return True if the contract implements the interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFixDescriptor).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Convenience function to set descriptor with SBE data via engine
     * @param sbeData Raw SBE-encoded data to deploy
     * @param descriptor Descriptor struct (fixSBEPtr and fixSBELen will be set automatically)
     * @return sbePtr Address of the deployed SBE data contract
     */
    function setDescriptorWithSBE(bytes memory sbeData, IFixDescriptor.FixDescriptor memory descriptor)
        external
        onlyRole(DESCRIPTOR_ADMIN_ROLE)
        returns (address sbePtr)
    {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        return FixDescriptorEngine(engine).setFixDescriptorWithSBE(sbeData, descriptor);
    }

    /**
     * @notice Convenience function to set descriptor via engine
     * @param descriptor The complete FixDescriptor struct (with fixSBEPtr already set)
     */
    function setDescriptor(IFixDescriptor.FixDescriptor calldata descriptor) external onlyRole(DESCRIPTOR_ADMIN_ROLE) {
        address engine = fixDescriptorEngine();
        require(engine != address(0), "CMTATWithFixDescriptor: Engine not set");
        FixDescriptorEngine(engine).setFixDescriptor(descriptor);
    }
}
