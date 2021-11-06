// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";

contract Equipment is ERC3664Upgradeable, ERC721EnumerableUpgradeable, IEquipment, DirectoryBridge {
	
    mapping(uint256 => uint256[]) _characterEquipments;         // characterId => []equipmentId
    mapping(uint256 => mapping(string => string)) _extendAttr;  // 
    mapping(uint256 => uint256) _equipmentCharacters;           // equipmentId => characterId
    mapping(uint32 => address) _suitFlag;                       // check suit is exists
    mapping(uint256 => bool) _nameFlag;                         // parts name is exists

    uint256 public _totalToken;

    function initialize() public initializer {
        __ERC3664_init();
        __ERC721Enumerable_init("Utopia Equipment Token", "UET");
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
    function mintBatchEquipment(address recipient, uint256 characterId, uint8 maxPosition) external onlyDirectory {
        for(uint256 i = 0; i < maxPosition; i++) {
            _mintEquipmentWithCharacter(recipient, characterId, i);
        }
    }

    // @dev 创建装备，为指定角色创建指定位置的装备
    function mintEquipment(address recipient, uint256 characterId, uint8 position) external onlyDirectory {
        _mintEquipmentWithCharacter(recipient, characterId, position);
    }

    function _mintEquipmentWithCharacter(address recipient, uint256 characterId, uint8 position) internal {
        ICharacter character = ICharacter(getAddress(CONTRACT_TYPE.CHARACTER));
        require(character.exists(characterId), "characterId not exists");
        require(character.ownerOf(characterId) == tx.origin, "characterId !owner");
        uint256 tokenId = _mintEquipment(recipient, position, "", 0, 0, 1);
        _characterEquipments[characterId].push(tokenId);
        _equipmentCharacters[tokenId] = characterId;
        emit NewEquipment(recipient, characterId, tokenId);
    }

    function _mintEquipment(address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal view returns(uint256 tokenId) {
        uint256 tokenId = ++_totalToken;
        _safeMint(recipient, tokenId);
        _initAttribute(tokenId, position, name, suitId, rarity, level);
        return tokenId;
    }

    // @dev 创建幸运石
    function mintLuckStone(address recipient) external onlyDirectory {
        _mintEquipment(recipient, 99, "Luck Stone", 0, 0, 1);
    }

    function isLucklyStone(uint256 tokenId) public view override returns (bool) {
        uint256 position, _ = getAttr(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
        return position == 99;
    }

    // @dev 随机创建装备，为指定角色创建指定位置的装备
    // position: random
    function mintRandomEquipment(address recipient, uint8 position) external onlyDirectory {
        // 1、随机创建装备，各项数据具有一定的随机性；
        // 2、随机逻辑参考 _getRandom(); 函数
        // 思考：属性中需要随机的部分，要参考 _partsInfo 进行对比
        // create random number and plus lucky number on msg.sender
        IEverLight everLight = IEverLight(getAddress(CONTRACT_TYPE.EVER_LIGHT));
        uint256 luckNum = _getRandom(uint256(position).toString()) % everLight.queryPartsCount();
        /*if (luckNum >= _partsInfo._partsCount[position]) {
          luckNum = _partsInfo._partsCount[position] - 1;
        }*/

        // find the parts on position by lucky number
        //tokenId = ++_config._currentTokenId;
        for(uint8 rare = 0; rare < 256; ++rare) {
            if (luckNum >= character.queryPartsTypeCount(position, rare)) {
                luckNum -= character.queryPartsTypeCount(position, rare);
                continue;
            }

            // calc rand power by base power and +10%
            uint32 randPower = uint32(everLight.queryPower(position, rare) <= 10 ?
                                    _getRandom(uint256(256).toString()) % 1 :
                                    _getRandom(uint256(256).toString()) % (everLight.queryPower(position, rare) / 10));


            // create token information
            //_tokenList[tokenId] = LibEverLight.TokenInfo(tokenId, /*tx.origin,*/ position, rare, _partsInfo._partsTypeList[position][rare][luckNum]._name,
            //                                           _partsInfo._partsTypeList[position][rare][luckNum]._suitId, 
            //                                           _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);
            uint32 suitId, string memory suitName = character.queryPartsType(position, rare, luckNum);
            _mintEquipment(recipient, position, suitName, suitId, rare, 1);
            break;
        }

        // clear lucky value on msg.sender, only used once
        // todo: 此处还未使用角色上的幸运值，考虑是否加上
        //_accountList[tx.origin]._luckyNum = 0;
    }

    // @dev 销毁指定ID的装备
    function burnEquipment(uint256 tokenId) external onlyDirectory {
        // 1.销毁指定的 tokenId，对应属性信息也删除
        // 2.与角色的绑定关系也需要删除
        require(exists(tokenId), "!exists");
        require(ownerOf(tokenId) == tx.origin, "!owner");
        _burn(tokenId); // burn 721, not 3664
    }

    // @dev 查看套装ID的所有者
    function querySuitOwner(uint32 suitId) public view override returns (address) {
       return _suitFlag[suitId];
    }

    // @dev 查看装备名称是否被使用
    function isNameExist(string memory name) public view override returns (bool) {
        return _nameFlag[uint256(keccak256(abi.encodePacked(name)))];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getEquipmentList(uint256 characterId) public view override returns (uint256[] memory) {
        return _characterEquipments[characterId];
    }

    function getBatchAttr(uint256 tokenId, uint256[] memory attrs) public view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }

    function getAttr(uint256 tokenId, uint256 attrId) public view override returns (uint256, string memory) {
        require(_exists(tokenId), "Token not exist");
        return (balanceOf(tokenId, attrId), string(textOf(tokenId, attrId)));
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
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

    function wear(uint256 characterId, uint256[] memory tokenId) external {
        ICharacter character = ICharacter(getAddress(uint256(CONTRACT_TYPE.CHARACTER)));
        require(tokenId.length > 0, "empty equipment");
        require(character.exists(characterId), "!exists");
        require(character.isApprovedOrOwner(_msgSender(), characterId), "Not owner or approver");

        uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_LEVEL), uint256(CHARACTERATTR.CHARACTER_SEX), 
                                    uint256(CHARACTERATTR.CHARACTER_OCCUPATION), uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                                    uint256(CHARACTERATTR.CHARACTER_DEXTERITY), uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_CONSTITUTION)];
        
        uint256[] memory characterAttrs = character.getBatchAttr(characterId, attrIds);
        for (uint i = 0; i < tokenId.length; ++i) {
            require(_isApprovedOrOwner(_msgSender(), tokenId[i]), "Not owner or approver");

            putOnOne(characterId, characterAttrs, tokenId[i]);
        }
    }

    // 使用归属关系的变化，来确定tokenId是否存在
    function putOnOne(uint256 characterId, uint256[] memory characterAttrs, uint256 tokenId) internal {
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                                    uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
                                    uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT),
                                    uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION)];
        uint256[] memory limitValue = balanceOfBatch(tokenId, attrIds);
        //require(canPutOn(characterAttrs, limitValue), "Limited to put on");
        uint256 position = limitValue[7];
        // 角色对应的装备列表，数组的下标就是 position 的位置
        uint256[] storage equipmentList = _characterEquipments[characterId];
        if (equipmentList.length = 0) {
            //todo: 此处的配置信息需要去configuration获取
            equipmentList = new uint256[](Genesis.MAX_EQUIPMENT);
        }

        if (equipmentList[position] != 0) {
            _transfer(address(this), _msgSender(), equipmentList[position]);
        }

        _transfer(_msgSender(), address(this), tokenId);
        equipmentList[position] = tokenId;
        _equipmentCharacters[tokenId] = characterId;
    }

    function takOff(uint256 characterId, uint256[] tokenId) external {
        require(tokenId.length > 0, "empty tokenId list");
        ICharacter character = ICharacter(getAddress(uint256(CONTRACT_TYPE.CHARACTER)));
        require(character.exists(characterId), "characterId not exists");
        require(character.isApprovedOrOwner(_msgSender(), characterId), "Not owner or approver");

        for (uint256 i = 0; i < tokenId.length; ++i) {
            // 装备在身上时，装备的所有者为合约，装备独立存在时，所有者为用户
            require(_isApprovedOrOwner(address(this), tokenId[i]), "Not owner or approver");
            takeOffOne(characterId, tokenId[i]);
        }
    }

    function takeOffOne(uint256 characterId, uint256 tokenId) internal {
        uint256 position = balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
        uint256[] storage equipmentList = _characterEquipments[characterId];

        require(equipmentList.length == Genesis.MAX_EQUIPMENT, "No equipment found");
        require(equipmentList[position] == tokenId, "No equipment found");

        equipmentList[position] = 0;
        _transfer(address(this), _msgSender(), tokenId);
    }

    // @dev 装备升级
    function upgradeToken(uint256 firstTokenId, uint256 secondTokenId) external {
  
        require(ownerOf(firstTokenId) == _msgSender(), "first !owner");
        require(ownerOf(secondTokenId) == _msgSender(), "second !owner");
        require(_exists(firstTokenId), "first !exists");
        require(_exists(secondTokenId), "first !exists");

        // 校验两个装备的部分属性（名称、等级、稀有度、位置等）
        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), uint256(EQUIPMENTATTR.EQUIPMENT_SUITID)];
        uint256[] memory firstAttrAmount = balanceOfBatch(firstTokenId, attrIds);
        uint256[] memory secondAttrAmount = balanceOfBatch(secondTokenId, attrIds);

        // check pats can upgrade
        //require(keccak256(bytes(_tokenList[firstTokenId]._name)) == keccak256(bytes(_tokenList[secondTokenId]._name)), "!name");
        require(firstAttrAmount[2] == secondAttrAmount[2], "!position");
        require(firstAttrAmount[3] == secondAttrAmount[3], "!level");
        require(firstAttrAmount[4] == secondAttrAmount[4], "!rare");
        require(firstAttrAmount[3] < 9, "exceed max level");
        
        // basepower = (basepower * 1.25 ** level) * +1.1
        // 查看预先定义的稀有度与power的关系 position => rare => power ，该配置从 EverLight 合约获取
        IEverLight everLight = IEverLight(getAddress(CONTRACT_TYPE.EVER_LIGHT));
        uint32 basePower = everLight.queryPower(firstAttrAmount[2], firstAttrAmount[4]);

        //todo: 此处的算力值还未进行有效的赋值，需要进行处理
        basePower = uint32(basePower * (125 ** (firstAttrAmount[3] - 1)) / (100 ** (firstAttrAmount[3] - 1)));
        uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

        // 装备合成，原有装备销毁，生成新的装备
        string memory name = textOf(firstTokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME));
        //uint256 tokenId = ++_totalToken;
        //_safeMint(_msgSender(), tokenId);
        // uint256 tokenId, uint256 position, string memory name, uint256 suitId, uint256 rarity
        //_initAttribute(tokenId, firstAttrAmount[2], name, firstAttrAmount[5], firstAttrAmount[4], firstAttrAmount[3]);
        _mintEquipment(_msgSender(), firstAttrAmount[2], name, firstAttrAmount[5], firstAttrAmount[4], firstAttrAmount[3]);

        // remove old token
        _burn(firstTokenId);
        _burn(secondTokenId);

        delete _equipmentCharacters[firstTokenId];
        delete _equipmentCharacters[secondTokenId];
    }

    // @dev 升级身上已穿的装备
    function upgradeWearToken(uint256 characterId, uint256 tokenId) external {
        ICharacter character = ICharacter(getAddress(CONTRACT_TYPE.CHARACTERATTR));
        require(character.ownerOf(characterId) == _msgSender(), "character !owner");
        require(ownerOf(tokenId) == _msgSender(), "equipment !owner");

        uint256[] memory attrIds = [uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), 
                                    uint256(EQUIPMENTATTR.EQUIPMENT_SUITID)];
        
        uint256[] memory newTokenAttrAmount = balanceOfBatch(tokenId, attrIds);
        
        //uint8 position = _tokenList[tokenId]._position;
        //uint256 partsId = _characterList[characterId]._tokenList[position];
        uint256 wearedEquipmentId = _characterEquipments[characterId][newTokenAttrAmount[1]];

        uint256[] memory oldTokenAttrAmount = balanceOfBatch(wearedEquipmentId, attrIds);

        // check pats can upgrade
        require(keccak256(textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))) == keccak256(textOf(wearedEquipmentId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))), "!token");
        require(newTokenAttrAmount[2] == oldTokenAttrAmount[2], "!level");
        require(newTokenAttrAmount[3] == oldTokenAttrAmount[3], "!rare");
        require(newTokenAttrAmount[2] < 9, "Max level");

        // todo: 此处对于新装备的算力值待定
        IEverLight everLight = IEverLight(getAddress(CONTRACT_TYPE.EVER_LIGHT));
        uint32 basePower = everLight.queryPower(oldTokenAttrAmount[1], oldTokenAttrAmount[3]);

        // basepower = (basepower * 1.25 ** level) * +1.1
        //uint32 basePower = _partsInfo._partsPowerList[position][_tokenList[partsId]._rare];
        basePower = uint32(basePower * (125 ** (oldTokenAttrAmount[2] - 1)) / (100 ** (oldTokenAttrAmount[2] - 1)));
        uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

        // 创造新的装备，同时默认穿在角色身上
        // address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level
        uint256 newTokenId = _mintEquipment(_msgSender(), oldTokenAttrAmount[1], string(wearedEquipmentId(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))), 
                        oldTokenAttrAmount[4], firstAttrAmount[3], firstAttrAmount[2] + 1);
        
        _transfer(_msgSender(), address(this), newTokenId);

        _characterEquipments[characterId][oldTokenAttrAmount[1]] = newTokenId;

        // remove old parts
        _burn(tokenId);
        delete _equipmentCharacters[tokenId];
    }

    // @dev 创建装备
    function newTokenType(uint256 tokenId, string memory name, uint32 suitId) external override {
        require(bytes(name).length <= 16, "Error name");
        require(ownerOf(tokenId) == _msgSender(), "!owner");
        require(!_nameFlag[nameFlag], "Error name");

        require(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL)) == 9, "level != 9");
        require(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED)) == 1, "createFlag=true|1");
        
        // create new parts type
        uint8 position = balanceOf(tokenId, EQUIPMENTATTR.EQUIPMENT_POSITION);
        uint8 rare = balanceOf(tokenId, EQUIPMENTATTR.EQUIPMENT_RARITY) + 1;
        
        IEverLight everLight = IEverLight(getAddress(CONTRACT_TYPE.EV));
        //require(_partsInfo._partsPowerList[position][rare] > 0, "Not open");
        require(everLight.queryPower(position, rare) > 0, "Not open");
        
        if (suitId == 0) {
            suitId = everLight.querySuitNum() + 1;
            //everLight.increaseSuitNum();
            addNewSuit(suitId, name, position, rare);
            _suitFlag[suitId] = tx.origin;
        } else {
            require(_suitFlag[suitId] == tx.origin, "Not own the suit");
        }

        // 调用EL接口，保存新的套装数据，以下部分代码调用接口完成
        //_partsInfo._partsTypeList[position][rare].push(LibEverLight.SuitInfo(name, suitId));
        //_partsInfo._partsCount[position] = _partsInfo._partsCount[position] + 1;
        //_partsInfo._nameFlag[nameFlag] = true;
        //emit NewTokenType(tx.origin, position, rare, name, suitId);

        // create 3 new token for creator
        for (uint i = 0; i < 3; ++i) {
          // todo: 此处的算力用处待定，还没有结论
            uint32 randPower = uint32(everLight.queryPower(position, rare) < 10 ?
                                    _getRandom(uint256(256).toString()) % 1 :
                                    _getRandom(uint256(256).toString()) % (everLight.queryPower(position, rare) / 10));

            // _mintEquipment(address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level)
            _mintEquipment(_msgSender(), position, name, suitId, rare, 1);

            // create token information
            //_tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin, */position, rare, name, suitId, 
            //                                            _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);

            //_erc721Proxy.mintBy(tx.origin, newTokenId);
        }

        // 原来的装备状态需要进行变更，9级装备的状态需要改变
        _attach(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED), 1, "", false);

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

    function _initAttribute(uint256 tokenId, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal {
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
        
        //uint256[] memory values = database.getBatchAttr(equipmentId, attrIds);
        uint256[] memory amounts = [tokenId, 0, position, level, rarity, suitId, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

        bytes[] memory texts = ["", name, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];

        _batchAttach(tokenId, attrIds, amounts, texts);
    }

    function _getRandom(string memory purpose) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
    }
}
