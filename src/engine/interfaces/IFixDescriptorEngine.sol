// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * @dev minimum interface to define a FixDescriptorEngine
 */
interface IFixDescriptorEngine {
    /**
     * @notice Returns the address of the token this engine is bound to
     * @return token The address of the token this engine is bound to
     */
    function token() external view returns (address token);
}
