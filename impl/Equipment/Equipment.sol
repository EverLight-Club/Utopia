// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC721/IERC721Upgradeable.sol";
import "../../token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IEquipment.sol";
import "../../interfaces/ICharacter.sol";
import "../../interfaces/IEverLight.sol";
import "../../library/Genesis.sol";
import "../../utils/Strings.sol";
import "../../proxy/Ownable.sol";
import "./Equipment3664.sol";

contract Equipment is Ownable, IEquipment, DirectoryBridge, ERC721EnumerableUpgradeable, IERC721ReceiverUpgradeable {
    
    using Strings for uint256;
    
    mapping(uint256 => uint256[]) _characterEquipments;         // characterId => []equipmentId
    mapping(uint256 => mapping(string => string)) _extendAttr;  // 
    mapping(uint256 => uint256) _equipmentCharacters;           // equipmentId => characterId
    mapping(uint32 => address) _suitFlag;                       // check suit is exists
    mapping(uint256 => bool) _nameFlag;                         // parts name is exists

    uint256 public _totalToken;
    Equipment3664 public equipment3664;

    function initialize() public initializer {
        __ERC721Enumerable_init("Utopia Equipment Token", "UET");
        __DirectoryBridge_init();
        __Equipment_init_unchained();
    }

    function __Equipment_init_unchained() internal initializer {
    }

    function setEquipment3664(address _equipment3664) external onlyOwner {
        require(_equipment3664 != address(0), "address is nil address");
        equipment3664 = Equipment3664(_equipment3664);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory output) {

    }

    // @dev 批量创建装备（对于新角色，进行初始化创建时调用该接口）
    function mintBatchEquipment(address recipient, uint256 characterId, uint8 maxPosition) external payable onlyDirectory {
        for(uint256 i = 0; i < maxPosition; i++) {
            _mintEquipmentWithCharacter(recipient, characterId, uint8(i));
        }
    }

    // @dev 创建装备，为指定角色创建指定位置的装备
    function mintEquipment(address recipient, uint256 characterId, uint8 position) external payable onlyDirectory {
        _mintEquipmentWithCharacter(recipient, characterId, position);
    }

    function _mintEquipmentWithCharacter(address recipient, uint256 characterId, uint8 position) internal {
        IERC721Upgradeable character = IERC721Upgradeable(getAddress(uint32(CONTRACT_TYPE.CHARACTER)));
        //require(character.ownerOf(characterId) == tx.origin, "characterId !owner");
        uint256 tokenId = _mintEquipment(recipient, position, "", 0, 0, 1);
        _characterEquipments[characterId].push(tokenId);
        _equipmentCharacters[tokenId] = characterId;
        emit NewEquipment(recipient, characterId, tokenId);
    }

    function _mintEquipment(address recipient, uint256 position, string memory name, uint256 suitId, uint256 rarity, uint256 level) internal returns(uint256 tokenId) {
        uint256 _tokenId = ++_totalToken;
        _safeMint(recipient, _tokenId);
        equipment3664.initAttributeForEquipment(_tokenId, position, name, suitId, rarity, level);
        return _tokenId;
    }

    function mintLuckStone(address recipient) external onlyDirectory {
        _mintEquipment(recipient, 99, "Luck Stone", 0, 0, 1);
    }

    function isLucklyStone(uint256 tokenId) public view  returns (bool) {
        uint256 position = equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
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

    function setSuitFlags(uint32 suitId, address _owner) external onlyDirectory {
        _suitFlag[suitId] = _owner;
    }

    // @dev 查看套装ID的所有者
    function querySuitOwner(uint32 suitId) public view returns (address) {
       return _suitFlag[suitId];
    }

    // @dev 查看装备名称是否被使用
    function isNameExist(string memory name) public view returns (bool) {
        return _nameFlag[uint256(keccak256(abi.encodePacked(name)))];
    }

    function setNameFlags(string memory name, bool flags) external onlyDirectory {
        _nameFlag[uint256(keccak256(abi.encodePacked(name)))] = flags;
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
        uint256[] memory limitValue = equipment3664.balanceOfBatch(tokenId, attrIds);
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
        uint256 position = equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION));
        uint256[] storage equipmentList = _characterEquipments[characterId];

        //require(equipmentList.length == Genesis.MAX_EQUIPMENT, "No equipment found");
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
        uint256[] memory firstAttrAmount = equipment3664.balanceOfBatch(firstTokenId, attrIds);
        uint256[] memory secondAttrAmount = equipment3664.balanceOfBatch(secondTokenId, attrIds);

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
        bytes memory name = equipment3664.textOf(firstTokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME));
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
        
        uint256[] memory newTokenAttrAmount = equipment3664.balanceOfBatch(tokenId, attrIds);
        
        //uint8 position = _tokenList[tokenId]._position;
        //uint256 partsId = _characterList[characterId]._tokenList[position];
        uint256 wearedEquipmentId = _characterEquipments[characterId][newTokenAttrAmount[1]];

        uint256[] memory oldTokenAttrAmount = equipment3664.balanceOfBatch(wearedEquipmentId, attrIds);

        // check pats can upgrade
        require(keccak256(equipment3664.textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))) == keccak256(equipment3664.textOf(wearedEquipmentId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))), "!token");
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
        uint256 newTokenId = _mintEquipment(_msgSender(), oldTokenAttrAmount[1], string(equipment3664.textOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_NAME))), 
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

        require(equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_LEVEL)) == 9, "level != 9");
        require(equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED)) == 1, "createFlag=true|1");
        
        // create new parts type
        uint8 position = uint8(equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_POSITION)));
        uint8 rare = uint8(equipment3664.balanceOf(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_RARITY)) + 1);
        
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
        equipment3664.attach(tokenId, uint256(EQUIPMENTATTR.EQUIPMENT_CREATED), 1, "", false);

    }

    function _getRandom(string memory purpose) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
