// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20MetadataUpgradeable.sol";
import "../../token/ERC721/IERC721EnumerableUpgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../library/Genesis.sol";
import '../../utils/Base64.sol';
import '../../utils/Strings.sol';
import '../../utils/Address.sol';
import "./LibEverLight.sol";
import "../../utils/Context.sol";
import "../../proxy/Initializable.sol";
import "./ICharacter.sol";
import "./IEquipment.sol";

contract EverLight is Initializable, Context, DirectoryBridge, ReentrancyGuard {

  using Address for address;
  using Strings for uint256;

  LibEverLight.Configurations _config;                            // all configurations
  mapping(address => LibEverLight.Account) _accountList;          // all packages owned by address
  mapping(address => address) _recommenderList;                   // msg.sender -> recommender
  
  mapping(uint8 => mapping(uint8 => uint32)) _partsPowerList;     // position -> (rare -> power)
  mapping(uint8 => mapping(uint8 => LibEverLight.SuitInfo[])) _partsTypeList;  // position -> (rare -> SuitInfo[])
  mapping(uint8 => uint32) _partsCount;                           // position -> count
  mapping(uint8 => string) _rareColor;                            // rare -> color

  address public _goverContract;                     // address of governance contract
  address public _tokenContract;                     // address of token contract
  address public _mintTokenContract;
  address[] private _mapContracts;                   // addresses of map contracts 

  event NewCharacter(address owner, uint256 characterId);
  event Withdrawal(address indexed src, address indexed token, uint256 wad);
  
  function initialize() public initializer {
    __DirectoryBridge_init();
    __EverLight_init_unchained();
  }

  function __EverLight_init_unchained() internal initializer {
    _config._baseFee = 0.001 * 10 ** 18; 
    _config._baseTokenFee = 0.001 * 10 ** 18;   // 200 ELGT
    _config._incrPerNum = 2500;       
    _config._incrFee = 0.001 * 10 ** 18; 
    _config._decrBlockNum = 25000;       
    _config._decrFee = 0.001 * 10 ** 18;
    _config._maxPosition = 2;
    _config._luckyStonePrice = 2000;    
  }

  function queryColorByRare(uint8 rare) external view returns (string memory color) {
    return _rareColor[rare];
  }

  function queryPower(uint8 position, uint8 rare) public view returns (uint32 power) {
    return _partsPowerList[position][rare];
  }

  function queryPartsCount(uint8 position) public view returns (uint32 count) {
    return _partsCount[position];
  }

  function queryPartsTypeCount(uint8 position, uint8 rare) public view returns (uint256 count) {
    return _partsTypeList[position][rare].length;
  }

  function queryPartsType(uint8 position, uint8 rare, uint256 index) public view returns (uint32 _suitId, string memory name) {
    (_suitId, name) = (_partsTypeList[position][rare][index]._suitId, _partsTypeList[position][rare][index]._name);
  }

  function querySuitNum() public view returns (uint256 totalSuitNum) {
    return _config._totalSuitNum;
  }

  function queryCharacterCE(uint256 tokenId) public view returns (uint256 _ce /*Combat Effectiveness*/) {
    uint256 _c_ce = ICharacter(getAddress(uint32(CONTRACT_TYPE.CHARACTER))).getCharacterCE(tokenId);
    uint256 _e_ce = IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).getEquipmentCE(tokenId);
    _ce = _c_ce + _e_ce;
  }

  function addNewSuit(uint256 suitId, string memory suitName, uint8 position, uint8 rare) external onlyDirectory {
    _config._totalSuitNum++;
    _partsTypeList[position][rare].push(LibEverLight.SuitInfo(suitName, uint32(suitId)));
    _partsCount[position] = _partsCount[position] + 1;
    //_nameFlag[nameFlag] = true;
    //emit NewTokenType(tx.origin, position, rare, suitName, suitId);
  }

  function queryAccount(address owner) public view returns (LibEverLight.Account memory account) {
    account = _accountList[owner];
  }

  function queryConfigurations() public view returns (LibEverLight.Configurations memory configurations) {
    configurations = _config;
  }

  function queryMapInfo() public view returns (address[] memory addresses) {
    addresses = _mapContracts;
  }

  function mintNewByToken(string memory name, address recommender, uint256 occupation) external {
    require(_mintTokenContract != address(0), "invalid mintTokenContract");
    // one address can only apply once
    require(!_accountList[tx.origin]._creationFlag, "Only once");
    // calc the apply fee
    uint32 decrTimes;
    uint256 applyFee = _config._baseTokenFee + _config._totalCreateNum / _config._incrPerNum * _config._incrFee;
    if (_config._latestCreateBlock != 0) {
      decrTimes = uint32(block.number - _config._latestCreateBlock ) / _config._decrBlockNum;
    }
    
    uint decrFee = (_config._totalDecrTimes + decrTimes) * _config._decrFee;
    applyFee = (applyFee - _config._baseTokenFee) > decrFee ? (applyFee - decrFee) : _config._baseTokenFee;

    //_transferERC20(_mintTokenContract, tx.origin, address(this), applyFee);

    _mintNew(name, recommender, occupation, decrTimes);

    if(recommender != address(0) && _accountList[recommender]._creationFlag) {
      address  preRecomender = _recommenderList[recommender];
      if(preRecomender != address(0)){ // 有上级推荐
        uint256 recommenderBounds = applyFee * 15 / 100;
        uint256 preRecomenderBounds = applyFee * 5 / 100;
        uint256 remainingAmount = applyFee - recommenderBounds - preRecomenderBounds;
        _transferERC20(_mintTokenContract, tx.origin, recommender, recommenderBounds);
        _transferERC20(_mintTokenContract, tx.origin, preRecomender, preRecomenderBounds);
        _transferERC20(_mintTokenContract, tx.origin, address(this), remainingAmount);
      } else {  // 一级推荐
        uint256 bounds20 = applyFee * 20 / 100;
        _transferERC20(_mintTokenContract, tx.origin, recommender, bounds20);
        _transferERC20(_mintTokenContract, tx.origin, address(this), applyFee - bounds20);
      }
      _recommenderList[tx.origin] = recommender;
    } else {
      _transferERC20(_mintTokenContract, tx.origin, address(this), applyFee);
    }
  }

  function mintNew(string memory name, address recommender, uint256 occupation) external payable {
    // one address can only apply once
    require(!_accountList[tx.origin]._creationFlag, "Only once");

    // calc the apply fee
    uint32 decrTimes;
    uint256 applyFee = _config._baseFee + _config._totalCreateNum / _config._incrPerNum * _config._incrFee;
    if (_config._latestCreateBlock != 0) {
      decrTimes = uint32(block.number - _config._latestCreateBlock ) / _config._decrBlockNum;
    }
    
    uint decrFee = (_config._totalDecrTimes + decrTimes) * _config._decrFee;
    applyFee = (applyFee - _config._baseFee) > decrFee ? (applyFee - decrFee) : _config._baseFee;
    require(msg.value >= applyFee, "Not enough value");

    _mintNew(name, recommender, occupation, decrTimes);

    if(recommender != address(0) && _accountList[recommender]._creationFlag) {
      address  preRecomender = _recommenderList[recommender];
      if(preRecomender != address(0)){ // 有上级推荐
        payable(recommender).transfer(applyFee * 15 / 100);
        payable(preRecomender).transfer(applyFee * 5 / 100);
      } else {  // 一级推荐
        payable(recommender).transfer(applyFee * 20 / 100);
      }
    }

    // return the left fee
    if (msg.value > applyFee) {
      payable(tx.origin).transfer(msg.value - applyFee);
    }
  }

  function _mintNew(string memory name, address recommender, uint256 occupation, uint32 decrTimes) internal {
    // create character
    //uint256 characterId = _createCharacter();
    uint256 characterId = ++_config._currentTokenId;

    // create package information
    _accountList[tx.origin]._creationFlag = true;

    // update stat information
    _config._totalCreateNum += 1;
    _config._latestCreateBlock = block.number;
    _config._totalDecrTimes += decrTimes;

    // mint nft
    // todo: 此处调用角色合约进行属性初始化
    // todo: 角色初始化之后还需要进行装备信息初始化
    // todo: 批量调用装备合约，完成各position装备的初始化（包含幸运值的使用，通过参数传入，参考：_createCharacter）
    ICharacter(getAddress(uint32(CONTRACT_TYPE.CHARACTER))).mintCharacter(msg.sender, recommender, characterId, name, occupation);
    address equipmentProxyAddr = getAddress(uint32(CONTRACT_TYPE.EQUIPMENT));
    IEquipment(equipmentProxyAddr).mintBatchEquipment(equipmentProxyAddr, characterId, uint8(_config._maxPosition));
  
    emit NewCharacter(msg.sender, characterId);
  }

  function exchangeToken(uint32 mapId, uint256[] memory mapTokenList) external {
    require(mapId < _mapContracts.length, "Invalid map");
    for (uint i = 0; i < mapTokenList.length; ++i) {
      // burn map token
      _transferERC721(_mapContracts[mapId], tx.origin, address(this), mapTokenList[i]);
      uint256 position = uint8(_getRandom(mapTokenList[i].toString()) % _config._maxPosition);
      IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).mintRandomEquipment(msg.sender, uint8(position));
    }
  }

  function buyLuckyStone(uint8 count) external {
    require(_tokenContract != address(0), "Not open");

    // transfer token to address 0
    uint256 totalToken = _config._luckyStonePrice * count;
    _transferERC20(_tokenContract, tx.origin, address(this), totalToken);

    // mint luck stone 
    for (uint8 i = 0; i < count; ++i) {
      IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).mintLuckStone(tx.origin);
    }
  }

  function useLuckyStone(uint256 characterId, uint256[] memory tokenId) external {
    require(IERC721EnumerableUpgradeable(getAddress(uint32(CONTRACT_TYPE.CHARACTER))).ownerOf(characterId) == msg.sender, "EverLight: !owner");

    for (uint i = 0; i < tokenId.length; ++i) {
      require(IERC721EnumerableUpgradeable(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).ownerOf(tokenId[i]) == msg.sender, "EverLight: stone !owner");
      require(IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).isLucklyStone(tokenId[i]), "EverLight: not stone");
      
      ICharacter(getAddress(uint32(CONTRACT_TYPE.CHARACTER))).attachLucklyPoint(characterId, 1);
      //++_accountList[tx.origin]._luckyNum;

      // burn luck stone token
      IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT))).burnEquipment(tokenId[i]);
    }
  }

  function addPartsType(uint8 position, uint8 rare, string memory color, uint256 power, string[] memory names, uint32[] memory suits) external onlyOwner {
    IEquipment equipment = IEquipment(getAddress(uint32(CONTRACT_TYPE.EQUIPMENT)));
    _partsPowerList[position][rare] = uint32(power);
    _rareColor[rare] = color;

    for (uint i=0; i<names.length; ++i) {
      _partsTypeList[position][rare].push(LibEverLight.SuitInfo(names[i], suits[i]));
      //_nameFlag[uint256(keccak256(abi.encodePacked(names[i])))] = true;
      equipment.setNameFlags(names[i], true);
      if (suits[i] > 0 ) {
        if (equipment.querySuitOwner(suits[i]) == address(0)) {
          _config._totalSuitNum = _config._totalSuitNum < suits[i] ? suits[i] : _config._totalSuitNum;
          //_suitFlag[suits[i]] = tx.origin;
          equipment.setSuitFlags(suits[i], tx.origin);
        } else {
          require(equipment.querySuitOwner(suits[i]) == tx.origin, "Not own the suit");
        }
      }
    }
    
    _partsCount[position] = uint32(_partsCount[position] + names.length);
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
    IERC20MetadataUpgradeable(contractAddress).transferFrom(from, to, amount);

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
    address ownerBefore = IERC721EnumerableUpgradeable(contractAddress).ownerOf(tokenId);
    require(ownerBefore == from, "Not own token");
    
    IERC721EnumerableUpgradeable(contractAddress).transferFrom(from, to, tokenId);

    address ownerAfter = IERC721EnumerableUpgradeable(contractAddress).ownerOf(tokenId);
    require(ownerAfter == to, "Transfer failed");
  }

  function withdraw(address _token, address payable _recipient) external onlyOwner {
    if (_token == address(0x0)) {
      require(_recipient != address(0x0));
        _recipient.transfer(address(this).balance);
      emit Withdrawal(_recipient, address(this), address(this).balance);
      return;
    }

    IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(_token);
    uint balance = token.balanceOf(address(this));
    // transfer token
    token.transfer(_recipient, balance);
    emit Withdrawal(_recipient, _token, balance);
  }

  function setMintFee(uint256 baseFee, uint256 baseTokenFee, uint32 incrPerNum, uint256 incrFee, uint32 decrBlockNum, uint256 decrFee) external onlyOwner {
    (_config._baseFee, _config._baseTokenFee, _config._incrPerNum, _config._incrFee, _config._decrBlockNum, _config._decrFee) = (baseFee, baseTokenFee, incrPerNum, incrFee, decrBlockNum, decrFee);
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

  function setMintTokenAddress(address tokenAddress) external onlyOwner {
    _mintTokenContract = tokenAddress;
  }
  
  function addMapAddress(address mapAddress) external onlyOwner {
    _mapContracts.push(mapAddress);
  }
}
