// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Character.
 */
interface ICharacter {
    enum CHARACTERATTR {
        CHARACTER_NAME,
        CHARACTER_OCCUPATION,
        CHARACTER_SEX,
        CHARACTER_LEVEL,
        CHARACTER_EXPERIENCE,
        CHARACTER_POINTS,
        CHARACTER_STRENGTH,
        CHARACTER_DEXTERITY,
        CHARACTER_INTELLIGENCE,
        CHARACTER_CONSTITUTION,
        CHARACTER_LUCK,
        CHARACTER_GOLD
    }

    enum EOCCUPATION {
        Warrior, 
        Archer, 
        Mage
    }

    enum ESEX {
        Male,
        Female,
        Neutral
    }

    event NewCharacter(address indexed owner, address indexed recommender, uint256 characterId);

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    //function exists(uint256 tokenId) external view returns (bool);
    //function ownerOf(uint256 tokenId) external view returns (address owner);
    // function getCharacterId(string memory name) external view returns (uint256);
    // function getCharacters(address owner) external view returns (uint256[] memory);
    // function getAttr(uint256 tokenId, uint256 attrId) external view returns (uint256, string memory);
    function getBatchAttr(uint256 tokenId, uint256[] memory attrId) external view returns (uint256[] memory);
    // function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory);

    // function increaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external;
    // function decreaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external;
    // function setExtendAttr(uint256 tokenId, string memory key, string memory value) external;


    // function mintCharacter(address recipient, uint256 tokenId, string memory name, EOCCUPATION occupation) external;*/




    
















}
