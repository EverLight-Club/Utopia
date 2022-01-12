// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Equipment.
 * 
 */
interface IGoodsDB {
    event NewGoods(address indexed creator, uint256 goodsId, string goodsName);

    function getAttr(uint256 goodsId, uint256 attrId) external view returns (uint256, string memory);
    function getBatchAttr(uint256 goodsId, uint256[] memory attrId) external view returns (uint256[] memory);
    function getExtendAttr(uint256 goodsId, string memory key) external view returns (string memory);
}
