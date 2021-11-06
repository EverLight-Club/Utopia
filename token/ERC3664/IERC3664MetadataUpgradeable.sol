// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3664Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC3664 standard.
 */
interface IERC3664MetadataUpgradeable is IERC3664Upgradeable {
    /**
     * @dev Returns the name of the attribute.
     */
    function name(uint256 attrId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the attribute.
     */
    function symbol(uint256 attrId) external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `attrId` attribute.
     */
    function attrURI(uint256 attrId) external view returns (string memory);
}
