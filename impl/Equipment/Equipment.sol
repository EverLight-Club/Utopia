// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC721/IERC721Upgradeable.sol";
import "../../token/ERC3664Stand/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";
import "../../interfaces/ICharacter.sol";
import "../../interfaces/IEverLight.sol";
import "../../library/Genesis.sol";
import "../../utils/Strings.sol";

contract Equipment is ERC3664Upgradeable, ERC721EnumerableUpgradeable, IEquipment, DirectoryBridge {
    
    using Strings for uint256;
    
    mapping(uint256 => uint256[]) _characterEquipments;         // characterId => []equipmentId
    mapping(uint256 => mapping(string => string)) _extendAttr;  // 
    mapping(uint256 => uint256) _equipmentCharacters;           // equipmentId => characterId
    mapping(uint32 => address) _suitFlag;                       // check suit is exists
    mapping(uint256 => bool) _nameFlag;                         // parts name is exists

    uint256 public _totalToken;

    function initialize() public /*initializer*/ {
        //__ERC3664_init();
        __ERC721Enumerable_init("Utopia Equipment Token", "UET");
        __DirectoryBridge_init();
        __Equipment_init_unchained();
    }
    
    function EquipmentInit(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner initializer {
        _mintBatch(attrIds, names, symbols, uris);
    }

    function __Equipment_init_unchained() internal initializer {
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

    // @dev 批量创建装备（对于新角色，进行初始化创建时调用该接口）
    function mintBatchEquipment(address recipient, uint256 characterId, uint8 maxPosition) external onlyDirectory {
        for(uint256 i = 0; i < maxPosition; i++) {
            _mintEquipmentWithCharacter(recipient, characterId, uint8(i));
        }
    }

    // @dev 创建装备，为指定角色创建指定位置的装备
    function mintEquipment(address recipient, uint256 characterId, uint8 position) external onlyDirectory {
        _mintEquipmentWithCharacter(recipient, characterId, position);
    }

    function _mintEquipmentWithCharacter(address recipient, uint256 characterId, uint8 position) internal {
        IERC721Upgradeable character = IERC721Upgradeable(getAddress(uint32(CONTRACT_TYPE.CHARACTER)));
        //require(character.exists(characterId), "characterId not exists");
        require(character.ownerOf(characterId) == tx.origin, "characterId !owner");
        uint256 tokenId = _mintEquipment(recipient, position, "", 0, 0, 1);
        _characterEquipments[characterId].push(tokenId);
        _equipmentCharacters[tokenId] = characterId;
        emit NewEquipment(recipient, characterId, tokenId);
    }

    function _mintEquipment(address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal returns(uint256 tokenId) {
        uint256 tokenId = ++_totalToken;
        _safeMint(recipient, tokenId);
        _initAttribute(tokenId, position, name, suitId, rarity, level);
        return tokenId;
    }

    function mintLuckStone(address recipient) external onlyDirectory {
        _mintEquipment(recipient, 99, "Luck Stone", 0, 0, 1);
    }

    function isLucklyStone(uint256 tokenId) public view  returns (bool) {
        uint256 position = balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
        return position == 99;
    }

    // @dev 随机创建装备，为指定角色创建指定位置的装备
    function mintRandomEquipment(address recipient, uint8 position) external onlyDirectory {
        // create random number and plus lucky number on msg.sender
        IEverLight everLight = IEverLight(getAddress(uint32(CONTRACT_TYPE.EVER_LIGHT)));
        uint256 luckNum = _getRandom(uint256(position).toString()) % everLight.queryPartsCount(position);

        // find the parts on position by lucky number
        for(uint8 rare = 0; rare < 256; ++rare) {
            if (luckNum >= everLight.queryPartsTypeCount(position, rare)) {
                luckNum -= everLight.queryPartsTypeCount(position, rare);
                continue;
            }

            // calc rand power by base power and +10%
            //uint32 randPower = uint32(everLight.queryPower(position, rare) <= 10 ?
            //                        _getRandom(uint256(256).toString()) % 1 :
            //                        _getRandom(uint256(256).toString()) % (everLight.queryPower(position, rare) / 10));
            (uint32 suitId, string memory suitName) = everLight.queryPartsType(position, rare, luckNum);
            _mintEquipment(recipient, position, suitName, suitId, rare, 1);
            break;
        }

        // clear lucky value on msg.sender, only used once
        // todo: 此处还未使用角色上的幸运值，考虑是否加上
        //_accountList[tx.origin]._luckyNum = 0;
    }

    // @dev 销毁指定ID的装备
    function burnEquipment(uint256 tokenId) external onlyDirectory {
        require(_exists(tokenId), "!exists");
        require(ownerOf(tokenId) == tx.origin, "!owner");
        _burn(tokenId); // burn 721, not 3664
    }

    // @dev 查看套装ID的所有者
    function querySuitOwner(uint32 suitId) public view returns (address) {
       return _suitFlag[suitId];
    }

    // @dev 查看装备名称是否被使用
    function isNameExist(string memory name) public view returns (bool) {
        return _nameFlag[uint256(keccak256(abi.encodePacked(name)))];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getEquipmentList(uint256 characterId) public view returns (uint256[] memory) {
        return _characterEquipments[characterId];
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external onlyDirectory {
        _extendAttr[tokenId][key] = value;
    }

    function wear(uint256 characterId, uint256[] memory tokenId) external {
        ICharacter character = ICharacter(getAddress(uint32(CONTRACT_TYPE.CHARACTER)));
        require(tokenId.length > 0, "empty equipment");
        require(character.isApprovedOrOwner(_msgSender(), characterId), "Not owner or approver");
        
        //todo:此处未开放对与角色的校验
        //uint256[] memory attrIds = new uint256[](7);
        /*(attrIds[0],attrIds[1],attrIds[2],attrIds[3],attrIds[4],
         attrIds[5],attrIds[6]) = (uint256(CHARACTERATTR.CHARACTER_LEVEL), uint256(CHARACTERATTR.CHARACTER_SEX), 
                                    uint256(CHARACTERATTR.CHARACTER_OCCUPATION), uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                                    uint256(CHARACTERATTR.CHARACTER_DEXTERITY), uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_CONSTITUTION));*/
        //uint256[] memory characterAttrs = character.getBatchAttr(characterId, attrIds);
        uint256[] memory characterAttrs = new uint256[](0);
        for (uint i = 0; i < tokenId.length; ++i) {
            require(_isApprovedOrOwner(_msgSender(), tokenId[i]), "Not owner or approver");
            putOnOne(characterId, characterAttrs, tokenId[i]);
        }
    }

    // 使用归属关系的变化，来确定tokenId是否存在
    function putOnOne(uint256 characterId, uint256[] memory characterAttrs, uint256 tokenId) internal {
        uint256[] memory attrIds = new uint256[](8);
        (
            attrIds[0], attrIds[1], attrIds[2], attrIds[3],
            attrIds[4], attrIds[5], attrIds[6], attrIds[7]
        ) = 
        (
            uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
            uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT), 
            uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT),
            uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION)
        );
        uint256[] memory limitValue = balanceOfBatch(tokenId, attrIds);
        //require(canPutOn(characterAttrs, limitValue), "Limited to put on");
        uint256 position = limitValue[7];
        
        // 角色对应的装备列表，数组的下标就是 position 的位置
        uint256[] memory equipmentList = _characterEquipments[characterId];
        if (equipmentList.length == 0) {
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

    function takOff(uint256 characterId, uint256[] memory tokenId) external {
        require(tokenId.length > 0, "empty tokenId list");
        ICharacter character = ICharacter(getAddress(uint32(CONTRACT_TYPE.CHARACTER)));
        //require(character.exists(characterId), "characterId not exists");
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
        uint256[] memory attrIds = new uint256[](6);
        (
            attrIds[0], attrIds[1], 
            attrIds[2], attrIds[3], 
            attrIds[4], attrIds[5]
        ) = 
        (
            uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_NAME), 
            uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), 
            uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), uint256(EQUIPMENTATTR.EQUIPMENT_SUITID)
        );
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
        IEverLight everLight = IEverLight(getAddress(uint32(CONTRACT_TYPE.EVER_LIGHT)));
        uint32 basePower = everLight.queryPower(uint8(firstAttrAmount[2]), uint8(firstAttrAmount[4]));

        //todo: 此处的算力值还未进行有效的赋值，需要进行处理
        basePower = uint32(basePower * (125 ** (firstAttrAmount[3] - 1)) / (100 ** (firstAttrAmount[3] - 1)));
        uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

        // 装备合成，原有装备销毁，生成新的装备
        bytes memory name = textOf(firstTokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME));
        _mintEquipment(_msgSender(), firstAttrAmount[2], string(name), firstAttrAmount[5], firstAttrAmount[4], firstAttrAmount[3]);

        // remove old token
        _burn(firstTokenId);
        _burn(secondTokenId);

        delete _equipmentCharacters[firstTokenId];
        delete _equipmentCharacters[secondTokenId];
    }

    // @dev 升级身上已穿的装备
    function upgradeWearToken(uint256 characterId, uint256 tokenId) external {
        IERC721Upgradeable character = IERC721Upgradeable(getAddress(uint32(CONTRACT_TYPE.CHARACTER)));
        require(character.ownerOf(characterId) == _msgSender(), "character !owner");
        require(ownerOf(tokenId) == _msgSender(), "equipment !owner");
        
        uint256[] memory attrIds = new uint256[](5);

        (
            attrIds[0], attrIds[1], attrIds[2], attrIds[3], attrIds[4]
        ) = 
        (
            uint256(EQUIPMENTATTR.EQUIPMENT_ID), uint256(EQUIPMENTATTR.EQUIPMENT_POSITION), 
            uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL), uint256(EQUIPMENTATTR.EQUIPMENT_RARITY), 
            uint256(EQUIPMENTATTR.EQUIPMENT_SUITID)
        );
        
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
        IEverLight everLight = IEverLight(getAddress(uint32(CONTRACT_TYPE.EVER_LIGHT)));
        uint32 basePower = everLight.queryPower(uint8(oldTokenAttrAmount[1]), uint8(oldTokenAttrAmount[3]));

        // basepower = (basepower * 1.25 ** level) * +1.1
        //uint32 basePower = _partsInfo._partsPowerList[position][_tokenList[partsId]._rare];
        basePower = uint32(basePower * (125 ** (oldTokenAttrAmount[2] - 1)) / (100 ** (oldTokenAttrAmount[2] - 1)));
        uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

        // 创造新的装备，同时默认穿在角色身上
        // address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level
        uint256 newTokenId = _mintEquipment(_msgSender(), oldTokenAttrAmount[1], string(textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))), 
                        oldTokenAttrAmount[4], oldTokenAttrAmount[3], oldTokenAttrAmount[2] + 1);
        
        _transfer(_msgSender(), address(this), newTokenId);

        _characterEquipments[characterId][oldTokenAttrAmount[1]] = newTokenId;

        // remove old parts
        _burn(tokenId);
        delete _equipmentCharacters[tokenId];
    }

    // @dev 创建装备
    function newTokenType(uint256 tokenId, string memory name, uint32 suitId) external {
        require(bytes(name).length <= 16, "Error name");
        require(ownerOf(tokenId) == _msgSender(), "!owner");
        require(!_nameFlag[uint256(keccak256(abi.encodePacked(name)))], "Error name");

        require(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL)) == 9, "level != 9");
        require(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED)) == 1, "createFlag=true|1");
        
        // create new parts type
        uint8 position = uint8(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION)));
        uint8 rare = uint8(balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_RARITY)) + 1);
        
        IEverLight everLight = IEverLight(getAddress(uint32(CONTRACT_TYPE.EVER_LIGHT)));
        //require(_partsInfo._partsPowerList[position][rare] > 0, "Not open");
        require(everLight.queryPower(position, rare) > 0, "Not open");
        
        if (suitId == 0) {
            suitId = uint32(everLight.querySuitNum()) + 1;
            //everLight.increaseSuitNum();
            everLight.addNewSuit(suitId, name, position, rare);
            _suitFlag[suitId] = tx.origin;
        } else {
            require(_suitFlag[suitId] == tx.origin, "Not own the suit");
        }

        // create 3 new token for creator
        for (uint i = 0; i < 3; ++i) {
          // todo: 此处的算力用处待定，还没有结论
            /*uint32 randPower = uint32(everLight.queryPower(position, rare) < 10 ?
                                    _getRandom(uint256(256).toString()) % 1 :
                                    _getRandom(uint256(256).toString()) % (everLight.queryPower(position, rare) / 10));*/

            // _mintEquipment(address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level)
            _mintEquipment(_msgSender(), position, name, suitId, rare, 1);
        }

        // 原来的装备状态需要进行变更，9级装备的状态需要改变
        _attach(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED), 1, "", false);

    }

    function _initAttribute(uint256 tokenId, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal {
        _batchAttach(tokenId, 
            _getInitAttributeAttrIds(), 
            _getInitAttributeAmounts(tokenId, position, level, rarity, suitId), 
            _getInitAttributeTexts(name));
    }
    
    function _getInitAttributeTexts(string memory name) internal returns(bytes[] memory) {
        bytes[] memory texts = new bytes[](20);
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
                texts[15],texts[16],texts[17],texts[18],texts[19] 
            )  = 
            (
                bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
            );
        }
        return texts;
    }
    
    function _getInitAttributeAmounts(uint256 tokenId, uint256 position, uint256 level, uint256 rarity, uint256 suitId) internal returns(uint256[] memory){
        uint256[] memory amounts = new uint256[](20);
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
                amounts[15],amounts[16],amounts[17],amounts[18],amounts[19] 
            )  = 
            (
                0, 0, 0, 0, 0
            );
        }
        return amounts;
    }
    
    function _getInitAttributeAttrIds() internal returns(uint256[] memory){
        uint256[] memory attrIds = new uint256[](20);
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
                 uint256(EQUIPMENTATTR.EQUIPMENT_SUITID), 
                uint256(EQUIPMENTATTR.LEVEL_LIMIT), uint256(EQUIPMENTATTR.SEX_LIMIT), 
                uint256(EQUIPMENTATTR.OCCUPATION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_LIMIT)
            );
        }
        { 
            (
                attrIds[10],attrIds[11],attrIds[12],attrIds[13],attrIds[14]
            )  = 
            (
                uint256(EQUIPMENTATTR.DEXTERITY_LIMIT), uint256(EQUIPMENTATTR.INTELLIGENCE_LIMIT), 
                uint256(EQUIPMENTATTR.CONSTITUTION_LIMIT), uint256(EQUIPMENTATTR.STRENGTH_BONUS), 
                uint256(EQUIPMENTATTR.DEXTERITY_BONUS)
            );
        }
        { 
            (
                attrIds[15],attrIds[16],attrIds[17],attrIds[18],attrIds[19] 
            )  = 
            (
                uint256(EQUIPMENTATTR.INTELLIGENCE_BONUS), 
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
