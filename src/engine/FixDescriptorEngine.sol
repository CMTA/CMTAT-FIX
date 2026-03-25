// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IFixDescriptor} from "@fixdescriptorkit/contracts/src/IFixDescriptor.sol";
import {FixDescriptorEngineBase} from "./FixDescriptorEngineBase.sol";

/**
 * @title FixDescriptorEngine
 * @notice Engine contract for managing FIX descriptor for a single bound token
 * @dev One engine instance is bound to one token at construction time
 */
contract FixDescriptorEngine is FixDescriptorEngineBase, AccessControlEnumerable {
    /// @notice Role for setting descriptors
    bytes32 public constant DESCRIPTOR_ADMIN_ROLE = keccak256("DESCRIPTOR_ADMIN_ROLE");

    /**
     * @notice Constructor
     * @param token_ Address of the token contract this engine will manage
     * @param admin Address to grant DEFAULT_ADMIN_ROLE
     * @param sbeData_ Optional SBE-encoded data to deploy and initialize descriptor
     * @param descriptor_ Optional descriptor struct to initialize
     */
    constructor(address token_, address admin, bytes memory sbeData_, IFixDescriptor.FixDescriptor memory descriptor_)
        FixDescriptorEngineBase(token_, sbeData_, descriptor_)
    {
        require(admin != address(0), "FixDescriptorEngine: Invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`
     * @dev Default Admin has all roles
     */
    function hasRole(bytes32 role, address account) public view virtual override(AccessControl, IAccessControl) returns (bool) {
        if (AccessControl.hasRole(DEFAULT_ADMIN_ROLE, account)) {
            return true;
        } else {
            return AccessControl.hasRole(role, account);
        }
    }

    function _authorizeSetFixDescriptor() internal virtual override {
        require(
            msg.sender == TOKEN || hasRole(DESCRIPTOR_ADMIN_ROLE, msg.sender),
            "FixDescriptorEngine: Missing descriptor admin role"
        );
    }

    function _authorizeSetFixDescriptorWithSBE() internal virtual override {
        require(
            msg.sender == TOKEN || hasRole(DESCRIPTOR_ADMIN_ROLE, msg.sender),
            "FixDescriptorEngine: Missing descriptor admin role"
        );
    }
}
