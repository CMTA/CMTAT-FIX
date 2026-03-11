// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/engine/FixDescriptorEngine.sol";
import "../src/example/CMTATWithFixDescriptor.sol";
import "../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import "../lib/CMTAT/contracts/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import "../lib/CMTAT/contracts/interfaces/engine/IRuleEngine.sol";
import "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

/**
 * @title DeployCMTATWithFixDescriptor
 * @notice Deployment script for CMTATWithFixDescriptor and FixDescriptorEngine
 * @dev Deploys a CMTAT token with FIX descriptor support
 * 
 * Usage:
 *   forge script scripts/DeployCMTATWithFixDescriptor.s.sol:DeployCMTATWithFixDescriptor --rpc-url $RPC_URL --broadcast --verify
 */
contract DeployCMTATWithFixDescriptor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        // Prepare CMTAT initialization parameters
        ICMTATConstructor.ERC20Attributes memory erc20Attrs = ICMTATConstructor.ERC20Attributes({
            name: "FIX Descriptor Token",
            symbol: "FIX",
            decimalsIrrevocable: 0
        });

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

        // Deploy implementation contract
        CMTATWithFixDescriptor implementation = new CMTATWithFixDescriptor();
        console.log("CMTATWithFixDescriptor implementation deployed at:", address(implementation));

        // Note: For actual deployment, you would deploy a proxy using OpenZeppelin's proxy pattern
        // This script shows the implementation deployment
        // To deploy with proxy, use:
        //   ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");
        //   CMTATWithFixDescriptor token = CMTATWithFixDescriptor(address(proxy));
        //   token.initialize(admin, erc20Attrs, extraInfo, engines);

        // In production, bind engines to the deployed token/proxy address provided via TOKEN_ADDRESS.
        
        // Example 1: Deploy engine WITHOUT constructor initialization (backward compatible)
        // This requires calling setFixDescriptor() or setFixDescriptorWithSBE() later
        bytes memory emptySBE = "";
        IFixDescriptor.FixDescriptor memory emptyDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: bytes32(0),
            fixRoot: bytes32(0),
            fixSBEPtr: address(0),
            fixSBELen: 0,
            schemaURI: ""
        });
        
        FixDescriptorEngine engineWithoutInit = new FixDescriptorEngine(
            tokenAddress,
            admin,
            emptySBE,
            emptyDescriptor
        );
        console.log("FixDescriptorEngine (without init) deployed at:", address(engineWithoutInit));
        
        // Example 2: Deploy engine WITH constructor initialization
        // This initializes the descriptor during construction - engine is ready immediately
        bytes memory sampleSBEData = hex"a2011901f70266555344"; // Example SBE data
        bytes32 sampleMerkleRoot = bytes32(uint256(0x1234567890abcdef));
        bytes32 sampleSchemaHash = keccak256("test-dictionary");
        
        IFixDescriptor.FixDescriptor memory initialDescriptor = IFixDescriptor.FixDescriptor({
            schemaHash: sampleSchemaHash,
            fixRoot: sampleMerkleRoot,
            fixSBEPtr: address(0), // Will be set automatically by constructor
            fixSBELen: 0,          // Will be set automatically by constructor
            schemaURI: "ipfs://QmExample"
        });
        
        FixDescriptorEngine engineWithInit = new FixDescriptorEngine(
            tokenAddress,
            admin,
            sampleSBEData,
            initialDescriptor
        );
        console.log("FixDescriptorEngine (with init) deployed at:", address(engineWithInit));
        console.log("FixDescriptorEngine bound to token:", tokenAddress);
        
        // Verify the initialized engine has descriptor set
        IFixDescriptor.FixDescriptor memory desc = engineWithInit.getFixDescriptor();
        console.log("Initialized engine descriptor root:", vm.toString(desc.fixRoot));
        console.log("Initialized engine SBE pointer:", address(desc.fixSBEPtr));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("Admin:", admin);
        console.log("Token/Proxy:", tokenAddress);
        console.log("CMTAT Implementation:", address(implementation));
        console.log("FixDescriptorEngine (without init):", address(engineWithoutInit));
        console.log("FixDescriptorEngine (with init):", address(engineWithInit));
        console.log("\n=== Deployment Patterns ===");
        console.log("Pattern 1: Constructor initialization (recommended)");
        console.log("  - Engine is ready immediately after deployment");
        console.log("  - No need to call setFixDescriptor() separately");
        console.log("  - Use when you have descriptor data at deployment time");
        console.log("\nPattern 2: Post-deployment initialization");
        console.log("  - Deploy engine with empty parameters");
        console.log("  - Call engine.setFixDescriptor() or setFixDescriptorWithSBE() later");
        console.log("  - Use when descriptor data is not available at deployment time");
        console.log("\n=== Next Steps (Pattern 2 only) ===");
        console.log("1. Deploy proxy pointing to implementation");
        console.log("2. Initialize proxy with initialize()");
        console.log("3. Call token.setFixDescriptorEngine(address(engine))");
        console.log("4. Grant DESCRIPTOR_ADMIN_ROLE on engine to admin");
        console.log("5. Call engine.setFixDescriptorWithSBE() to set descriptor");
    }
}
