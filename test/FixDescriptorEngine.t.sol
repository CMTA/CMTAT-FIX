// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FixDescriptorEngine} from "../src/engine/FixDescriptorEngine.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

/**
 * @title FixDescriptorEngineTest
 * @notice Comprehensive test suite for FixDescriptorEngine
 * @dev Tests all FixDescriptorEngine functionality including constructor initialization,
 *      descriptor management, SBE deployment, and verification
 */
contract FixDescriptorEngineTest is Test {
    FixDescriptorEngine public engine;
    address public token;
    address public admin;
    address public user;

    // Sample SBE data for testing
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

    function setUp() public {
        admin = vm.addr(1);
        user = vm.addr(2);
        token = address(0x3);
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructor() public {
        bytes memory emptySBE = "";
        IFixDescriptor.FixDescriptor memory emptyDescriptor = _emptyDescriptor();

        engine = new FixDescriptorEngine(token, admin, emptySBE, emptyDescriptor);

        assertEq(engine.token(), token, "Token address should match");
        assertTrue(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), admin), "Admin should have DEFAULT_ADMIN_ROLE");
        assertTrue(engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin), "Admin should have DESCRIPTOR_ADMIN_ROLE");
    }

    function testConstructorRevertsOnZeroToken() public {
        bytes memory emptySBE = "";
        IFixDescriptor.FixDescriptor memory emptyDescriptor = _emptyDescriptor();

        vm.expectRevert("FixDescriptorEngine: Invalid token address");
        new FixDescriptorEngine(address(0), admin, emptySBE, emptyDescriptor);
    }

    function testConstructorRevertsOnZeroAdmin() public {
        bytes memory emptySBE = "";
        IFixDescriptor.FixDescriptor memory emptyDescriptor = _emptyDescriptor();

        vm.expectRevert("FixDescriptorEngine: Invalid admin address");
        new FixDescriptorEngine(token, address(0), emptySBE, emptyDescriptor);
    }

    function testConstructorWithInitialization() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmExample"
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Verify descriptor is immediately available
        IFixDescriptor.FixDescriptor memory desc = engine.getFixDescriptor();
        assertEq(desc.schemaHash, sampleSchemaHash, "Schema hash should match");
        assertEq(desc.fixRoot, sampleMerkleRoot, "Root should match");
        assertTrue(desc.fixSBEPtr != address(0), "SBE pointer should be set");
        assertEq(desc.fixSBELen, uint32(sampleSBEData.length), "SBE length should match");
    }

    function testVersion() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());
        assertEq(engine.version(), "1.0.0", "Version should match module constant");
    }

    /*//////////////////////////////////////////////////////////////
                        DESCRIPTOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetFixDescriptor() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        address preDeployedSBE = address(0x1234567890123456789012345678901234567890);
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("new-dict"),
            fixRoot: bytes32(uint256(0xabcdef)),
            fixSBEPtr: preDeployedSBE,
            fixSBELen: 100,
            schemaURI: "ipfs://QmNew"
        });

        vm.prank(admin);
        engine.setFixDescriptor(descriptor);

        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixSBEPtr, preDeployedSBE, "SBE pointer should match");
    }

    function testSetFixDescriptorRevertsWhenUnauthorized() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("new-dict"),
            fixRoot: bytes32(uint256(0xabcdef)),
            fixSBEPtr: address(0x123),
            fixSBELen: 100,
            schemaURI: ""
        });

        vm.prank(user);
        vm.expectRevert();
        engine.setFixDescriptor(descriptor);
    }

    function testSetFixDescriptorWithSBE() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmTest"
        });

        vm.prank(admin);
        address sbePtr = engine.setFixDescriptorWithSBE(sampleSBEData, descriptor);

        assertTrue(sbePtr != address(0), "SBE pointer should be set");

        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixSBEPtr, sbePtr, "SBE pointer should match returned value");
        assertEq(stored.fixSBELen, uint32(sampleSBEData.length), "SBE length should match");
    }

    function testSetFixDescriptorWithSBEAllowsBoundTokenCaller() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmTokenCaller"
        });

        vm.prank(token);
        address sbePtr = engine.setFixDescriptorWithSBE(sampleSBEData, descriptor);

        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixSBEPtr, sbePtr, "Token caller should be able to update descriptor");
    }

    function testSetFixDescriptorWithSBERevertsWhenUnauthorized() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        vm.prank(user);
        vm.expectRevert();
        engine.setFixDescriptorWithSBE(sampleSBEData, descriptor);
    }

    function testUpdateDescriptor() public {
        // Initialize with first descriptor
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Update descriptor
        bytes memory newSBEData = hex"deadbeef";
        IFixDescriptor.FixDescriptor memory updatedDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("updated-dict"),
            fixRoot: bytes32(uint256(0x999)),
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmUpdated"
        });

        vm.prank(admin);
        engine.setFixDescriptorWithSBE(newSBEData, updatedDescriptor);

        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixRoot, bytes32(uint256(0x999)), "Updated root should match");
    }

    function testSetFixDescriptorAllowsBoundTokenCaller() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("token-direct-write"),
            fixRoot: bytes32(uint256(0x777)),
            fixSBEPtr: address(0x1234567890123456789012345678901234567890),
            fixSBELen: 10,
            schemaURI: "ipfs://QmTokenDirect"
        });

        vm.prank(token);
        engine.setFixDescriptor(descriptor);

        IFixDescriptor.FixDescriptor memory stored = engine.getFixDescriptor();
        assertEq(stored.fixRoot, descriptor.fixRoot, "Bound token caller should update root");
        assertEq(stored.fixSBEPtr, descriptor.fixSBEPtr, "Bound token caller should update pointer");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetFixDescriptor() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmTest"
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        IFixDescriptor.FixDescriptor memory desc = engine.getFixDescriptor();
        assertEq(desc.schemaHash, sampleSchemaHash, "Schema hash should match");
        assertEq(desc.fixRoot, sampleMerkleRoot, "Root should match");
    }

    function testGetFixDescriptorRevertsWhenNotInitialized() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        vm.expectRevert("Descriptor not initialized");
        engine.getFixDescriptor();
    }

    function testGetFixRoot() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        bytes32 root = engine.getFixRoot();
        assertEq(root, sampleMerkleRoot, "Root should match");
    }

    function testGetFixSBEChunk() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Read full chunk
        bytes memory chunk = engine.getFixSBEChunk(0, sampleSBEData.length);
        assertEq(chunk, sampleSBEData, "Full chunk should match");

        // Read partial chunk
        bytes memory partialChunk = engine.getFixSBEChunk(0, 2);
        assertEq(partialChunk.length, 2, "Partial chunk length should match");
        assertEq(partialChunk[0], sampleSBEData[0], "First byte should match");
        assertEq(partialChunk[1], sampleSBEData[1], "Second byte should match");
    }

    function testGetFixSBEChunkBeyondEnd() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Reading beyond end should return available data only
        bytes memory chunk = engine.getFixSBEChunk(0, 1000);
        assertEq(chunk.length, sampleSBEData.length, "Should return available data only");
    }

    function testGetFixSBEChunkFromBeyondEnd() public {
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Reading from beyond end should return empty
        bytes memory chunk = engine.getFixSBEChunk(1000, 10);
        assertEq(chunk.length, 0, "Should return empty bytes");
    }

    /*//////////////////////////////////////////////////////////////
                        VERIFICATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testVerifyField() public {
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes32 root = keccak256(abi.encodePacked(pathCBOR, value));

        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: root,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        // Single-leaf tree: empty proof should validate exactly the committed leaf.
        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);

        bool isValid = engine.verifyField(pathCBOR, value, proof, directions);
        assertTrue(isValid, "Valid leaf proof should verify against committed root");
    }

    function testVerifyFieldReturnsFalseForInvalidLeaf() public {
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes memory wrongValue = hex"38";
        bytes32 root = keccak256(abi.encodePacked(pathCBOR, value));

        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: root,
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });

        engine = new FixDescriptorEngine(token, admin, sampleSBEData, initialDescriptor);

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);

        bool isValid = engine.verifyField(pathCBOR, wrongValue, proof, directions);
        assertFalse(isValid, "Wrong leaf should not verify against committed root");
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL ENUMERABLE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetRoleMemberCount() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        assertEq(engine.getRoleMemberCount(engine.DEFAULT_ADMIN_ROLE()), 1, "DEFAULT_ADMIN_ROLE should have 1 member");
        assertEq(engine.getRoleMemberCount(engine.DESCRIPTOR_ADMIN_ROLE()), 0, "DESCRIPTOR_ADMIN_ROLE should have 0 explicit members");
    }

    function testGetRoleMember() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        assertEq(engine.getRoleMember(engine.DEFAULT_ADMIN_ROLE(), 0), admin, "First DEFAULT_ADMIN_ROLE member should be admin");
    }

    function testGetRoleMemberCountAfterGrant() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        vm.stopPrank();

        assertEq(engine.getRoleMemberCount(engine.DESCRIPTOR_ADMIN_ROLE()), 1, "DESCRIPTOR_ADMIN_ROLE should have 1 member after grant");
        assertEq(engine.getRoleMember(engine.DESCRIPTOR_ADMIN_ROLE(), 0), user, "Member should be user");
    }

    function testGetRoleMemberCountAfterRevoke() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        engine.revokeRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        vm.stopPrank();

        assertEq(engine.getRoleMemberCount(engine.DESCRIPTOR_ADMIN_ROLE()), 0, "DESCRIPTOR_ADMIN_ROLE should have 0 members after revoke");
    }

    function testGetRoleMembersMultiple() public {
        address user2 = vm.addr(3);
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user2);
        vm.stopPrank();

        assertEq(engine.getRoleMemberCount(engine.DESCRIPTOR_ADMIN_ROLE()), 2, "Should have 2 members");
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function testHasRole() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        // Admin should have all roles
        assertTrue(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), admin), "Admin should have DEFAULT_ADMIN_ROLE");
        assertTrue(engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin), "Admin should have DESCRIPTOR_ADMIN_ROLE");

        // User should not have roles
        assertFalse(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), user), "User should not have DEFAULT_ADMIN_ROLE");
        assertFalse(engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), user), "User should not have DESCRIPTOR_ADMIN_ROLE");
    }

    function testGrantRole() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        // Verify admin has DEFAULT_ADMIN_ROLE (granted in constructor)
        bytes32 defaultAdminRole = engine.DEFAULT_ADMIN_ROLE();
        assertTrue(engine.hasRole(defaultAdminRole, admin), "Admin should have DEFAULT_ADMIN_ROLE");
        // Verify admin has DESCRIPTOR_ADMIN_ROLE via hasRole override
        assertTrue(
            engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin),
            "Admin should have DESCRIPTOR_ADMIN_ROLE via hasRole override"
        );
        // Verify admin can grant DESCRIPTOR_ADMIN_ROLE (admin role is admin for all roles by default)
        bytes32 adminRole = engine.getRoleAdmin(engine.DESCRIPTOR_ADMIN_ROLE());
        assertEq(adminRole, defaultAdminRole, "DESCRIPTOR_ADMIN_ROLE admin should be DEFAULT_ADMIN_ROLE");
        // Verify admin has the admin role (this is what grantRole checks)
        assertTrue(engine.hasRole(adminRole, admin), "Admin should have admin role for DESCRIPTOR_ADMIN_ROLE");
        // Double-check: verify the role check that grantRole will perform
        bytes32 roleToGrant = engine.DESCRIPTOR_ADMIN_ROLE();
        bytes32 requiredAdminRole = engine.getRoleAdmin(roleToGrant);
        assertTrue(
            engine.hasRole(requiredAdminRole, admin),
            "Admin should have required admin role to grant DESCRIPTOR_ADMIN_ROLE"
        );

        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        vm.stopPrank();

        assertTrue(
            engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), user), "User should have DESCRIPTOR_ADMIN_ROLE after grant"
        );
    }

    function testRevokeRole() public {
        engine = new FixDescriptorEngine(token, admin, "", _emptyDescriptor());

        // Verify admin has DEFAULT_ADMIN_ROLE (granted in constructor)
        assertTrue(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), admin), "Admin should have DEFAULT_ADMIN_ROLE");
        // Verify admin can grant DESCRIPTOR_ADMIN_ROLE
        assertTrue(
            engine.hasRole(engine.getRoleAdmin(engine.DESCRIPTOR_ADMIN_ROLE()), admin),
            "Admin should have admin role for DESCRIPTOR_ADMIN_ROLE"
        );

        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        engine.revokeRole(engine.DESCRIPTOR_ADMIN_ROLE(), user);
        vm.stopPrank();

        assertFalse(
            engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), user),
            "User should not have DESCRIPTOR_ADMIN_ROLE after revoke"
        );
    }
}
