// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";
import '../../utils/Base64.sol';
import '../../utils/Strings.sol';
import './utils/Address.sol';

contract EverLightDB is DirectoryBridge, ReentrancyGuard {

  using Address for address;
  using Strings for uint256;

  LibEverLight.Configurations _config;                         // all configurations
  IERC721Proxy public _erc721Proxy;                            // address of 721 token      
  
  LibEverLight.PartsInfo _partsInfo;                           // all parts informations
  //mapping(uint256 => LibEverLight.TokenInfo) _tokenList;     // all tokens  
  mapping(address => LibEverLight.Account) _accountList;       // all packages owned by address
  //mapping(uint256 => LibEverLight.Character) _characterList; // all character owned by address

  function initialize() public initializer {
      __DirectoryBridge_init();
      __EverLight_init_unchained();
	}

  function __EverLight_init_unchained() internal initializer {
    _config._baseFee = 25 * 10 ** 18; 
    _config._incrPerNum = 2500;       
    _config._incrFee = 25 * 10 ** 18; 
    _config._decrBlockNum = 25000;       
    _config._decrFee = 25 * 10 ** 18;
    _config._maxPosition = 11;
    _config._luckyStonePrice = 2000;    
  }

  function queryColorByRare(uint8 rare) external view override returns (string memory color) {
    return _partsInfo._rareColor[rare];
  }

  function queryAccount(address owner) external view override returns (LibEverLight.Account memory account) {
    account = _accountList[owner];
  }

  function queryCharacter(uint256 characterId) external view override returns (uint256 tokenId, uint32 powerFactor, uint256[] memory tokenList, uint32 totalPower) {
    (tokenId, powerFactor, totalPower) = (_characterList[characterId]._tokenId, _characterList[characterId]._powerFactor, _characterList[characterId]._totalPower);
    
    tokenList = new uint256[](_config._maxPosition);
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      tokenList[i] = _characterList[characterId]._tokenList[i];
    }
  }

  /*function queryBaseInfo() external view override returns (uint256 baseFee, uint32 incrPerNum, uint256 incrFee, 
                                      uint32 decrBlockNum, uint256 decrFee, uint256 lastestCreateBlock, uint32 totalSuitNum) {
    (baseFee, incrPerNum, incrFee, decrBlockNum, decrFee, lastestCreateBlock, totalSuitNum) = (_config._baseFee, _config._incrPerNum, _config._incrFee, _config._decrBlockNum, _config._decrFee, _config._latestCreateBlock, _config._totalSuitNum);
  }*/

  function queryToken(uint256 tokenId) external view override returns (LibEverLight.TokenInfo memory tokenInfo) {
    tokenInfo = _tokenList[tokenId];
  }

  function queryCharacterCount() external view override returns (uint32) {
    return _config._totalCreateNum;
  }

  function queryLuckyStonePrice() external view override returns (uint32) {
    return _config._luckyStonePrice;
  }

  function queryMapInfo() external view override returns (address[] memory addresses) {
    addresses = _config._mapContracts;
  }

  function querySuitOwner(uint32 suitId) external view override returns (address) {
    return _partsInfo._suitFlag[suitId];
  }

  function isNameExist(string memory name) external view override returns (bool) {
    return _partsInfo._nameFlag[uint256(keccak256(abi.encodePacked(name)))];
  }

  function queryCharacterExtra(uint256 characterId, uint256 extraKey) external view override returns (string memory) {
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    return _characterList[characterId]._extraList[extraKey];
  }

  function setCharacterExtra(uint256 characterId, uint256 extraKey, string memory extraValue) external override {
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    _characterList[characterId]._extraList[extraKey] = extraValue;
  }

  function mint() external override payable {
    // one address can only apply once
    require(!_accountList[tx.origin]._creationFlag, "Only once");

    // calc the apply fee
    uint32 decrTimes;
    uint256 applyFee = _config._baseFee + _config._totalCreateNum / _config._incrPerNum * _config._incrFee;
    if (_config._latestCreateBlock != 0) {
      decrTimes = uint32( block.number - _config._latestCreateBlock ) / _config._decrBlockNum;
    }
    
    uint decrFee = (_config._totalDecrTimes + decrTimes) * _config._decrFee;
    applyFee = (applyFee - _config._baseFee) > decrFee ? (applyFee - decrFee) : _config._baseFee;
    require(msg.value >= applyFee, "Not enough value");

    // create character
    uint256 characterId = _createCharacter();

    // create package information
    _accountList[tx.origin]._creationFlag = true;
    // _accountList[tx.origin]._luckyNum = 0;

    // return the left fee
    if (msg.value > applyFee) {
      payable(tx.origin).transfer(msg.value - applyFee);
    }

    // update stat information
    _config._totalCreateNum += 1;
    _config._latestCreateBlock = block.number;
    _config._totalDecrTimes += decrTimes;

    // mint nft
    _erc721Proxy.mintBy(tx.origin, characterId);
  }

  function wear(uint256 characterId, uint256[] memory tokenList) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "character not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin);
    require(tokenList.length > 0, "Empty token");
    
    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // deal with all parts
    for (uint i = 0; i < tokenList.length; ++i) {
      if (tokenList[i] == 0) {
        continue;
      }

      //require(_tokenOwnOf(tokenList[i]) == tx.origin, "parts not owner");
      require(_erc721Proxy.ownerOf(tokenList[i]) == tx.origin, "parts !owner");
      require(_tokenList[tokenList[i]]._wearToken == 0, "weared");

      // wear parts
      uint8 position = _tokenList[tokenList[i]]._position;
      uint256 partsId = _characterList[newCharacterId]._tokenList[position];

      _characterList[newCharacterId]._tokenList[position] = tokenList[i];
      _tokenList[tokenList[i]]._wearToken = newCharacterId;
      _erc721Proxy.burnBy(tokenList[i]);

      // mint weared parts
      if (partsId != 0) {
        _tokenList[partsId]._wearToken = 0;
        _erc721Proxy.mintBy(tx.origin, partsId);
      }
    }

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];

    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function takeOff(uint256 characterId, uint8[] memory positions) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    require(positions.length > 0, "Empty position");
    
    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // deal with all parts
    for (uint i=0; i<positions.length; ++i) {
      require(positions[i]<_config._maxPosition, "Invalid position");

      uint256 partsId = _characterList[newCharacterId]._tokenList[positions[i]];
      if (partsId == 0) {
        continue;
      }

      _characterList[newCharacterId]._tokenList[positions[i]] = 0;
      _tokenList[partsId]._wearToken = 0;
      _erc721Proxy.mintBy(tx.origin, partsId);
    }

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];

    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function upgradeToken(uint256 firstTokenId, uint256 secondTokenId) external override {
  
    require(_erc721Proxy.ownerOf(firstTokenId) == tx.origin, "first !owner");
    require(_erc721Proxy.ownerOf(secondTokenId) == tx.origin, "second !owner");

    // check pats can upgrade
    require(keccak256(bytes(_tokenList[firstTokenId]._name)) == keccak256(bytes(_tokenList[secondTokenId]._name)), "!name");
    require(_tokenList[firstTokenId]._level == _tokenList[secondTokenId]._level, "!level");
    require(_tokenList[firstTokenId]._position == _tokenList[secondTokenId]._position, "!position");
    require(_tokenList[firstTokenId]._rare == _tokenList[secondTokenId]._rare, "!rare");
    require(_tokenList[firstTokenId]._level < 9, "Max level");
    
    require(_tokenList[firstTokenId]._wearToken == 0, "f weared");
    require(_tokenList[secondTokenId]._wearToken == 0, "s weared");

    // basepower = (basepower * 1.25 ** level) * +1.1
    uint32 basePower = _partsInfo._partsPowerList[_tokenList[firstTokenId]._position][_tokenList[firstTokenId]._rare];
    basePower = uint32(basePower * (125 ** (_tokenList[firstTokenId]._level - 1)) / (100 ** (_tokenList[firstTokenId]._level - 1)));
    uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

    // create new parts
    uint256 newTokenId = ++_config._currentTokenId;
    _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin,*/ _tokenList[firstTokenId]._position, _tokenList[firstTokenId]._rare,
                                                    _tokenList[firstTokenId]._name, _tokenList[firstTokenId]._suitId, basePower + randPower,
                                                    _tokenList[firstTokenId]._level + 1, false, 0);

    // remove old token
    _erc721Proxy.burnBy(firstTokenId);
    delete _tokenList[firstTokenId];
    _erc721Proxy.burnBy(secondTokenId);
    delete _tokenList[secondTokenId];
    
    // mint new token
    _erc721Proxy.mintBy(tx.origin, newTokenId);
  }

  function upgradeWearToken(uint256 characterId, uint256 tokenId) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    //require(_tokenOwnOf(tokenId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(tokenId) == tx.origin, "parts !owner");

    uint8 position = _tokenList[tokenId]._position;
    uint256 partsId = _characterList[characterId]._tokenList[position];

    // check pats can upgrade
    require(keccak256(bytes(_tokenList[tokenId]._name)) == keccak256(bytes(_tokenList[partsId]._name)), "!token");
    require(_tokenList[tokenId]._level == _tokenList[partsId]._level, "!level");
    require(_tokenList[tokenId]._rare == _tokenList[partsId]._rare, "!rare");
    require(_tokenList[tokenId]._level < 9, "Max level");
    require(_tokenList[tokenId]._wearToken == 0, "Weared");

    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // basepower = (basepower * 1.25 ** level) * +1.1
    uint32 basePower = _partsInfo._partsPowerList[position][_tokenList[partsId]._rare];
    basePower = uint32(basePower * (125 ** (_tokenList[partsId]._level - 1)) / (100 ** (_tokenList[partsId]._level - 1)));
    uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

    // create new parts
    uint256 newTokenId = ++_config._currentTokenId;
    _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin,*/ _tokenList[partsId]._position, _tokenList[partsId]._rare,
                                                    _tokenList[partsId]._name, _tokenList[partsId]._suitId, basePower + randPower,
                                                    _tokenList[partsId]._level + 1, false, newCharacterId);

    _characterList[newCharacterId]._tokenList[position] = newTokenId;
    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);

    // remove old parts
    _erc721Proxy.burnBy(tokenId);
    delete _tokenList[tokenId];
    delete _tokenList[partsId];

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function exchangeToken(uint32 mapId, uint256[] memory mapTokenList) external override {
    require(mapId < _config._mapContracts.length, "Invalid map");

    for (uint i=0; i<mapTokenList.length; ++i) {
      // burn map token
      _transferERC721(_config._mapContracts[mapId], tx.origin, address(this), mapTokenList[i]);

      // generate new token
      uint256 newTokenId = _genRandomToken(uint8(_getRandom(mapTokenList[i].toString()) % _config._maxPosition));

      _erc721Proxy.mintBy(tx.origin, newTokenId);
    }
  }

  function buyLuckyStone(uint8 count) external override {
    require(_config._tokenContract != address(0), "Not open");

    // transfer token to address 0
    uint256 totalToken = _config._luckyStonePrice * count;
    _transferERC20(_config._tokenContract, tx.origin, address(this), totalToken);

    // mint luck stone 
    for (uint8 i=0; i<count; ++i) {
      uint256 newTokenId = ++_config._currentTokenId;
      (_tokenList[newTokenId]._tokenId, _tokenList[newTokenId]._position, _tokenList[newTokenId]._name) = (newTokenId, 99, "Lucky Stone");

      _erc721Proxy.mintBy(tx.origin, newTokenId);
    }
  }

  function useLuckyStone(uint256[] memory tokenId) external override {
    for (uint i=0; i<tokenId.length; ++i) {
      //require(_tokenOwnOf(tokenId[i]) == tx.origin, "Not owner");
      require(_erc721Proxy.ownerOf(tokenId[i]) == tx.origin, "stone !owner");
      require(_tokenList[tokenId[i]]._position == 99, "Not lucky stone");

      ++_accountList[tx.origin]._luckyNum;

      // burn luck stone token
      _erc721Proxy.burnBy(tokenId[i]);
      delete _tokenList[tokenId[i]];
    }
  }

  function newTokenType(uint256 tokenId, string memory name, uint32 suitId) external override {
    //require(_tokenOwnOf(tokenId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(tokenId) == tx.origin, "!owner");
    require(_tokenList[tokenId]._level == 9, "level != 9");
    require(!_tokenList[tokenId]._createFlag, "createFlag=true");
    require(bytes(name).length <= 16, "Error name");

    // create new parts type
    uint8 position = _tokenList[tokenId]._position;
    uint8 rare = _tokenList[tokenId]._rare + 1;
    uint256 nameFlag = uint256(keccak256(abi.encodePacked(name)));
    
    require(_partsInfo._partsPowerList[position][rare] > 0, "Not open");
    require(!_partsInfo._nameFlag[nameFlag], "Error name");
    
    if (suitId == 0) {
      suitId = ++_config._totalSuitNum;
      _partsInfo._suitFlag[suitId] = tx.origin;
    } else {
      require(_partsInfo._suitFlag[suitId] == tx.origin, "Not own the suit");
    }

    _partsInfo._partsTypeList[position][rare].push(LibEverLight.SuitInfo(name, suitId));
    _partsInfo._partsCount[position] = _partsInfo._partsCount[position] + 1;
    _partsInfo._nameFlag[nameFlag] = true;
    emit NewTokenType(tx.origin, position, rare, name, suitId);

    // create 3 new token for creator
    for (uint i=0; i<3; ++i) {
      uint256 newTokenId = ++_config._currentTokenId;
      uint32 randPower = uint32(_partsInfo._partsPowerList[position][rare] < 10 ?
                                _getRandom(uint256(256).toString()) % 1 :
                                _getRandom(uint256(256).toString()) % (_partsInfo._partsPowerList[position][rare] / 10));

        // create token information
        _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin, */position, rare, name, suitId, 
                                                    _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);

        _erc721Proxy.mintBy(tx.origin, newTokenId);
    }

    // update token and charactor information
    uint256 newPartsTokenId = ++_config._currentTokenId;
    _tokenList[newPartsTokenId] = LibEverLight.TokenInfo(newPartsTokenId,/* tx.origin,*/ position, rare - 1, _tokenList[tokenId]._name, 
                                                         _tokenList[tokenId]._suitId, _tokenList[tokenId]._power, 9, true, _tokenList[tokenId]._wearToken);

    if (_tokenList[newPartsTokenId]._wearToken != 0) {
      _characterList[_tokenList[newPartsTokenId]._wearToken]._tokenList[position] = newPartsTokenId;
    } else {
      _erc721Proxy.burnBy(tokenId);
      _erc721Proxy.mintBy(tx.origin, newPartsTokenId);
    }

    delete _tokenList[tokenId];
  }

  // internal functions
  /*function _characterOwnOf(uint256 tokenId) internal view returns (address) {
    return _characterList[tokenId]._owner;
  }*/

  /*function _tokenOwnOf(uint256 tokenId) internal view returns (address) {
    return _tokenList[tokenId]._owner;
  }*/

  function _getRandom(string memory purpose) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
  }

  function _genRandomToken(uint8 position) internal returns (uint256 tokenId) {
    // create random number and plus lucky number on msg.sender
    uint256 luckNum = _getRandom(uint256(position).toString()) % _partsInfo._partsCount[position] + _accountList[tx.origin]._luckyNum;
    if (luckNum >= _partsInfo._partsCount[position]) {
      luckNum = _partsInfo._partsCount[position] - 1;
    }

    // find the parts on position by lucky number
    tokenId = ++_config._currentTokenId;
    for(uint8 rare=0; rare<256; ++rare) {
      if (luckNum >= _partsInfo._partsTypeList[position][rare].length) {
        luckNum -= _partsInfo._partsTypeList[position][rare].length;
        continue;
      }

      // calc rand power by base power and +10%
      uint32 randPower = uint32(_partsInfo._partsPowerList[position][rare] <= 10 ?
                                _getRandom(uint256(256).toString()) % 1 :
                                _getRandom(uint256(256).toString()) % (_partsInfo._partsPowerList[position][rare] / 10));

      // create token information
      _tokenList[tokenId] = LibEverLight.TokenInfo(tokenId, /*tx.origin,*/ position, rare, _partsInfo._partsTypeList[position][rare][luckNum]._name,
                                                   _partsInfo._partsTypeList[position][rare][luckNum]._suitId, 
                                                   _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);
      break;
    }

    // clear lucky value on msg.sender, only used once
    _accountList[tx.origin]._luckyNum = 0;
  }

  function _createCharacter() internal returns (uint256 tokenId) {
    // create character
    tokenId = ++_config._currentTokenId;
    _characterList[tokenId]._tokenId = tokenId;
    //_characterList[tokenId]._owner = tx.origin;
    _characterList[tokenId]._powerFactor = uint32(_getRandom(uint256(256).toString()) % 30);

    // create all random parts for character
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      uint256 partsId = _genRandomToken(i);

      _characterList[tokenId]._tokenList[i] = partsId;
      _tokenList[partsId]._wearToken = tokenId;
    }

    // calc total power of character
    _characterList[tokenId]._totalPower = _calcTotalPower(tokenId);
  }

  function _calcTotalPower(uint256 tokenId) internal view returns (uint32 totalPower) {
    uint256 lastSuitId;
    bool suitFlag = true;

    // sum parts power
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      uint256 index = _characterList[tokenId]._tokenList[i];
      if (index == 0) {
        suitFlag = false;
        continue;
      }

      totalPower += _tokenList[index]._power;
      
      if (suitFlag == false || _tokenList[index]._suitId == 0) {
        suitFlag = false;
        continue;
      } 

      if (lastSuitId == 0) {
        lastSuitId = _tokenList[index]._suitId;
        continue;
      }

      if (_tokenList[index]._suitId != lastSuitId) {
        suitFlag = false;
      }
    }

    // calc suit power
    if (suitFlag) {
      totalPower += totalPower * 12 / 100;
    }
    totalPower += totalPower * _characterList[tokenId]._powerFactor / 100;
  }

  function _copyCharacter(uint256 oldId, uint256 newId) internal {
    (_characterList[newId]._tokenId, /*_characterList[newId]._owner,*/ _characterList[newId]._powerFactor) = (newId,/* tx.origin,*/ _characterList[oldId]._powerFactor);

    // copy old character's all parts info
    for (uint8 index=0; index<_config._maxPosition; ++index) {
      _characterList[newId]._tokenList[index] = _characterList[oldId]._tokenList[index];
      // 
      _tokenList[_characterList[newId]._tokenList[index]]._wearToken = newId;
    }
  }

  function _transferERC20(address contractAddress, address from, address to, uint256 amount) internal {
    //uint256 balanceBefore = IERC20(contractAddress).balanceOf(from);
    IERC20(contractAddress).transferFrom(from, to, amount);

    bool success;
    assembly {
      switch returndatasize()
        case 0 {                       // This is a non-standard ERC-20
            success := not(0)          // set success to true
        }
        case 32 {                      // This is a compliant ERC-20
            returndatacopy(0, 0, 32)
            success := mload(0)        // Set `success = returndata` of external call
        }
        default {                      // This is an excessively non-compliant ERC-20, revert.
            revert(0, 0)
        }
    }
    require(success, "Transfer failed");
  }

  function _transferERC721(address contractAddress, address from, address to, uint256 tokenId) internal {
    address ownerBefore = IERC721(contractAddress).ownerOf(tokenId);
    require(ownerBefore == from, "Not own token");
    
    IERC721(contractAddress).transferFrom(from, to, tokenId);

    address ownerAfter = IERC721(contractAddress).ownerOf(tokenId);
    require(ownerAfter == to, "Transfer failed");
  }

  // governace functions
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setMintFee(uint256 baseFee, uint32 incrPerNum, uint256 incrFee, uint32 decrBlockNum, uint256 decrFee) external onlyOwner {
    (_config._baseFee, _config._incrPerNum, _config._incrFee, _config._decrBlockNum, _config._decrFee) = (baseFee, incrPerNum, incrFee, decrBlockNum, decrFee);
  }

  function addPartsType(uint8 position, uint8 rare, string memory color, uint256 power, string[] memory names, uint32[] memory suits) external onlyOwner {
    _partsInfo._partsPowerList[position][rare] = uint32(power);
    _partsInfo._rareColor[rare] = color;

    for (uint i=0; i<names.length; ++i) {
      _partsInfo._partsTypeList[position][rare].push(LibEverLight.SuitInfo(names[i], suits[i]));
      _partsInfo._nameFlag[uint256(keccak256(abi.encodePacked(names[i])))] = true;

      if (suits[i] > 0 ) {
        if (_partsInfo._suitFlag[suits[i]] == address(0)) {
          _config._totalSuitNum = _config._totalSuitNum < suits[i] ? suits[i] : _config._totalSuitNum;
          _partsInfo._suitFlag[suits[i]] = tx.origin;
        } else {
          require(_partsInfo._suitFlag[suits[i]] == tx.origin, "Not own the suit");
        }
      }
    }
    
    _partsInfo._partsCount[position] = uint32(_partsInfo._partsCount[position] + names.length);
  }

  function setLuckStonePrice(uint32 price) external onlyOwner {
    _config._luckyStonePrice = price;
  }
 
  function setMaxPosition(uint32 maxPosition) external onlyOwner {
    _config._maxPosition = maxPosition;
  }

  function setGovernaceAddress(address governaceAddress) external onlyOwner {
    _config._goverContract = governaceAddress;
  }

  function setTokenAddress(address tokenAddress) external onlyOwner {
    _config._tokenContract = tokenAddress;
  }
  
  function addMapAddress(address mapAddress) external onlyOwner {
    _config._mapContracts.push(mapAddress);
  }

  function setERC721Proxy(address proxyAddress) external onlyOwner {
    _erc721Proxy = IERC721Proxy(proxyAddress);
  }



    
}
