// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Equipment.
 */
interface IEquipmentDB { 
    event NewEquipment(address indexed creator, uint256 equipmentId, string equipmentName);

    function getAttr(uint256 tokenId, uint256 attrId) external view returns (uint256, string memory);
    function getBatchAttr(uint256 tokenId, uint256[] memory attrId) external view returns (uint256[] memory);
    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory);
    function getBaseAttr(uint256 tokenId) external view returns (uint256, string memory, uint256, uint256, uint256, uint256);
    function getLimitAttr(uint256 tokenId) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getBonusAttr(uint256 tokenId) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}
