// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CMTATWithFixDescriptor} from "../src/CMTAT/CMTATWithFixDescriptor.sol";
import {FixDescriptorEngine} from "../src/engine/FixDescriptorEngine.sol";
import {CMTATBaseRuleEngine} from "CMTAT/contracts/modules/2_CMTATBaseRuleEngine.sol";
import {ICMTATConstructor} from "CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {IERC1643CMTAT} from "CMTAT/contracts/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import {IRuleEngine} from "CMTAT/contracts/interfaces/engine/IRuleEngine.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title CMTATWithFixDescriptorTest
 * @notice Comprehensive test suite for CMTATWithFixDescriptor view functions
 * @dev Tests all IFixDescriptor interface functions and integration with FixDescriptorEngine
 */
contract CMTATWithFixDescriptorTest is Test {
    CMTATWithFixDescriptor public token;
    FixDescriptorEngine public engine;
    address public admin;
    address public user;

    // Sample SBE data for testing
    bytes public sampleSBEData = hex"a2011901f70266555344"; // Simple SBE encoded data
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

        // Prepare CMTAT initialization parameters
        ICMTATConstructor.ERC20Attributes memory erc20Attrs =
            ICMTATConstructor.ERC20Attributes({name: "FIX Descriptor Token", symbol: "FIX", decimalsIrrevocable: 0});

        IERC1643CMTAT.DocumentInfo memory terms = IERC1643CMTAT.DocumentInfo({
            name: "Token Terms",
            uri: "https://example.com/terms",
            documentHash: keccak256("terms-v1")
        });

        ICMTATConstructor.ExtraInformationAttributes memory extraInfo = ICMTATConstructor.ExtraInformationAttributes({
            tokenId: "FIX-TOKEN-001",
            terms: terms,
            information: "CMTAT token with FIX descriptor support"
        });

        ICMTATConstructor.Engine memory engines = ICMTATConstructor.Engine({
            ruleEngine: IRuleEngine(address(0))
        });

        // Deploy token implementation
        CMTATWithFixDescriptor implementation = new CMTATWithFixDescriptor();

        // Deploy proxy and initialize token
        // CMTATWithFixDescriptor is upgradeable and requires proxy deployment
        // The implementation has _disableInitializers() so it cannot be initialized directly
        // We need to deploy via ERC1967Proxy and initialize through the proxy
        // Use abi.encodeCall to properly encode the initialize function call
        bytes memory initData = abi.encodeCall(CMTATBaseRuleEngine.initialize, (admin, erc20Attrs, extraInfo, engines));

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        token = CMTATWithFixDescriptor(address(proxy));

        // Verify admin has DEFAULT_ADMIN_ROLE after initialization (CMTAT pattern)
        bytes32 defaultAdminRole = token.DEFAULT_ADMIN_ROLE();
        assertTrue(token.hasRole(defaultAdminRole, admin), "Admin should have DEFAULT_ADMIN_ROLE after initialization");
        // Verify admin has DESCRIPTOR_ENGINE_ROLE via hasRole override (CMTAT pattern gives admin all roles)
        assertTrue(
            token.hasRole(token.DESCRIPTOR_ENGINE_ROLE(), admin),
            "Admin should have DESCRIPTOR_ENGINE_ROLE via hasRole override"
        );
        // Verify the role check that setFixDescriptorEngine will perform
        bytes32 requiredRole = token.DESCRIPTOR_ENGINE_ROLE();
        assertTrue(token.hasRole(requiredRole, admin), "Admin should have DESCRIPTOR_ENGINE_ROLE to set engine");

        // Deploy engine bound to token (without constructor initialization for backward compatibility)
        bytes memory emptySBE = "";
        IFixDescriptor.FixDescriptor memory emptyDescriptor = _emptyDescriptor();
        engine = new FixDescriptorEngine(address(token), admin, emptySBE, emptyDescriptor);

        // Verify engine admin has DEFAULT_ADMIN_ROLE
        assertTrue(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), admin), "Engine admin should have DEFAULT_ADMIN_ROLE");
        // Verify engine admin has DESCRIPTOR_ADMIN_ROLE via hasRole override
        assertTrue(
            engine.hasRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin),
            "Engine admin should have DESCRIPTOR_ADMIN_ROLE via hasRole override"
        );

        // Set engine on token (now admin has DEFAULT_ADMIN_ROLE from initialization)
        vm.prank(admin);
        token.setFixDescriptorEngine(address(engine));

        // Grant DESCRIPTOR_ADMIN_ROLE to admin on engine (admin already has it via hasRole override, but grant explicitly for clarity)
        vm.startPrank(admin);
        engine.grantRole(engine.DESCRIPTOR_ADMIN_ROLE(), admin);
        vm.stopPrank();

        // Set descriptor with SBE data
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0), // Will be set by engine
            fixSBELen: 0, // Will be set by engine
            schemaURI: "ipfs://QmExample"
        });

        vm.prank(admin);
        engine.setFixDescriptorWithSBE(sampleSBEData, descriptor);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetDescriptorEngine() public view {
        address engineAddress = token.getDescriptorEngine();
        assertEq(engineAddress, address(engine), "Engine address mismatch");
    }

    function testGetFixDescriptor() public view {
        IFixDescriptor.FixDescriptor memory descriptor = token.getFixDescriptor();

        assertEq(descriptor.schemaHash, sampleSchemaHash, "Schema hash mismatch");
        assertEq(descriptor.fixRoot, sampleMerkleRoot, "Merkle root mismatch");
        assertTrue(descriptor.fixSBEPtr != address(0), "SBE pointer should be set");
        assertEq(descriptor.fixSBELen, uint32(sampleSBEData.length), "SBE length mismatch");
        assertEq(keccak256(bytes(descriptor.schemaURI)), keccak256(bytes("ipfs://QmExample")), "Schema URI mismatch");
    }

    function testGetFixRoot() public view {
        bytes32 root = token.getFixRoot();
        assertEq(root, sampleMerkleRoot, "Root mismatch");
    }

    function testGetFixSBEChunk() public view {
        // Read full chunk
        bytes memory chunk = token.getFixSBEChunk(0, sampleSBEData.length);
        assertEq(chunk, sampleSBEData, "Full chunk mismatch");

        // Read partial chunk
        bytes memory partialChunk = token.getFixSBEChunk(0, 2);
        bytes memory expectedPartial = new bytes(2);
        expectedPartial[0] = sampleSBEData[0];
        expectedPartial[1] = sampleSBEData[1];
        assertEq(partialChunk, expectedPartial, "Partial chunk mismatch");

        // Read chunk from middle
        if (sampleSBEData.length > 3) {
            bytes memory middleChunk = token.getFixSBEChunk(1, 2);
            bytes memory expectedMiddle = new bytes(2);
            expectedMiddle[0] = sampleSBEData[1];
            expectedMiddle[1] = sampleSBEData[2];
            assertEq(middleChunk, expectedMiddle, "Middle chunk mismatch");
        }
    }

    function testGetFixSBEChunkBeyondEnd() public view {
        // Reading beyond end should return available data
        bytes memory chunk = token.getFixSBEChunk(0, 1000);
        assertEq(chunk.length, sampleSBEData.length, "Should return available data only");
        assertEq(chunk, sampleSBEData, "Should return full data");
    }

    function testGetFixSBEChunkFromBeyondEnd() public view {
        // Reading from beyond end should return empty
        bytes memory chunk = token.getFixSBEChunk(1000, 10);
        assertEq(chunk.length, 0, "Should return empty bytes");
    }

    function testVerifyField() public view {
        // This test only checks call plumbing through token->engine with current setUp descriptor.
        // Deterministic valid/invalid proof assertions are covered in dedicated tests below.
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);

        bool isValid = token.verifyField(pathCBOR, value, proof, directions);
        assertTrue(isValid || !isValid, "verifyField should return a boolean");
    }

    function testSupportsInterface() public view {
        // Test IFixDescriptor interface support
        bytes4 fixDescriptorInterfaceId = type(IFixDescriptor).interfaceId;
        assertTrue(token.supportsInterface(fixDescriptorInterfaceId), "Should support IFixDescriptor");

        // Test ERC165 support
        bytes4 erc165InterfaceId = type(IERC165).interfaceId;
        assertTrue(token.supportsInterface(erc165InterfaceId), "Should support ERC165");
    }

    /*//////////////////////////////////////////////////////////////
                        ERROR CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetFixDescriptorRevertsWhenEngineNotSet() public {
        // Deploy new token without engine
        CMTATWithFixDescriptor newToken = new CMTATWithFixDescriptor();

        vm.expectRevert("CMTATWithFixDescriptor: Engine not set");
        newToken.getFixDescriptor();
    }

    function testGetFixRootRevertsWhenEngineNotSet() public {
        CMTATWithFixDescriptor newToken = new CMTATWithFixDescriptor();

        vm.expectRevert("CMTATWithFixDescriptor: Engine not set");
        newToken.getFixRoot();
    }

    function testGetFixSBEChunkRevertsWhenEngineNotSet() public {
        CMTATWithFixDescriptor newToken = new CMTATWithFixDescriptor();

        vm.expectRevert("CMTATWithFixDescriptor: Engine not set");
        newToken.getFixSBEChunk(0, 10);
    }

    function testVerifyFieldRevertsWhenEngineNotSet() public {
        CMTATWithFixDescriptor newToken = new CMTATWithFixDescriptor();

        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);

        vm.expectRevert("CMTATWithFixDescriptor: Engine not set");
        newToken.verifyField(pathCBOR, value, proof, directions);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testEngineTokenBinding() public view {
        assertEq(engine.token(), address(token), "Engine should be bound to token");
    }

    function testSetFixDescriptorEngineRevertsWhenEngineBoundToAnotherToken() public {
        FixDescriptorEngine otherEngine = new FixDescriptorEngine(address(0xBEEF), admin, "", _emptyDescriptor());

        vm.prank(admin);
        vm.expectRevert("FixDescriptorEngineModule: Engine not bound to this CMTAT");
        token.setFixDescriptorEngine(address(otherEngine));
    }

    function testSetFixDescriptorEngineRevertsWhenSameEngine() public {
        vm.prank(admin);
        vm.expectRevert("FixDescriptorEngineModule: Same engine");
        token.setFixDescriptorEngine(address(engine));
    }

    function testSetFixDescriptorEngineRevertsWhenZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("FixDescriptorEngineModule: Invalid engine address");
        token.setFixDescriptorEngine(address(0));
    }

    function testSetFixDescriptorEngineRevertsWhenUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        token.setFixDescriptorEngine(address(engine));
    }

    function testSetDescriptorWithSBEViaTokenRevertsWhenUnauthorized() public {
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("unauthorized-dict"),
            fixRoot: bytes32(uint256(0x111)),
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmUnauthorized"
        });

        vm.prank(user);
        vm.expectRevert();
        token.setDescriptorWithSBE(hex"deadbeef", descriptor);
    }

    function testSetDescriptorViaTokenRevertsWhenUnauthorized() public {
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("unauthorized-direct"),
            fixRoot: bytes32(uint256(0x444)),
            fixSBEPtr: address(0x1234567890123456789012345678901234567890),
            fixSBELen: 42,
            schemaURI: "ipfs://QmUnauthorizedDirect"
        });

        vm.prank(user);
        vm.expectRevert();
        token.setDescriptor(descriptor);
    }

    function testSetDescriptorWithSBEViaTokenWorksForAdmin() public {
        bytes memory newSBEData = hex"deadbeef";
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("admin-write-dict"),
            fixRoot: bytes32(uint256(0x222)),
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: "ipfs://QmAdmin"
        });

        vm.prank(admin);
        address sbePtr = token.setDescriptorWithSBE(newSBEData, descriptor);

        IFixDescriptor.FixDescriptor memory stored = token.getFixDescriptor();
        assertEq(stored.fixRoot, bytes32(uint256(0x222)), "Descriptor root should update");
        assertEq(stored.fixSBELen, uint32(newSBEData.length), "Descriptor SBE length should update");
        assertEq(stored.fixSBEPtr, sbePtr, "Descriptor SBE pointer should match return value");
    }

    function testSetDescriptorViaTokenWorksForAdmin() public {
        IFixDescriptor.FixDescriptor memory descriptor = IFixDescriptor.FixDescriptor({
            schemaHash: keccak256("direct-admin-write"),
            fixRoot: bytes32(uint256(0x333)),
            fixSBEPtr: address(0x1234567890123456789012345678901234567890),
            fixSBELen: 42,
            schemaURI: "ipfs://QmAdminDirect"
        });

        vm.prank(admin);
        token.setDescriptor(descriptor);

        IFixDescriptor.FixDescriptor memory stored = token.getFixDescriptor();
        assertEq(stored.fixRoot, bytes32(uint256(0x333)), "Descriptor root should update");
        assertEq(stored.fixSBEPtr, descriptor.fixSBEPtr, "Descriptor pointer should update");
        assertEq(stored.fixSBELen, descriptor.fixSBELen, "Descriptor length should update");
    }

    function testVerifyFieldReturnsTrueForValidLeafProof() public {
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes32 root = keccak256(abi.encodePacked(pathCBOR, value));

        FixDescriptorEngine proofEngine = new FixDescriptorEngine(
            address(token),
            admin,
            "",
            IFixDescriptor.FixDescriptor({
                schemaHash: keccak256("proof-dict"),
                fixRoot: root,
                fixSBEPtr: address(0),
                fixSBELen: 0,
                schemaURI: "ipfs://QmProof"
            })
        );

        vm.prank(admin);
        token.setFixDescriptorEngine(address(proofEngine));

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);
        bool isValid = token.verifyField(pathCBOR, value, proof, directions);

        assertTrue(isValid, "Valid leaf proof should verify");
    }

    function testVerifyFieldReturnsFalseForInvalidLeafProof() public {
        bytes memory pathCBOR = hex"01";
        bytes memory value = hex"37";
        bytes memory wrongValue = hex"38";
        bytes32 root = keccak256(abi.encodePacked(pathCBOR, value));

        FixDescriptorEngine proofEngine = new FixDescriptorEngine(
            address(token),
            admin,
            "",
            IFixDescriptor.FixDescriptor({
                schemaHash: keccak256("proof-dict"),
                fixRoot: root,
                fixSBEPtr: address(0),
                fixSBELen: 0,
                schemaURI: "ipfs://QmProof"
            })
        );

        vm.prank(admin);
        token.setFixDescriptorEngine(address(proofEngine));

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory directions = new bool[](0);
        bool isValid = token.verifyField(pathCBOR, wrongValue, proof, directions);

        assertFalse(isValid, "Wrong leaf should fail verification");
    }

    function testEngineDescriptorMatchesToken() public view {
        IFixDescriptor.FixDescriptor memory engineDesc = engine.getFixDescriptor();
        IFixDescriptor.FixDescriptor memory tokenDesc = token.getFixDescriptor();

        assertEq(engineDesc.schemaHash, tokenDesc.schemaHash, "Schema hash should match");
        assertEq(engineDesc.fixRoot, tokenDesc.fixRoot, "Root should match");
        assertEq(engineDesc.fixSBEPtr, tokenDesc.fixSBEPtr, "SBE pointer should match");
        assertEq(engineDesc.fixSBELen, tokenDesc.fixSBELen, "SBE length should match");
    }

    function testEngineRootMatchesTokenRoot() public view {
        bytes32 engineRoot = engine.getFixRoot();
        bytes32 tokenRoot = token.getFixRoot();

        assertEq(engineRoot, tokenRoot, "Roots should match");
    }

    function testEngineSBEChunkMatchesTokenChunk() public view {
        bytes memory engineChunk = engine.getFixSBEChunk(0, sampleSBEData.length);
        bytes memory tokenChunk = token.getFixSBEChunk(0, sampleSBEData.length);

        assertEq(engineChunk, tokenChunk, "Chunks should match");
        assertEq(engineChunk, sampleSBEData, "Chunk should match original data");
    }
}
