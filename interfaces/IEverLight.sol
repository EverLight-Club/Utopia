// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface IEverLight {

	function queryPartsCount(uint8 position) external returns (uint32 count);
	function queryPartsTypeCount(uint8 position, uint8 rare) external view returns (uint32 count) ;
	function queryPartsType(uint8 position, uint8 rare, uint256 index) external view returns (uint32 _suitId, string memory name);
	function queryPower(uint8 position, uint8 rare) external view returns (uint32 power);
	function querySuitNum() external view returns (uint256 totalSuitNum);
	function addNewSuit(uint256 suitId, string memory suitName, uint8 position, uint8 rare) external;
}
