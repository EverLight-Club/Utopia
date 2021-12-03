// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

library LibEverLight {

  struct AttrMetadataExtend {
        string name;    
        string symbol;
        bool exist;
        uint256 balance;
        bytes text;
  }

  struct EquipmentExtend {
      uint256 tokenId;
      uint256 position;
      uint256 attrId;
      string name;
      string symbol;
      bool exist;
      uint256 balance;
      bytes text;
  }

  struct Configurations {
    uint256 _baseFee;                           // base fee for create character
    uint256 _baseTokenFee;
    uint32 _incrPerNum;                         // the block number for increase fee
    uint256 _incrFee;                           // increase fee after increase block number
    uint32 _decrBlockNum;                       // the block number for decrease fee
    uint256 _decrFee;                           // decrease fee after decrease block number
    uint256 _latestCreateBlock;                 // the latest block number for create characters
    uint32 _totalDecrTimes;                     // total decrease times for nonone apply 
    uint32 _totalCreateNum;                     // total number of create characters
    uint256 _currentTokenId;                    // current token id for nft creation
    uint32 _totalSuitNum;                       // total suit number 
    uint32 _maxPosition;                        // max parts number for charater
    uint32 _luckyStonePrice;                    // price of lucky stone
}
  
  struct SuitInfo {
    string _name;                               // suit name
    uint32 _suitId;                             // suit id, 0 for non suit
  }
 
  struct PartsInfo {
    mapping(uint8 => mapping(uint8 => uint32)) _partsPowerList;     // position -> (rare -> power)
    mapping(uint8 => mapping(uint8 => SuitInfo[])) _partsTypeList;  // position -> (rare -> SuitInfo[])
    mapping(uint8 => uint32) _partsCount;       // position -> count
    mapping(uint8 => string) _rareColor;        // rare -> color
    mapping(uint32 => address) _suitFlag;       // check suit is exists
    mapping(uint256 => bool) _nameFlag;         // parts name is exists
  }
  
  struct TokenInfo {
    uint256 _tokenId;                           // token id
    //address _owner;                             // owner of token
    uint8 _position;                            // parts position
    uint8 _rare;                                // rare level 
    string _name;                               // parts name
    uint32 _suitId;                             // suit id, 0 for non suit
    uint32 _power;                              // parts power
    uint8 _level;                               // parts level
    bool _createFlag;                           // has created new parts
    uint256 _wearToken;                         // character token id which wear this token
  }

  struct Account {
    bool _creationFlag;                         // if the address has created character
    //uint32 _luckyNum;                           // lucky number of current address
  }

  struct Character {
    uint256 _tokenId;                           // token id
    //address _owner;                           // owner of character
    uint32 _powerFactor;                        // power factor of character
    mapping(uint8 => uint256) _tokenList;       // position -> tokenID
    uint32 _totalPower;                         // total power of parts list
    mapping(uint256 => string) _extraList;      // 
  }



}
