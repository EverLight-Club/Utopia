// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Equipment.
 */
interface IGoods {

    enum GOODSATTR {
        GOODS_ID,
        GOODS_NAME,
        GOODS_LEVEL,
        GOODS_CONSUME,
        GOODS_UPCOUNT,
        GOODS_UPID
    }

    event NewGoods(address indexed owner, uint256 goodsId, uint256 amount);
    event ConsumeGoods(address indexed spender, uint256 goodsId, uint256 amount);

    function getBalance(address owner, uint256 goodsId) external view returns (uint256);
    function batchBalance(address owner, uint256[] memory goodsId) external view returns (uint256[] memory);
    function getGoodsAttr(uint256 goodsId, uint256 attrId) external view returns (uint256, string memory);
    function getGoodsBatchAttr(uint256 goodsId, uint256[] memory attrs) external view returns (uint256[] memory);
    function getExtendAttr(uint256 goodsId, string memory key) external view returns (string memory);
    function getOriginExtendAttr(uint256 goodsId, string memory key) external view returns (string memory);

    function setExtendAttr(uint256 goodsId, string memory key, string memory value) external;
    function claim(address to, uint256 goodsId, uint256 amount) external;
    function burn(address from, uint256 goodsId, uint256 amount) external;
}
