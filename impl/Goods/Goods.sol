// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC1155/ERC1155Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../interfaces/IGoods.sol";
import "../../library/Genesis.sol";
import "./IGoodsDB.sol";

contract Goods is ERC1155Upgradeable, IGoods, DirectoryBridge {
	
    mapping(uint256 => mapping(string => string)) _extendAttr;

    function initialize() public initializer {
        __ERC1155_init_unchained("");
        __DirectoryBridge_init();
        __Goods_init_unchained();
	}

    function __Goods_init_unchained() internal initializer {
        
    }

    function getBalance(address owner, uint256 goodsId) external view returns (uint256) {
        return balanceOf(owner, goodsId);
    }

    function batchBalance(address owner, uint256[] memory goodsId) external view returns (uint256[] memory) {
        require(goodsId.length > 0, "Empty goods id");

        uint256[] memory batchBalances = new uint256[](goodsId.length);
        for (uint256 i = 0; i < goodsId.length; ++i) {
            batchBalances[i] = balanceOf(owner, goodsId[i]);
        }

        return batchBalances;
    }

    function getGoodsAttr(uint256 goodsId, uint256 attrId) external view override returns (uint256, string memory) {
        IGoodsDB database = IGoodsDB(getAddress(uint256(CONTRACTTYPE.GOODSDB)));
        return database.getAttr(goodsId, attrId);
    }

    function getGoodsBatchAttr(uint256 goodsId, uint256[] memory attrs) external view override returns (uint256[] memory) {
        IGoodsDB database = IGoodsDB(getAddress(uint256(CONTRACTTYPE.GOODSDB)));
        return database.getBatchAttr(goodsId, attrs);
    }

    function getExtendAttr(uint256 goodsId, string memory key) external view override returns (string memory) {
        return _extendAttr[goodsId][key];
    }

    function getOriginExtendAttr(uint256 goodsId, string memory key) external view override returns (string memory) {
        IGoodsDB database = IGoodsDB(getAddress(uint256(CONTRACTTYPE.GOODSDB)));
        return database.getExtendAttr(goodsId, key);
    }

    function setExtendAttr(uint256 goodsId, string memory key, string memory value) external onlyDirectory {
        _extendAttr[goodsId][key] = value;
    }

    function claim(address to, uint256 goodsId, uint256 amount) external onlyDirectory {
        _mint(to, goodsId, amount, "");

        emit NewGoods(to, goodsId, amount);
    }

    function burn(address from, uint256 goodsId, uint256 amount) external onlyDirectory {
        _burn(from, goodsId, amount);

        emit ConsumeGoods(from, goodsId, amount);
    }

    function upGoods(uint256 goodsId, uint256 amount) external {
        IGoodsDB database = IGoodsDB(getAddress(uint256(CONTRACTTYPE.GOODSDB)));

        uint256[] goodsAttr = database.getBatchAttr(goodsId, [uint256(GOODSATTR.GOODS_UPCOUNT), uint256(GOODSATTR.GOODS_UPID)]);
        require(goodsAttr[0] > 0, "Goods can not up");

        uint256 upCount = amount / goodsAttr[0];
        uint256 needBalance = upCount * goodsAttr[0];
        uint256 balance = balanceOf(_msgSender(), goodsId);
    
        require(upCount > 0, "Not enough goods");
        require(balance >= needBalance, "Not enough balance");

        _burn(_msgSender(), goodsId, needBalance);
        _mint(_msgSender(), goodsAttr[1], upCount, "");

        emit NewGoods(_msgSender(), goodsAttr[1], upCount);
        emit ConsumeGoods(_msgSender(), goodsId, needBalance);
    }
}
