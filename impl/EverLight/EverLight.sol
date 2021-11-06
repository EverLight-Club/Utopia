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
import '../../utils/Address.sol';
import "../../interfaces/ICharacter.sol";
import "../../interfaces/IEquipment.sol";

contract EverLight is DirectoryBridge, ReentrancyGuard {

  using Address for address;
  using Strings for uint256;

  LibEverLight.Configurations _config;                         // all configurations
  mapping(address => LibEverLight.Account) _accountList;       // all packages owned by address
  mapping(address => address) _recommenderList;                // msg.sender -> recommender

  address public _goverContract;                     // address of governance contract
  address public _tokenContract;                     // address of token contract
  address[] private _mapContracts;                   // addresses of map contracts 
  
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

  function queryAccount(address owner) external view override returns (LibEverLight.Account memory account) {
    account = _accountList[owner];
  }

  function queryConfigurations() external view override returns (LibEverLight.Configurations memory configurations) {
    configurations = _config;
  }

  /*function queryCharacterCount() external view override returns (uint32) {
    return _config._totalCreateNum;
  }*/

  /*function queryLuckyStonePrice() external view override returns (uint32) {
    return _config._luckyStonePrice;
  }*/

  function queryMapInfo() external view override returns (address[] memory addresses) {
    addresses = _mapContracts;
  }

  /// 创建角色
  function mint(string memory name, uint256 occupation /* 职业 */, address recommender /* 推荐人 */) external override payable {
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
    //uint256 characterId = _createCharacter();
    uint256 characterId = ++_config._currentTokenId;

    // create package information
    _accountList[tx.origin]._creationFlag = true;

    // return the left fee
    if (msg.value > applyFee) {
      payable(tx.origin).transfer(msg.value - applyFee);
    }

    // 判断当前推荐人是否是有效的，然后按照比例进行分配
    // 一级推荐 5%，直属推荐 15% => 按照参数设定
    if(recommender != address(0) && _accountList[recommender]._creationFlag) {
      address  preRecomender = _recommenderList[recommender];
      if(preRecomender != address(0)){ // 有上级推荐
        payable(recommender).transfer(applyFee * 15 / 100);
        payable(preRecomender).transfer(applyFee * 5 / 100);
      } else {  // 一级推荐
        payable(recommender).transfer(applyFee * 20 / 100);
      }
    }

    // update stat information
    _config._totalCreateNum += 1;
    _config._latestCreateBlock = block.number;
    _config._totalDecrTimes += decrTimes;

    // mint nft
    // todo: 此处调用角色合约进行属性初始化
    // todo: 角色初始化之后还需要进行装备信息初始化
    // todo: 批量调用装备合约，完成各position装备的初始化（包含幸运值的使用，通过参数传入，参考：_createCharacter）
    ICharacter(getAddress(CONTRACT_TYPE.CHARACTER)).mintCharacter(msg.sender, recommender, characterId, name, occupation);
    IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).batchMintEquipment(msg.sender, characterId, _config._maxPosition);
  }

  // @dev ELMT 兑换装备
  // todo: 装备兑换由 EverLight 提供入口，调用装备合约完成新装备的创建；
  function exchangeToken(uint32 mapId, uint256[] memory mapTokenList) external override {
    require(mapId < _mapContracts.length, "Invalid map");
    // logic:
    // 1、直接调用装备合约完成装备创建，装备归属于当前调用者；
    // 2、装备的生成满足随机性；

    for (uint i=0; i<mapTokenList.length; ++i) {
      // burn map token
      _transferERC721(_mapContracts[mapId], tx.origin, address(this), mapTokenList[i]);
      IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).mintRandomEquipment(msg.sender);
    }
  }

  // @dev 购买幸运石
  function buyLuckyStone(uint8 count) external override {
    require(_tokenContract != address(0), "Not open");

    // transfer token to address 0
    uint256 totalToken = _config._luckyStonePrice * count;
    _transferERC20(_tokenContract, tx.origin, address(this), totalToken);

    // todo: 
    // 1.转移用于的 ELET 代币金额
    // 2.调用角色合约，为角色新增幸运值；
    // 3.幸运值会有多个，同样按照数量加点；
    // 思考：每次购买的幸运值对应点数为多少？

    // mint luck stone 
    for (uint8 i = 0; i < count; ++i) {
      uint256 newTokenId = ++_config._currentTokenId;
      //(_tokenList[newTokenId]._tokenId, _tokenList[newTokenId]._position, _tokenList[newTokenId]._name) = (newTokenId, 99, "Lucky Stone");
      IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).mintLuckStone(tx.origin);
    }
  }

  // @dev 使用幸运石
  function useLuckyStone(uint256 characterId, uint256[] memory tokenId) external override {
    // 幸运石为特殊的装备
    // 幸运石使用后角色的幸运值增加
    // 对应的装备需要销毁
    require(ICharacter(getAddress(CONTRACT_TYPE.CHARACTER)).ownerOf(characterId) == msg.sender, "EverLight: !owner");

    for (uint i = 0; i < tokenId.length; ++i) {
      require(IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).ownerOf(tokenId[i]) == msg.sender, "EverLight: stone !owner");
      require(IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).isLucklyStone(tokenId[i]), "EverLight: not stone");
      
      // 角色幸运值增加
      ICharacter(getAddress(CONTRACT_TYPE.CHARACTER)).increateLucklyPoint(characterId, 1);
      //++_accountList[tx.origin]._luckyNum;

      // burn luck stone token
      IEquipment(getAddress(CONTRACT_TYPE.EQUIPMENT)).burnEquipment(tokenId[i]);
    }
  }

  function _getRandom(string memory purpose) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
  }

  // function _genRandomToken(uint8 position) internal returns (uint256 tokenId) {
  //   // create random number and plus lucky number on msg.sender
  //   uint256 luckNum = _getRandom(uint256(position).toString()) % _partsInfo._partsCount[position] + _accountList[tx.origin]._luckyNum;
  //   if (luckNum >= _partsInfo._partsCount[position]) {
  //     luckNum = _partsInfo._partsCount[position] - 1;
  //   }

  //   // find the parts on position by lucky number
  //   tokenId = ++_config._currentTokenId;
  //   for(uint8 rare=0; rare<256; ++rare) {
  //     if (luckNum >= _partsInfo._partsTypeList[position][rare].length) {
  //       luckNum -= _partsInfo._partsTypeList[position][rare].length;
  //       continue;
  //     }

  //     // calc rand power by base power and +10%
  //     uint32 randPower = uint32(_partsInfo._partsPowerList[position][rare] <= 10 ?
  //                               _getRandom(uint256(256).toString()) % 1 :
  //                               _getRandom(uint256(256).toString()) % (_partsInfo._partsPowerList[position][rare] / 10));

  //     // create token information
  //     _tokenList[tokenId] = LibEverLight.TokenInfo(tokenId, /*tx.origin,*/ position, rare, _partsInfo._partsTypeList[position][rare][luckNum]._name,
  //                                                  _partsInfo._partsTypeList[position][rare][luckNum]._suitId, 
  //                                                  _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);
  //     break;
  //   }

  //   // clear lucky value on msg.sender, only used once
  //   _accountList[tx.origin]._luckyNum = 0;
  // }

  // function _createCharacter() internal returns (uint256 tokenId) {
  //   // create character
  //   tokenId = ++_config._currentTokenId;
  //   //_characterList[tokenId]._tokenId = tokenId;
  //   //_characterList[tokenId]._powerFactor = uint32(_getRandom(uint256(256).toString()) % 30);

  //   // create all random parts for character
  //   /*for (uint8 i=0; i<_config._maxPosition; ++i) {
  //     uint256 partsId = _genRandomToken(i);

  //     _characterList[tokenId]._tokenList[i] = partsId;
  //     _tokenList[partsId]._wearToken = tokenId;
  //   }*/

  //   // calc total power of character
  //   //_characterList[tokenId]._totalPower = _calcTotalPower(tokenId);
  // }

  // function _calcTotalPower(uint256 tokenId) internal view returns (uint32 totalPower) {
  //   uint256 lastSuitId;
  //   bool suitFlag = true;

  //   // sum parts power
  //   for (uint8 i=0; i<_config._maxPosition; ++i) {
  //     uint256 index = _characterList[tokenId]._tokenList[i];
  //     if (index == 0) {
  //       suitFlag = false;
  //       continue;
  //     }

  //     totalPower += _tokenList[index]._power;
      
  //     if (suitFlag == false || _tokenList[index]._suitId == 0) {
  //       suitFlag = false;
  //       continue;
  //     } 

  //     if (lastSuitId == 0) {
  //       lastSuitId = _tokenList[index]._suitId;
  //       continue;
  //     }

  //     if (_tokenList[index]._suitId != lastSuitId) {
  //       suitFlag = false;
  //     }
  //   }

  //   // calc suit power
  //   if (suitFlag) {
  //     totalPower += totalPower * 12 / 100;
  //   }
  //   totalPower += totalPower * _characterList[tokenId]._powerFactor / 100;
  // }

  // function _copyCharacter(uint256 oldId, uint256 newId) internal {
  //   (_characterList[newId]._tokenId, /*_characterList[newId]._owner,*/ _characterList[newId]._powerFactor) = (newId,/* tx.origin,*/ _characterList[oldId]._powerFactor);

  //   // copy old character's all parts info
  //   for (uint8 index=0; index<_config._maxPosition; ++index) {
  //     _characterList[newId]._tokenList[index] = _characterList[oldId]._tokenList[index];
  //     // 
  //     _tokenList[_characterList[newId]._tokenList[index]]._wearToken = newId;
  //   }
  // }

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

  function setLuckStonePrice(uint32 price) external onlyOwner {
    _config._luckyStonePrice = price;
  }
 
  function setMaxPosition(uint32 maxPosition) external onlyOwner {
    _config._maxPosition = maxPosition;
  }

  function setGovernaceAddress(address governaceAddress) external onlyOwner {
    _goverContract = governaceAddress;
  }

  function setTokenAddress(address tokenAddress) external onlyOwner {
    _tokenContract = tokenAddress;
  }
  
  function addMapAddress(address mapAddress) external onlyOwner {
    _mapContracts.push(mapAddress);
  }
}
