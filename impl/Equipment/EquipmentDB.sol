// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../../utils/OwnableUpgradeable.sol";
import "../../interfaces/IEquipment.sol";
import "./IEquipmentDB.sol";

contract EquipmentDB is ERC3664Upgradeable, ERC721EnumerableUpgradeable, IEquipmentDB, OwnableUpgradeable {

    mapping(uint256 => mapping(string => string)) _extendAttr;
    uint256 _totalToken;

    function initialize() public initializer {
        __ERC3664_init_unchained();
        __ERC721Enumerable_init_unchained("Utopia Equipment DB", "UED");
        __Ownable_init_unchained();
        __EquipmentDB_init_unchained();
	}

    function __EquipmentDB_init_unchained() internal initializer {
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), uint256(EQUIPMENTATTR.EQUIPMENT_SUITID), 
                                    uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                                    uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), 
                                    uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_BONUS), uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), 
                                    uint256(EQUIPMENTATTR.CONSTITUTION_BONUS), uint256(EQUIPMENTATTR.ATTACK_BONUS), 
                                    uint256(EQUIPMENTATTR.DEFENSE_BONUS), uint256(EQUIPMENTATTR.SPEED_BONUS)];
        string[] memory names = ["id", "name", "position", "level", "rarity", "suit id", "level limit", "sex limit", 
                                 "occupation limit", "strength limit", "DEXTERITY limit", "intelligence limit",
                                 "CONSTITUTION limit", "strength bonus", "DEXTERITY bonus", "intelligence bonus", 
                                 "CONSTITUTION bonus", "attack bonus", "defense bonus", "speed bonus"];
        string[] memory symbols = ["ID", "NAME", "POSITION", "LEVEL", "RARITY", "SUITID", "LLEVEL", "LSEX", "LOCCUPATION",
                                   "LSTRENGTH", "LDEXTERITY", "LINTELLIGENCE", "LCONSTITUTION", "BSTRENGTH", "BDEXTERITY", 
                                   "BINTELLIGENCE", "BCONSTITUTION", "BATTACK", "BDEFENSE", "BSPEED"];
        string[] memory uris = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];
        _mintBatch(attrIds, names, symbols, uris);
    }

    function getAttr(uint256 tokenId, uint256 attrId) external view override returns (uint256, string memory) {
        require(_exists(tokenId), "Token not exist");
        return (balanceOf(tokenId, attrId), string(textOf(tokenId, attrId)));
    }

    function getBatchAttr(uint256 tokenId, uint256[] memory attrId) external view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function getBaseAttr(uint256 tokenId) external view override returns (uint256, string memory, uint256, uint256, uint256, uint256) {
        require(_exists(tokenId), "Token not exist");
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), uint256(EQUIPMENTATTR.EQUIPMENT_SUITID)];
                
        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        return (currValue[0], textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME)), currValue[1], currValue[2], currValue[3], currValue[4]);
    }

    function getLimitAttr(uint256 tokenId) external view override returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        require(_exists(tokenId), "Token not exist");
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                                    uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), 
                                    uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT)];
                
        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        return (currValue[0], currValue[1], currValue[2], currValue[3], currValue[4], currValue[5], currValue[6]);
    }

    function getBonusAttr(uint256 tokenId) external view override returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        require(_exists(tokenId), "Token not exist");
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.STRENGTH_BONUS), uint256(EQUIPMENTATTR.DEXTERITY_BONUS), 
                                    uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), uint256(EQUIPMENTATTR.CONSTITUTION_BONUS), 
                                    uint256(EQUIPMENTATTR.ATTACK_BONUS), uint256(EQUIPMENTATTR.DEFENSE_BONUS), 
                                    uint256(EQUIPMENTATTR.SPEED_BONUS)];
                
        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        return (currValue[0], currValue[1], currValue[2], currValue[3], currValue[4], currValue[5], currValue[6]);
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        _extendAttr[tokenId][key] = value;
    }

    function addEquipment(uint256[] memory attrId, uint256[] memory values, bytes[] memory texts) external onlyOwner {
        uint256 tokenId = ++ _totalToken;
        _safeMint(address(this), tokenId);
        _batchAttach(tokenId, attrIds, values, texts);

        emit NewEquipment(_msgSender(), tokenId, textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME)));
    }

    function updateEquipment(uint256 tokenId, uint256[] memory attrId, uint256[] memory values, bytes[] memory texts) external onlyOwner {
        require(_exists(tokenId), "Token not exist");
        require(attrId.length == values.length, "Not match values");
        require(attrId.length == texts.length, "Not match values");
        require(attrId.length > 0, "Empty attributes");

        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        _burnBatch(tokenId, attrIds, currValue);

        _batchAttach(tokenId, attrIds, values, texts);
    }

    function addNewAttr(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner {
        require(attrIds.length == names.length, "Not match values");
        require(attrIds.length == symbols.length, "Not match values");
        require(attrIds.length == uris.length, "Not match values");
        require(attrIds.length > 0, "Empty attribute");

        _mintBatch(attrIds, names, symbols, uris); 
    }
}
