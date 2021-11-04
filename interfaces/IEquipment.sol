// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Equipment.
 */
interface IEquipment {
    enum EQUIPMENTATTR {
        EQUIPMENT_ID,
        EQUIPMENT_NAME,
        EQUIPMENT_POSITION,
        EQUIPMENT_LEVEL,
        EQUIPMENT_RARITY,
        EQUIPMENT_SUITID,

        LEVEL_LIMIT,
        SEX_LIMIT,
        OCCUPATION_LIMIT,
        STRENGTH_LIMIT,
        DEXTERITY_LIMIT,
        INTELLIGENCE_LIMIT,
        CONSTITUTION_LIMIT,

        STRENGTH_BONUS,
        DEXTERITY_BONUS,
        INTELLIGENCE_BONUS,
        CONSTITUTION_BONUS,
        ATTACK_BONUS,
        DEFENSE_BONUS,
        SPEED_BONUS
    }

    event NewEquipment(address indexed owner, uint256 tokenId, uint256 equipmentId);

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
    function getEquipmentList(uint256 characterId) external view returns (uint256[] memory);
    function getEquipments(address owner) external view returns (uint256[] memory);
    function getEquipmentAttr(uint256 tokenId, uint256[] memory attrs) external view returns (uint256[] memory);
    function equipmentBouns(uint256 characterId, uint256[] memory attrIds) external view returns (uint256[] memory);
    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory);
    function getOriginExtendAttr(uint256 tokenId, string memory key) external view returns (string memory);

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external;
    function claim(address to, uint256 equipmentId) external;
}
