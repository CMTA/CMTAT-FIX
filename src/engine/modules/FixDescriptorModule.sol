// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";
import "@fixdescriptorkit/contracts/src/FixDescriptorLib.sol";
import "@fixdescriptorkit/contracts/src/SSTORE2.sol";

/**
 * @title FixDescriptorModule
 * @notice Module for managing FIX descriptor storage and verification
 * @dev Handles storage, retrieval, and verification of descriptors for a single token
 *      Uses FixDescriptorLib as the underlying implementation
 *      This module is designed for single-token engines (one engine per token)
 */
abstract contract FixDescriptorModule {
    using FixDescriptorLib for FixDescriptorLib.Storage;

    /// @notice Single descriptor storage for the bound token
    FixDescriptorLib.Storage internal _descriptor;

    /**
     * @notice Get the descriptor for the bound token
     * @return descriptor The FixDescriptor struct
     */
    function _getDescriptor() internal view returns (IFixDescriptor.FixDescriptor memory descriptor) {
        return _descriptor.getDescriptor();
    }

    /**
     * @notice Set or update the descriptor for the bound token
     * @param descriptor The complete FixDescriptor struct
     */
    function _setDescriptor(IFixDescriptor.FixDescriptor calldata descriptor) internal {
        _descriptor.setDescriptor(descriptor);
    }

    /**
     * @notice Check if the descriptor has been initialized
     * @return True if descriptor is initialized
     */
    function _isInitialized() internal view returns (bool) {
        return _descriptor.isInitialized();
    }

    /**
     * @notice Verify a specific field against the committed descriptor
     * @param pathCBOR CBOR-encoded bytes of the field path
     * @param value Raw FIX value bytes
     * @param proof Merkle proof (sibling hashes)
     * @param directions Direction array (true=right child, false=left child)
     * @return valid True if the proof is valid
     */
    function _verifyField(
        bytes calldata pathCBOR,
        bytes calldata value,
        bytes32[] calldata proof,
        bool[] calldata directions
    ) internal view returns (bool valid) {
        return _descriptor.verifyFieldProof(pathCBOR, value, proof, directions);
    }

    /**
     * @notice Get SBE data chunk from SSTORE2 storage
     * @param start Start offset (in the data, not including STOP byte)
     * @param size Number of bytes to read
     * @return chunk The requested SBE data
     */
    function _getSBEChunk(uint256 start, uint256 size) internal view returns (bytes memory chunk) {
        return _descriptor.getFixSBEChunk(start, size);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy SBE data using SSTORE2 pattern and set descriptor
     * @param sbeData Raw SBE-encoded data to deploy
     * @param descriptor Descriptor struct (fixSBEPtr and fixSBELen will be set automatically)
     * @return sbePtr Address of the deployed SBE data contract
     */
    function _deployAndSetDescriptor(bytes memory sbeData, IFixDescriptor.FixDescriptor memory descriptor)
        internal
        returns (address sbePtr)
    {
        sbePtr = _deploySBE(sbeData);

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sbePtr)
        }
        require(codeSize == sbeData.length + 1, "FixDescriptorModule: Invalid SBE size");

        descriptor.fixSBEPtr = sbePtr;
        descriptor.fixSBELen = uint32(sbeData.length);

        _setDescriptorMemory(descriptor);

        return sbePtr;
    }

    /**
     * @notice Set descriptor from memory
     * @param descriptor Descriptor struct in memory
     */
    function _setDescriptorMemory(IFixDescriptor.FixDescriptor memory descriptor) internal {
        bytes32 oldRoot = _descriptor.descriptor.fixRoot;
        _descriptor.descriptor = descriptor;

        if (_descriptor.initialized) {
            emit IFixDescriptor.FixDescriptorUpdated(oldRoot, descriptor.fixRoot, descriptor.fixSBEPtr);
        } else {
            emit IFixDescriptor.FixDescriptorSet(
                descriptor.fixRoot, descriptor.schemaHash, descriptor.fixSBEPtr, descriptor.fixSBELen
            );
            _descriptor.initialized = true;
        }
    }

    /**
     * @notice Initialize descriptor from constructor
     * @param sbeData Raw SBE-encoded data to deploy
     * @param descriptor Descriptor struct
     */
    function _initializeDescriptorFromConstructor(bytes memory sbeData, IFixDescriptor.FixDescriptor memory descriptor)
        internal
    {
        address sbePtr = address(0);

        if (sbeData.length > 0) {
            sbePtr = _deploySBE(sbeData);

            uint256 codeSize;
            assembly {
                codeSize := extcodesize(sbePtr)
            }
            require(codeSize == sbeData.length + 1, "FixDescriptorModule: Invalid SBE size");

            descriptor.fixSBEPtr = sbePtr;
            descriptor.fixSBELen = uint32(sbeData.length);
        }

        require(descriptor.fixRoot != bytes32(0), "FixDescriptorModule: Invalid descriptor root");

        _setDescriptorMemory(descriptor);
    }

    /**
     * @notice Deploy data to a contract using SSTORE2 pattern
     * @param data The data to store
     * @return ptr Address of the deployed data contract
     */
    function _deploySBE(bytes memory data) internal returns (address ptr) {
        return SSTORE2.write(data);
    }
}
