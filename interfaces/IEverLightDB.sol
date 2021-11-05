// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface IEverLightDB {

    mapping(uint8 => mapping(uint8 => uint32)) _partsPowerList;     // position -> (rare -> power)
    mapping(uint8 => mapping(uint8 => SuitInfo[])) _partsTypeList;  // position -> (rare -> SuitInfo[])
    mapping(uint8 => uint32) _partsCount;       // position -> count
    mapping(uint8 => string) _rareColor;        // rare -> color
    mapping(uint32 => address) _suitFlag;       // check suit is exists
    mapping(uint256 => bool) _nameFlag;         // parts name is exists

    function getPower(uint8 _position, uint8 _rare) external view returns(uint32);
    function setPower(uint8 _position, uint8 _rare, uint32 _power) external;

    function getTypeList(uint8 _position, uint8 _rare) external view returns(LibEverLight.SuitInfo[] memory);
    function setTypeList(uint8 _position, uint8 _rare, LibEverLight.SuitInfo[] memory suitInfoList) external;
    function addType(uint8 _position, uint8 _rare, LibEverLight.SuitInfo memory _suitInfo) external;
    function updateType(uint8 _position, uint8 _rare, LibEverLight.SuitInfo memory _suitInfo) external;

    function setPartsCount(uint8 _position, uint32 _partsCount) external;
    function getPartsCount(uint8 _position) external view returns(uint32);

    function setRareCount(uint8 _rare, string memory _color) external;
    function getRareCount(uint8 _rare) external view returns(string memory);

    function setSuitFlag(uint8 _suitId, address _suitOwner) external;
    function getSuitFlag(uint8 _suitId) external view returns(address _suitOwner);

    function setPartsName(uint256 _position, bool _val) external;
    function partsNameExists(uint256 _position) external view returns(bool);

}
