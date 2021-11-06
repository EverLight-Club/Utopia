// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";
import "./IEquipmentDB.sol";

contract Equipment is ERC3664Upgradeable, ERC721EnumerableUpgradeable, IEquipment, DirectoryBridge {
	
    mapping(uint256 => uint256[]) _characterEquipments;
    mapping(uint256 => mapping(string => string)) _extendAttr;
    uint256 _totalToken;

    function initialize() public initializer {
        __ERC3664_init();
        __ERC721Enumerable("Utopia Equipment Token", "UET");
        __DirectoryBridge_init();
        __Equipment_init_unchained();
	}

    function __Equipment_init_unchained() internal initializer {
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_SUITID), uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS), uint256(EQUIPMENTATTR.DEXTERITY_BONUS),
                                    uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), uint256(EQUIPMENTATTR.CONSTITUTION_BONUS), uint256(EQUIPMENTATTR.ATTACK_BONUS), uint256(EQUIPMENTATTR.DEFENSE_BONUS), uint256(EQUIPMENTATTR.SPEED_BONUS)];
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

    // @dev 批量创建装备（对于新角色，进行初始化创建时调用该接口）
    function batchMintEquipment(address recipient, uint256 characterId, uint8 maxPosition) external onlyDirectory {
        // 1、指定角色创建装备，本合约需要维护角色与装备的关系；
        // 2、每个position对应的装备 tokenId 需要进行保存；
        // 3、每个装备的算力值需要体现到装备属性中去；
        // 4、思考：幸运石的加成，是否由调用方传入，幸运石管控在 EverLight 合约中;
    }

    // @dev 创建装备，为指定角色创建指定位置的装备
    function mintEquipment(address recipient, uint256 characterId, uint8 position) external onlyDirectory {
        // 1、记录新装备与角色关系；
        // 2、记录新装备与处于的位置；
        // 3、新装备的属性按默认值处理；
        // 注意：装备的特有属性或者加成的处理需要进行考虑；
    }

    // @dev 创建幸运石
    function mintLuckStone(address recipient) external onlyDirectory {
        
    }

    function isLucklyStone(uint256 tokenId) external view override returns (bool) {
        return true;
    }

    // @dev 随机创建装备，为指定角色创建指定位置的装备
    function mintRandomEquipment(address recipient) external onlyDirectory {
        // 1、随机创建装备，各项数据具有一定的随机性；
        // 2、随机逻辑参考 _getRandom(); 函数
    }

    // @dev 销毁指定ID的装备
    function burnEquipment(uint256 tokenId) external onlyDirectory {
        // 1.销毁指定的 tokenId，对应属性信息也删除
        // 2.与角色的绑定关系也需要删除
    }

    // 思考：套装的数据存储在何处
    function querySuitOwner(uint32 suitId) external view override returns (address) {
        //todo: 调用DB的接口查询
        return 0x0;
    }

    function isNameExist(string memory name) external view override returns (bool) {
        //todo: 调用DB接口查询
        //return _partsInfo._nameFlag[uint256(keccak256(abi.encodePacked(name)))];
        return true;
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view virtual returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getEquipmentList(uint256 characterId) external view override returns (uint256[] memory) {
        return _characterEquipments[characterId];
    }

    function getEquipments(address owner) external view override returns (uint256[] memory) {
        if (owner == address(0)) {
            owner = _msgSender();
        }
        
        uint256 balance = balanceOf(owner);
        uint256[] result = new uint256[](balance);

        for (uint256 i=0; i<balance; ++i) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function getEquipmentAttr(uint256 tokenId, uint256[] memory attrs) external view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function getOriginExtendAttr(uint256 tokenId, string memory key) external view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");

        IEquipmentDB database = IEquipmentDB(getAddress(uint256(CONTRACTTYPE.EQUIPMENTDB)));
        return database.getExtendAttr(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_ID)), key);
    }

    function equipmentBouns(uint256 characterId, uint256[] memory attrIds) external view override returns (uint256[] memory) {
        require(attrIds.length > 0, "Empty attributes");

        uint256[] memory bonus = new uint256[](attrids.length);
        uint256[] storage equipmentList = _characterEquipments[characterId];
        for (uint i=0; i<equipmentList.length; ++i) {
            if (equipmentList[i] == 0) {
                continue;
            }

            uint256[] memory bonusValue = balanceOfBatch(equipmentList[i], attrIds);
            for (uint j=0; j<attrIds.length; ++j) {
                bonus[j] += bonusValue[j];
            }
        }

        return bonus;
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external onlyDirectory {
        _extendAttr[tokenId][key] = value;
    }

    function claim(address to, uint256 equipmentId) external onlyDirectory {
        uint256 tokenId = ++_totalToken;
        _safeMint(to, tokenId);

        _initAttribute(tokenId, equipmentId);

        emit NewEquipment(to, tokenId, equipmentId);
    }

    function putOn(uint256 characterId, uint256[] memory tokenId) external {
        ICharacter character = ICharacter(getAddress(uint256(CONTRACTTYPE.CHARACTER)));
        require(character.isApprovedOrOwner(_msgSender(), characterId), "Not owner or approver");

        uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_LEVEL), uint256(CHARACTERATTR.CHARACTER_SEX), 
                                    uint256(CHARACTERATTR.CHARACTER_OCCUPATION), uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                                    uint256(CHARACTERATTR.CHARACTER_DEXTERITY), uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_CONSTITUTION)];
        
        uint256[] memory characterAttrs = character.getBatchAttr(characterId, attrIds);
        for (uint i=0; i<tokenId.length; ++i) {
            require(_isApprovedOrOwner(_msgSender(), tokenId[i]), "Not owner or approver");

            putOnOne(characterId, characterAttrs, tokenId[i]);
        }
    }

    function takOff(uint256 characterId, uint256[] tokenId) external {
        ICharacter character = ICharacter(getAddress(uint256(CONTRACTTYPE.CHARACTER)));
        require(character.isApprovedOrOwner(_msgSender(), characterId), "Not owner or approver");

        for (uint i=0; i<tokenId.length; ++i) {
            require(_isApprovedOrOwner(address(this), tokenId[i]), "Not owner or approver");

            takeOffOne(characterId, tokenId[i]);
        }
    }

    function putOnOne(uint256 characterId, uint256[] memory characterAttrs, uint256 tokenId) internal {
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                                    uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT),
                                    uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION)];
        uint256[] memory limitValue = balanceOfBatch(tokenId, attrIds);
        require(canPutOn(characterAttrs, limitValue), "Limited to put on");

        uint256[] storage equipmentList = _characterEquipments[characterId];
        if (equipmentList.length = 0) {
            equipmentList = new uint256[](Genesis.MAX_EQUIPMENT);
        }

        if (equipmentList[limitValue[7]] != 0) {
            _transfer(address(this), _msgSender(), equipmentList[limitValue[7]]);
        }

        _transfer(_msgSender(), address(this), tokenId);
        equipmentList[limitValue[7]] = tokenId;
    }

    function takeOffOne(uint256 characterId, uint256 tokenId) internal {
        uint256 position = balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
        uint256[] storage equipmentList = _characterEquipments[characterId];

        require(equipmentList.length == Genesis.MAX_EQUIPMENT, "No equipment found");
        require(equipmentList[position] == tokenId, "No equipment found");

        equipmentList[position] = 0;
        _transfer(address(this), _msgSender(), tokenId);
    }

    function canPutOn(uint256[] memory characterAttrs, uint256[] memory limitValue) internal return (bool) {
        if (characterAttrs[0] < limitValue[0]) return false;
        if (characterAttrs[1] != limitValue[1]) return false;
        if (characterAttrs[2] != limitValue[2]) return false;
        if (characterAttrs[3] < limitValue[3]) return false;
        if (characterAttrs[4] < limitValue[4]) return false;
        if (characterAttrs[5] < limitValue[5]) return false;
        if (characterAttrs[6] < limitValue[6]) return false;

        return true;
    }

    function _initAttribute(uint256 tokenId, uint256 equipmentId) internal {
        IEquipmentDB database = IEquipmentDB(getAddress(uint256(CONTRACTTYPE.EQUIPMENTDB)));
        require(database._exists(equipmentId), "Equipment not exist");
        
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
        uint256[] memory values = database.getBatchAttr(equipmentId, attrIds);
        (, string memory name) = database.getAttr(equipmentId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME));
        bytes[] memory texts = ["", name, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];

        values[0] = equipmentId;
        values[3] = 1;
        _batchAttach(tokenId, attrIds, amounts, texts);
    }
}
