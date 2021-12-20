// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICharacter {

	function mintCharacter(address recipient, address recommender, uint256 tokenId, string memory name, uint256 occupation) external;
	function attachLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external;
	function getCharacterCE(uint256 tokenId) external view returns (uint256 _ce);
}
