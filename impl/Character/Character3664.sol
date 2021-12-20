// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/ICharacter.sol";
import "../../utils/Strings.sol";

contract Character3664 is ICharacter, ERC3664Upgradeable, DirectoryBridge {
    
    using Strings for uint256;

    constructor() {
        initialize();
    }
    
    function initialize() public initializer {
        __ERC3664_init();
        __DirectoryBridge_init();
        __Character_init_unchained();
    }

    function CharacterInit(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner {
        _mintBatch(attrIds, names, symbols, uris);
    }

    function __Character_init_unchained() internal initializer {
    }

    function initAttributeForCharacter(uint256 tokenId, string memory name, uint256 occupation, uint256 sex) external onlyDirectory { 
        _initAttribute(tokenId, name, occupation, sex);
    }

    function attach(uint256 tokenId, uint256 attrId, uint256 amount, bytes memory text, bool isPrimary) external onlyDirectory {
        _attach(tokenId, attrId, amount, text, isPrimary);
    }

    function batchAttach(
        uint256 tokenId,
        uint256[] memory attrIds,
        uint256[] memory amounts,
        bytes[] memory texts
    ) external onlyDirectory { 
        _batchAttach(tokenId, attrIds, amounts, texts);
    }

    function burn(uint256 tokenId, uint256 attrId, uint256 amount) external onlyDirectory { 
        _burn(tokenId, attrId, amount);
    }

    function mintBatch(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyDirectory {
        _mintBatch(attrIds, names, symbols, uris);
    }

    function burnBatch(
        uint256 tokenId,
        uint256[] memory attrIds,
        uint256[] memory amounts
    ) external onlyDirectory { 
        _burnBatch(tokenId, attrIds, amounts);
    }

    function queryCharacterAttrs(uint256 tokenId) external view returns(uint256[] memory balances) {
        //require(_exists(tokenId), "Token not exist");
        uint256[] memory attrIds = _getInitAttributeAttrIds();
        balances = new uint256[](attrIds.length);
        for(uint256 i = 0; i < attrIds.length; i++){
            balances[i] = balanceOf(tokenId, attrIds[i]);
        }
    }

    function _initAttribute(uint256 tokenId, string memory name, uint256 occupation, uint256 sex) internal {
        _batchAttach(tokenId, _getInitAttributeAttrIds(), _getInitAttributeAmounts(occupation, sex), _getInitAttributeTexts(name));
    }

    function _getInitAttributeAttrIds() internal pure returns(uint256[] memory) {
        uint256[] memory attrIds = new uint256[](12);
        {
            (
                attrIds[0], attrIds[1], attrIds[2], attrIds[3], attrIds[4]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                uint256(CHARACTERATTR.CHARACTER_EXPERIENCE)
            );
        }
        {
            (
                attrIds[5], attrIds[6], attrIds[7], attrIds[8], attrIds[9]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_POINTS), 
                uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_PATIENCE)
            );
        }
        {
            (
                attrIds[10], attrIds[11]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)
            );
        }
        return attrIds;
    }

    function _getInitAttributeAmounts(uint256 occupation, uint256 sex) internal pure returns(uint256[] memory) {
        // 经验值：等级为1进行计算经验值；
        //玩家当前等级经验=INT（（ROUND((玩家当前等级^3*0.004)+玩家当前等级*INT(玩家当前等级*0.02)+玩家当前等级*2+10,0)）*（INT((玩家当前等级^3*0.0003+玩家当前等级^2*0.002+玩家当前等级*(INT(玩家当前等级/20)))+玩家当前等级/2+1)））
        uint256[] memory amounts = new uint256[](12);
        {
            (
                amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]
            ) = 
            (
                1, uint256(occupation), sex, 1, _calcExperienceByLevel(1)
            );
        }
        {
            (
                amounts[5], amounts[6], amounts[7], amounts[8], amounts[9]
            ) = 
            (
                0, 0, 0, 0, 0
            );
        }
        {
            (
                amounts[10],amounts[11]
            ) = 
            (
                0, 0
            );
        }
        if(occupation == uint256(EOCCUPATION.Warrior) ){ // 战士
            (amounts[6], amounts[7], amounts[8], amounts[9]) = (30, 20, 15, 20);
        }
        if(occupation == uint256(EOCCUPATION.Mage) ){ // 法师 Mage
            (amounts[6], amounts[7], amounts[8], amounts[9]) = (15, 20, 30, 20);
        }
        if(occupation == uint256(EOCCUPATION.Archer)){ // 弓手 Archer
            (amounts[6], amounts[7], amounts[8], amounts[9]) = (20, 30, 20, 15);
        }
        return amounts;
    }

    function _getInitAttributeTexts(string memory name) pure internal returns(bytes[] memory) {
        bytes[] memory texts = new bytes[](12);
        {(
            texts[0], texts[1], texts[2], texts[3], texts[4]
        ) = 
        (
            bytes(name), bytes(""), bytes(""), bytes(""), bytes("")
        );}
        {(
            texts[5], texts[6], texts[7], texts[8], texts[9]
        ) = 
        (
            bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
        );}
        {(
            texts[10],texts[11]
        ) = 
        (
            bytes(""), bytes("")
        );}
        return texts;
    }

    function _calcExperienceByLevel(uint256 level) pure internal returns(uint256 experience) {
        //玩家当前等级经验=INT（（ROUND((玩家当前等级^3*0.004)+玩家当前等级*INT(玩家当前等级*0.02)+玩家当前等级*2+10,0)）*（INT((玩家当前等级^3*0.0003+玩家当前等级^2*0.002+玩家当前等级*(INT(玩家当前等级/20)))+玩家当前等级/2+1)））
        // (玩家当前等级^3*0.004)+玩家当前等级*INT(玩家当前等级*0.02)+玩家当前等级*2+10
        uint256 splitOne = 4 * (level ** 3) / 1000 + level * 2 / 100 + level * 2 + 10;
        uint256 splitTwo = level ** 3 * 3 / 10000 + level ** 2 * 2 / 1000 + level * level / 20 + level / 2 + 1;
        experience = splitOne * splitTwo;
    }
}
