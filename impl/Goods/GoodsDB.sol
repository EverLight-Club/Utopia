// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../../utils/OwnableUpgradeable.sol";
import "../../interfaces/IGoods.sol";
import "./IGoodsDB.sol";

contract GoodsDB is ERC3664Upgradeable, ERC721EnumerableUpgradeable, IGoodsDB, OwnableUpgradeable {

    function initialize() public initializer {
        __ERC3664_init_unchained();
        __ERC721Enumerable_init_unchained("Utopia Goods DB", "UGD");
        __Ownable_init_unchained();
        __GoodsDB_init_unchained();
	}

    function __GoodsDB_init_unchained() internal initializer {
        uint256[] memory attrIds = [uint256(GOODSATTR.GOODS_ID), uint256(GOODSATTR.GOODS_NAME), 
                                    uint256(GOODSATTR.GOODS_LEVEL), uint256(GOODSATTR.GOODS_CONSUME), 
                                    uint256(GOODSATTR.GOODS_UPCOUNT), uint256(GOODSATTR.GOODS_UPID)];
        string[] memory names = ["id", "name", "level", "consume", "upcount", "upid"];
        string[] memory symbols = ["ID", "NAME", "LEVEL", "CONSUME", "UPCOUNT", "UPID"];
        string[] memory uris = ["", "", "", "", "", ""];
        _mintBatch(attrIds, names, symbols, uris);
    }

    function getAttr(uint256 goodsId, uint256 attrId) external view override returns (uint256, string memory) {
        require(_exists(goodsId), "Goods not exist");
        return (balanceOf(goodsId, attrId), string(textOf(goodsId, attrId)));
    }

    function getBatchAttr(uint256 goodsId, uint256[] memory attrId) external view override returns (uint256[] memory) {
        require(_exists(goodsId), "Goods not exist");
        return balanceOfBatch(goodsId, attrIds);
    }

    function getExtendAttr(uint256 goodsId, string memory key) external view override returns (string memory) {
        require(_exists(goodsId), "Goods not exist");
        return _extendAttr[goodsId][key];
    }

    function setExtendAttr(uint256 goodsId, string memory key, string memory value) external {
        require(_isApprovedOrOwner(_msgSender(), goodsId), "Not owner or approver");
        _extendAttr[goodsId][key] = value;
    }

    function addGoods(uint256[] memory attrId, uint256[] memory values, bytes[] memory texts) external onlyOwner {
        uint256 goodsId;
        for (uint256 i=0; i<attrId.length; ++i) {
            if (attrId[i] == uint256(GOODSATTR.GOODS_ID)) {
                goodsId = values[i];
                require(!_exists(goodsId), "Goods exist");

                break;
            }
        }

        require(goodsId != 0, "Goods id not set");
        _safeMint(address(this), goodsId);
        _batchAttach(goodsId, attrIds, values, texts);

        emit NewGoods(_msgSender(), goodsId, textOf(goodsId, uint256(GOODSATTR.GOODS_NAME)));
    }

    function updateGoods(uint256 goodsId, uint256[] memory attrId, uint256[] memory values, bytes[] memory texts) external onlyOwner {
        require(_exists(goodsId), "Goods not exist");
        require(attrId.length == values.length, "Not match values");
        require(attrId.length == texts.length, "Not match values");
        require(attrId.length > 0, "Empty attributes");

        uint256[] memory currValue = balanceOfBatch(goodsId, attrIds);
        _burnBatch(goodsId, attrIds, currValue);

        _batchAttach(goodsId, attrIds, values, texts);
    }

    function addNewAttr(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner {
        require(attrIds.length == names.length, "Not match values");
        require(attrIds.length == symbols.length, "Not match values");
        require(attrIds.length == uris.length, "Not match values");
        require(attrIds.length > 0, "Empty attribute");

        _mintBatch(attrIds, names, symbols, uris); 
    }
}
