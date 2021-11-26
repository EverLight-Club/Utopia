// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";

contract Equipment3664 is DirectoryBridge, ERC3664Upgradeable, IEquipment {
    
    mapping(uint256 => mapping(string => string)) _extendAttr;  // 

    uint256 public _totalToken;

    constructor() {
        initialize();
    }

    function initialize() public initializer {
        __ERC3664_init();
        __DirectoryBridge_init();
        __Equipment3664_init_unchained();
    }

    function __Equipment3664_init_unchained() internal initializer {
        /*uint256[] memory attrIds = new uint256[](20);
        string[] memory names = new string[](20);
        string[] memory symbols = new string[](20);
        string[] memory uris = new string[](20);
        
        (attrIds[0],attrIds[1],attrIds[2],attrIds[3],attrIds[4],attrIds[5],attrIds[6],attrIds[7],attrIds[8],attrIds[9],
        attrIds[10],attrIds[11],attrIds[12],attrIds[13],attrIds[14],attrIds[15],attrIds[16],
        attrIds[17],attrIds[18],attrIds[19] ) = (uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_SUITID), uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS), uint256(EQUIPMENTATTR.DEXTERITY_BONUS),
                                    uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), uint256(EQUIPMENTATTR.CONSTITUTION_BONUS), uint256(EQUIPMENTATTR.ATTACK_BONUS), uint256(EQUIPMENTATTR.DEFENSE_BONUS), uint256(EQUIPMENTATTR.SPEED_BONUS) );
        (names[0],names[1],names[2],names[3],names[4],
         names[5],names[6],names[7],names[8],names[9],
         names[10],names[11],names[12],names[13],names[14],
         names[15],names[16],names[17],names[18],names[19] 
        ) = ("id", "name", "position", "level", "rarity", "suit id", "level limit", "sex limit", 
                                 "occupation limit", "strength limit", "DEXTERITY limit", "intelligence limit",
                                 "CONSTITUTION limit", "strength bonus", "DEXTERITY bonus", "intelligence bonus", 
                                 "CONSTITUTION bonus", "attack bonus", "defense bonus", "speed bonus");
        (symbols[0],symbols[1],symbols[2],symbols[3],symbols[4],
         symbols[5],symbols[6],symbols[7],symbols[8],symbols[9],
         symbols[10],symbols[11],symbols[12],symbols[13],symbols[14],
         symbols[15],symbols[16],symbols[17],symbols[18],symbols[19] 
        )  = ("ID", "NAME", "POSITION", "LEVEL", "RARITY", "SUITID", "LLEVEL", "LSEX", "LOCCUPATION",
                                   "LSTRENGTH", "LDEXTERITY", "LINTELLIGENCE", "LCONSTITUTION", "BSTRENGTH", "BDEXTERITY", 
                                   "BINTELLIGENCE", "BCONSTITUTION", "BATTACK", "BDEFENSE", "BSPEED");
        (uris[0],uris[1],uris[2],uris[3],uris[4],
         uris[5],uris[6],uris[7],uris[8],uris[9],
         uris[10],uris[11],uris[12],uris[13],uris[14],
         uris[15],uris[16],uris[17],uris[18],uris[19] 
        )  = ("", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "");
        _mintBatch(attrIds, names, symbols, uris);*/
    }

    function attach(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount,
        bytes memory text,
        bool isPrimary
    ) external onlyDirectory {
        _attach(tokenId, attrId, amount, text, isPrimary);
    }

    function mintBatch(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner {
        _mintBatch(attrIds, names, symbols, uris);
    }

    function initAttributeForEquipment(uint256 tokenId, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) external onlyDirectory {
        _initAttribute(tokenId, position, name, suitId, rarity, level);
    }

    function queryEquipmentAttrs(uint256 tokenId) external view returns(uint256[] memory balances){
        uint256[] memory attrIds = _getInitAttributeAttrIds();
        balances = new uint256[](attrIds.length);
        for(uint256 i = 0; i < attrIds.length; i++){
            balances[i] = balanceOf(tokenId, attrIds[i]);
        }
    }

    function queryEquipmentByBatch(uint256[] memory tokenIds) external view returns(uint256[] memory equipments){
        uint256[] memory attrIds = _getInitAttributeAttrIds();
        equipments = new uint256[](tokenIds.length * attrIds.length);
        uint256 index = 0;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            for(uint256 n = 0; n < attrIds.length; n++){
                equipments[index] = balanceOf(tokenIds[i], attrIds[n]);
                index++;
            }
        }
        return equipments;
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory) {
        return _extendAttr[tokenId][key];
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external onlyDirectory {
        _extendAttr[tokenId][key] = value;
    }

    function _initAttribute(uint256 tokenId, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal {
        _batchAttach(tokenId, 
            _getInitAttributeAttrIds(), 
            _getInitAttributeAmounts(tokenId, position, level, rarity, suitId), 
            _getInitAttributeTexts(name));
    }
    
    function _getInitAttributeTexts(string memory name) internal pure returns(bytes[] memory) {
        bytes[] memory texts = new bytes[](21);
        {
            (
                texts[0],texts[1],texts[2],texts[3],texts[4]
            )  = 
            (
                bytes(""), bytes(name), bytes(""), bytes(""), bytes("")
            );
            
        }
        {
            (
                texts[5],texts[6],texts[7],texts[8],texts[9]
            )  = 
            (
                bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
            );
            
        }
        {
            (
                texts[10],texts[11],texts[12],texts[13],texts[14]
            )  = 
            (
                bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
            );
        }
        {
            (
                texts[15],texts[16],texts[17],texts[18],texts[19] ,texts[20] 
            )  = 
            (
                bytes(""), bytes(""), bytes(""), bytes(""), bytes(""),bytes("")
            );
        }
        return texts;
    }
    
    function _getInitAttributeAmounts(uint256 tokenId, uint256 position, uint256 level, uint256 rarity, uint256 suitId) internal pure returns(uint256[] memory){
        uint256[] memory amounts = new uint256[](21);
        {
            (
                amounts[0],amounts[1],amounts[2],amounts[3],amounts[4]
            )  = 
            (
                tokenId, 0, position, level, rarity
            );
        }
        {
            (
                amounts[5],amounts[6],amounts[7],amounts[8],amounts[9]
            )  = 
            (
                suitId, 0, 0, 0, 0
            );
        }
        {
            (
                amounts[10],amounts[11],amounts[12],amounts[13],amounts[14]
            )  = 
            (
                0, 0, 0, 0, 0
            );
        }
        {
            (
                amounts[15],amounts[16],amounts[17],amounts[18],amounts[19],amounts[20]  
            )  = 
            (
                0, 0, 0, 0, 0, 0
            );
        }
        return amounts;
    }
    
    function _getInitAttributeAttrIds() internal pure returns(uint256[] memory){
        uint256[] memory attrIds = new uint256[](21);
        { 
            (
                attrIds[0],attrIds[1],attrIds[2],attrIds[3],attrIds[4]
            )  = 
            (
                uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), 
                uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), 
                uint256(EQUIPMENTATTR.EQUIPMENT_RARITY)
            );
        }
        { 
            (
                attrIds[5],attrIds[6],attrIds[7],attrIds[8],attrIds[9]
            )  = 
            (
                uint256(EQUIPMENTATTR.EQUIPMENT_SUITID), uint256(EQUIPMENTATTR.EQUIPMENT_CREATED), 
                uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                uint256(EQUIPMENTATTR.OCCUPATION_LIMIT)
            );
        }
        { 
            (
                attrIds[10],attrIds[11],attrIds[12],attrIds[13],attrIds[14]
            )  = 
            (
                uint256(EQUIPMENTATTR.STRENGTH_LIMIT), uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), 
                uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), 
                uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS) 
                
            );
        }
        { 
            (
                attrIds[15],attrIds[16],attrIds[17],attrIds[18],attrIds[19],attrIds[20]
            )  = 
            (
                uint256(EQUIPMENTATTR.DEXTERITY_BONUS), uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), 
                uint256(EQUIPMENTATTR.CONSTITUTION_BONUS), uint256(EQUIPMENTATTR.ATTACK_BONUS), 
                uint256(EQUIPMENTATTR.DEFENSE_BONUS), uint256(EQUIPMENTATTR.SPEED_BONUS)
            );
        }
        return attrIds;
    }

    function _getRandom(string memory purpose) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
    }
}
