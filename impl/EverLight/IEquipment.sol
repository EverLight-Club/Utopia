// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEquipment {
    
    function mintBatchEquipment(address recipient, uint256 characterId, uint8 maxPosition) external;

    function mintRandomEquipment(address recipient, uint8 position) external;

    function mintLuckStone(address recipient) external;

    function isLucklyStone(uint256 tokenId) external view  returns (bool);

    function burnEquipment(uint256 tokenId) external;

    function querySuitOwner(uint32 suitId) external view returns (address);

    function setSuitFlags(uint32 suitId, address _owner) external;

    function setNameFlags(string memory name, bool flags) external;

    function getEquipmentCE(uint256 characterId) external view returns (uint256 _ce);
}