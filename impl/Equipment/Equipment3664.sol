// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";
import "../../utils/Strings.sol";

contract Equipment3664 is DirectoryBridge, ERC3664Upgradeable, IEquipment {
    
    using Strings for uint256;

    mapping(uint256 => mapping(uint256 => uint256)) _rareAttributeValues; // rare => attrId => value
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
        _initRareAttributeValue();

    }

    function initRareAttributeValue(uint256 rare, uint256 attrId, uint256 attrValue) external onlyOwner {
        _rareAttributeValues[rare][attrId] = attrValue;
    }

    function _initRareAttributeValue() internal {
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 18;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 18;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 18;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 18;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 88;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 88;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.HP_BONUS)] = 176;
        _rareAttributeValues[0][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 18;

        _rareAttributeValues[1][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 22;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 22;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 22;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 22;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 110;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 110;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.HP_BONUS)] = 220;
        _rareAttributeValues[1][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 110;

        _rareAttributeValues[2][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 26;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 26;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 26;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 26;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 132;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 132;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.HP_BONUS)] = 264;
        _rareAttributeValues[2][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 132;

        _rareAttributeValues[3][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 31;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 31;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 31;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 31;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 154;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 154;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.HP_BONUS)] = 308;
        _rareAttributeValues[3][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 154;

        _rareAttributeValues[4][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 35;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 35;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 35;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 35;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 176;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 176;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.HP_BONUS)] = 352;
        _rareAttributeValues[4][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 176;

        _rareAttributeValues[5][uint256(EQUIPMENTATTR.STRENGTH_BONUS)] = 40;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.DEXTERITY_BONUS)] = 40;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS)] = 40;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.PATIENCE_BONUS)] = 40;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.ATTACK_BONUS)] = 198;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.DEFENSE_BONUS)] = 198;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.HP_BONUS)] = 396;
        _rareAttributeValues[5][uint256(EQUIPMENTATTR.SPEED_BONUS)] = 198;

    }

    function getAmountByTokenIdList(uint256[] memory equipmentList) public view returns (uint256 _ce) {
        (uint256 _strength, uint256 _dexterity, uint256 _intelligence, uint256 _patience) = (0, 0, 0, 0);
        (uint256 _dps, uint256 _atk, uint256 _def, uint256 _hp) = (0, 0, 0, 0);
        {
            for(uint256 i = 0; i < equipmentList.length; i++){
                _strength = _strength + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.STRENGTH_BONUS));
                _dexterity = _dexterity + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.DEXTERITY_BONUS));
                _intelligence = _intelligence + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS));
                _patience = _patience + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.PATIENCE_BONUS));
                _dps = _dps + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.SPEED_BONUS));
                _atk = _atk + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.ATTACK_BONUS));
                _def = _def + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.DEFENSE_BONUS));
                _hp = _hp + balanceOf(equipmentList[i], uint256(EQUIPMENTATTR.HP_BONUS));
            }
        }
        _ce = (_atk + _dps + _hp + _def) * 2 + (_strength + _dexterity + _intelligence + _patience) * 4;
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
        bytes[] memory texts = new bytes[](22);
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
                texts[15],texts[16],texts[17],texts[18],texts[19] ,texts[20],texts[21]  
            )  = 
            (
                bytes(""), bytes(""), bytes(""), bytes(""), bytes(""),bytes(""),bytes("")
            );
        }
        return texts;
    }
    
    //todo: 此处需要进行调整；
    function _getInitAttributeAmounts(uint256 tokenId, uint256 position, uint256 level, uint256 rarity, uint256 suitId) internal view returns(uint256[] memory){
        // 1、根据稀有度确定需要设置的属性；
        // 2、根据等级计算属性的值，有加成的计算；
        uint256[] memory attrs = new uint256[](8);
        {   
            (
                attrs[0],attrs[1],attrs[2],attrs[3],attrs[4],attrs[5],attrs[6],attrs[7]
            )  = 
            (
                uint256(EQUIPMENTATTR.STRENGTH_BONUS),     uint256(EQUIPMENTATTR.DEXTERITY_BONUS), 
                uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), uint256(EQUIPMENTATTR.PATIENCE_BONUS), 
                uint256(EQUIPMENTATTR.ATTACK_BONUS),       uint256(EQUIPMENTATTR.DEFENSE_BONUS), 
                uint256(EQUIPMENTATTR.SPEED_BONUS),        uint256(EQUIPMENTATTR.HP_BONUS)
            ); 
        }       
        uint256 rarityIndex = rarity + 1;
        uint256[] memory indexes = new uint256[](rarityIndex);
        {
            for(uint256 i = 0; i < indexes.length; i++){
                // uint256(keccak256(abi.encodePacked(tokenId, i)))
                indexes[i] = _getRandom(uint256(keccak256(abi.encodePacked(tokenId, i))).toString()) % attrs.length;
                //indexes[i] = _getRandom(uint256(i).toString()) % attrs.length;
            }
        }

        //uint256 basePower = uint256(10 * (125 ** level) / (100 ** level));
        //uint256 randPower = uint256(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));
        //uint256 attrValue = basePower + randPower;

        uint256[] memory amounts = new uint256[](22);
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
            // 武器的加成属性，需要按照随机值设定
            (
                amounts[15],amounts[16],amounts[17],amounts[18],amounts[19],amounts[20],amounts[21]    
            )  = 
            (
                0, 0, 0, 0, 0, 0, 0
            );
        }

        {
            for(uint256 n = 0; n < indexes.length; n++){
                uint256 attrIndex = attrs[indexes[n]];
                uint256 attrValue = _rareAttributeValues[rarity][attrIndex];
                amounts[attrIndex] = attrValue / indexes.length;
            }
        }
        return amounts;
    }
    
    function _getInitAttributeAttrIds() internal pure returns(uint256[] memory){
        uint256[] memory attrIds = new uint256[](22);
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
                uint256(EQUIPMENTATTR.PATIENCE_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS) 
                
            );
        }
        { 
            (
                attrIds[15],attrIds[16],attrIds[17],attrIds[18],attrIds[19],attrIds[20],attrIds[21]
            )  = 
            (
                uint256(EQUIPMENTATTR.DEXTERITY_BONUS), uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), 
                uint256(EQUIPMENTATTR.PATIENCE_BONUS), uint256(EQUIPMENTATTR.ATTACK_BONUS), 
                uint256(EQUIPMENTATTR.DEFENSE_BONUS), uint256(EQUIPMENTATTR.SPEED_BONUS),
                uint256(EQUIPMENTATTR.HP_BONUS)
            );
        }
        return attrIds;
    }

    function _getRandom(string memory purpose) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
    }
}
