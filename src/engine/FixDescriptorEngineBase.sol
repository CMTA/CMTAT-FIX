// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IFixDescriptorEngine.sol";
import "./modules/FixDescriptorModule.sol";
import "./modules/VersionModule.sol";

/**
 * @title FixDescriptorEngineBase
 * @notice Base contract for FIX descriptor mechanics with hook-based authorization.
 * @dev Concrete engines implement authorization hooks to enforce write policy.
 */
abstract contract FixDescriptorEngineBase is IFixDescriptorEngine, FixDescriptorModule, VersionModule {
    /// @notice The token this engine is bound to.
    address internal immutable TOKEN;

    /**
     * @notice Constructor
     * @param token_ Address of the token contract this engine will manage
     * @param sbeData_ Optional SBE-encoded data to deploy and initialize descriptor
     * @param descriptor_ Optional descriptor struct to initialize
     */
    constructor(address token_, bytes memory sbeData_, IFixDescriptor.FixDescriptor memory descriptor_) {
        require(token_ != address(0), "FixDescriptorEngine: Invalid token address");
        TOKEN = token_;

        if (sbeData_.length > 0 && descriptor_.fixRoot != bytes32(0)) {
            _initializeDescriptorFromConstructor(sbeData_, descriptor_);
        } else if (descriptor_.fixRoot != bytes32(0)) {
            _initializeDescriptorFromConstructor("", descriptor_);
        }
    }

    /**
     * @notice Get the complete FIX descriptor for the bound token
     * @return descriptor The FixDescriptor struct
     */
    function getFixDescriptor() external view returns (IFixDescriptor.FixDescriptor memory descriptor) {
        return _getDescriptor();
    }

    /**
     * @notice Get the Merkle root commitment for the bound token
     * @return root The fixRoot for verification
     */
    function getFixRoot() external view returns (bytes32 root) {
        IFixDescriptor.FixDescriptor memory descriptor = _getDescriptor();
        return descriptor.fixRoot;
    }

    /**
     * @notice Returns the address of the token this engine is bound to
     * @return The address of the token this engine is bound to
     */
    function token() external view returns (address) {
        return TOKEN;
    }

    /**
     * @notice Verify a specific field against the committed descriptor for the bound token
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
    ) external view returns (bool valid) {
        return _verifyField(pathCBOR, value, proof, directions);
    }

    /**
     * @notice Get SBE data chunk from SSTORE2 storage for the bound token
     * @param start Start offset (in the data, not including STOP byte)
     * @param size Number of bytes to read
     * @return chunk The requested SBE data
     */
    function getFixSBEChunk(uint256 start, uint256 size) external view returns (bytes memory chunk) {
        return _getSBEChunk(start, size);
    }

    /**
     * @notice Set or update the FIX descriptor for the bound token
     * @param descriptor The complete FixDescriptor struct
     */
    function setFixDescriptor(IFixDescriptor.FixDescriptor calldata descriptor) external {
        _authorizeSetFixDescriptor();
        _setDescriptor(descriptor);
    }

    /**
     * @notice Deploy SBE data and set descriptor in one transaction
     * @param sbeData Raw SBE-encoded data to deploy
     * @param descriptor Descriptor struct (fixSBEPtr and fixSBELen will be set automatically)
     * @return sbePtr Address of the deployed SBE data contract
     */
    function setFixDescriptorWithSBE(bytes memory sbeData, IFixDescriptor.FixDescriptor memory descriptor)
        external
        returns (address sbePtr)
    {
        _authorizeSetFixDescriptorWithSBE();
        return _deployAndSetDescriptor(sbeData, descriptor);
    }

    /// @notice Authorization hook for `setFixDescriptor`.
    function _authorizeSetFixDescriptor() internal virtual;

    /// @notice Authorization hook for `setFixDescriptorWithSBE`.
    function _authorizeSetFixDescriptorWithSBE() internal virtual;
}
