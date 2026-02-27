// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FixDescriptorEngineModule} from "../src/FixDescriptorEngineModule.sol";
import {FixDescriptorEngine} from "../src/FixDescriptorEngine.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";

contract MockFixDescriptorEngineModule is FixDescriptorEngineModule {
    function initialize(address engine_) external initializer {
        __FixDescriptorEngineModule_init_unchained(engine_);
    }

    function _authorizeSetDescriptorEngine() internal override {}
}

contract FixDescriptorEngineModuleTest is Test {
    MockFixDescriptorEngineModule public module;
    address public admin;

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

    function testInitializerSetsEngineWhenBoundToToken() public {
        module = new MockFixDescriptorEngineModule();
        FixDescriptorEngine engine = new FixDescriptorEngine(address(module), admin, "", _emptyDescriptor());

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
