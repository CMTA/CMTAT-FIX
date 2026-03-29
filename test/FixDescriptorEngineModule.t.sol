// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FixDescriptorEngineModule} from "../src/FixDescriptorEngineModule.sol";
import {FixDescriptorEngine} from "../src/engine/FixDescriptorEngine.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

contract MockFixDescriptorEngineModule is FixDescriptorEngineModule {
    function initialize(address engine_) external initializer {
        __fixDescriptorEngineModuleInitUnchained(engine_);
    }

    function _authorizeSetDescriptorEngine() internal override {}
}

contract FixDescriptorEngineModuleTest is Test {
    MockFixDescriptorEngineModule public module;
    address public admin;
    event FixDescriptorEngineSet(address indexed engine);

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
    }

    /// @dev Must match `FIX_DESCRIPTOR_ENGINE_MODULE_STORAGE_LOCATION` (ERC-7201 comment in module).
    function testErc7201StorageSlotMatchesFormula() public pure {
        bytes32 computed = bytes32(
            uint256(
                keccak256(
                    abi.encode(uint256(keccak256("CMTAT.storage.FixDescriptorEngineModule")) - 1)
                )
            ) & ~uint256(0xff)
        );
        assertEq(
            computed,
            0xa53cb59b6022663116b97fd8896a8d8c96544a6d32d4ec30cfa96e5d8df7e300,
            "ERC-7201 slot must match CMTAT.storage.FixDescriptorEngineModule formula"
        );
    }

    function testInitializerSetsEngineWhenBoundToToken() public {
        module = new MockFixDescriptorEngineModule();
        FixDescriptorEngine engine = new FixDescriptorEngine(address(module), admin, "", _emptyDescriptor());

        vm.expectEmit(true, false, false, true);
        emit FixDescriptorEngineSet(address(engine));
        module.initialize(address(engine));

        assertEq(module.fixDescriptorEngine(), address(engine), "Initializer should set bound engine");
    }

    function testInitializerRevertsWhenEngineBoundToAnotherToken() public {
        module = new MockFixDescriptorEngineModule();
        FixDescriptorEngine wrongEngine = new FixDescriptorEngine(address(0xBEEF), admin, "", _emptyDescriptor());

        vm.expectRevert("FixDescriptorEngineModule: Engine not bound to this CMTAT");
        module.initialize(address(wrongEngine));
    }

    function testInitializerAllowsZeroEngine() public {
        module = new MockFixDescriptorEngineModule();

        module.initialize(address(0));

        assertEq(module.fixDescriptorEngine(), address(0), "Zero engine should be preserved");
    }
}
