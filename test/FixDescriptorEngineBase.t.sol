// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FixDescriptorEngineBase} from "../src/FixDescriptorEngineBase.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

contract OpenFixDescriptorEngineBase is FixDescriptorEngineBase {
    constructor(address token_, bytes memory sbeData_, IFixDescriptor.FixDescriptor memory descriptor_)
        FixDescriptorEngineBase(token_, sbeData_, descriptor_)
    {}

    function _authorizeSetFixDescriptor() internal pure override {}
    function _authorizeSetFixDescriptorWithSBE() internal pure override {}
}

contract FixDescriptorEngineBaseTest is Test {
    OpenFixDescriptorEngineBase public engine;
    address public token = address(0x3);

    bytes public sampleSBEData = hex"a2011901f70266555344";
    bytes32 public sampleMerkleRoot = bytes32(uint256(0x1234567890abcdef));
    bytes32 public sampleSchemaHash = keccak256("test-dictionary");

    function _emptyDescriptor() internal pure returns (IFixDescriptor.FixDescriptor memory descriptor) {
        descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: bytes32(0),
            fixRoot: bytes32(0),
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });
    }

    function testConstructorBindsToken() public {
        engine = new OpenFixDescriptorEngineBase(token, "", _emptyDescriptor());
        assertEq(engine.token(), token);
    }

    function testConstructorRevertsOnZeroToken() public {
        vm.expectRevert("FixDescriptorEngine: Invalid token address");
        new OpenFixDescriptorEngineBase(address(0), "", _emptyDescriptor());
    }

    function testSetFixDescriptorWorks() public {
        engine = new OpenFixDescriptorEngineBase(token, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0x1234567890123456789012345678901234567890),
            fixSBELen: 10,
            schemaURI: "ipfs://QmBase"
        });

        engine.setFixDescriptor(descriptor);
        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixRoot, sampleMerkleRoot);
    }

    function testSetFixDescriptorWithSBEWorks() public {
        engine = new OpenFixDescriptorEngineBase(token, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmBaseSBE"
        });

        address sbePtr = engine.setFixDescriptorWithSBE(sampleSBEData, descriptor);
        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixSBEPtr, sbePtr);
        assertEq(stored.fixSBELen, uint32(sampleSBEData.length));
    }

    function testVerifyFieldValidLeaf() public {
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes32 root = keccak256(abi.encodePacked(pathCBOR, value));

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: root,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new OpenFixDescriptorEngineBase(token, "", descriptor);

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);
        assertTrue(engine.verifyField(pathCBOR, value, proof, directions));
    }
}
