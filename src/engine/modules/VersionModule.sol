// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VersionModule
 * @notice Module for version tracking
 * @dev Provides version information for the engine
 */
abstract contract VersionModule {
    /// @notice Version string
    string public constant VERSION = "1.0.0";

    /**
     * @notice Get the version of the engine
     * @return version The version string
     */
    function version() external pure virtual returns (string memory) {
        return VERSION;
    }
}
