// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICharacter {

	function mintCharacter(address recipient, address recommender, uint256 tokenId, string memory name, uint256 occupation) external;
	function attachLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external;
	function getCharacterFeature(uint256 tokenId) external view returns (uint256 _hp, uint256 _atk, uint256 _def, uint256 _dps);
}
