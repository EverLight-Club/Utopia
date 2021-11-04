// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGoodsDB {
    function addGoods(uint256[] memory attrId, uint256[] memory values, bytes[] memory texts) external;
}

contract GoodsData {
    IGoodsDB database = IGoodsDB(address(0x));

    function initDB {
        uint256[] memory attrId = [uint256(GOODSATTR.GOODS_ID), uint256(GOODSATTR.GOODS_NAME), 
                                   uint256(GOODSATTR.GOODS_LEVEL), uint256(GOODSATTR.GOODS_CONSUME), 
                                   uint256(GOODSATTR.GOODS_UPCOUNT), uint256(GOODSATTR.GOODS_UPID)];

        database.addGoods(attrId, [1, 1, 1, 0, 3, 2], ["", "Small Ruby", "", "", "", ""]);
        database.addGoods(attrId, [2, 1, 1, 0, 3, 3], ["", "Medium Ruby", "", "", "", ""]);
        database.addGoods(attrId, [3, 1, 1, 0, 3, 4], ["", "Large Ruby", "", "", "", ""]);
        database.addGoods(attrId, [4, 1, 1, 0, 0, 0], ["", "Perfect Ruby", "", "", "", ""]);

        database.addGoods(attrId, [4, 1, 1, 0, 3, 5], ["", "Small Topaz", "", "", "", ""]);
        database.addGoods(attrId, [5, 1, 1, 0, 3, 6], ["", "Medium Topaz", "", "", "", ""]);
        database.addGoods(attrId, [6, 1, 1, 0, 3, 7], ["", "Large Topaz", "", "", "", ""]);
        database.addGoods(attrId, [7, 1, 1, 0, 0, 0], ["", "Perfect Topaz", "", "", "", ""]);

        database.addGoods(attrId, [8, 1, 1, 0, 3, 9], ["", "Small Sapphire", "", "", "", ""]);
        database.addGoods(attrId, [9, 1, 1, 0, 3, 10], ["", "Medium Sapphire", "", "", "", ""]);
        database.addGoods(attrId, [10, 1, 1, 0, 3, 11], ["", "Large Sapphire", "", "", "", ""]);
        database.addGoods(attrId, [11, 1, 1, 0, 0, 0], ["", "Perfect Sapphire", "", "", "", ""]);

        database.addGoods(attrId, [12, 1, 1, 0, 3, 13], ["", "Small Emerald", "", "", "", ""]);
        database.addGoods(attrId, [13, 1, 1, 0, 3, 14], ["", "Medium Emerald", "", "", "", ""]);
        database.addGoods(attrId, [14, 1, 1, 0, 3, 15], ["", "Large Emerald", "", "", "", ""]);
        database.addGoods(attrId, [15, 1, 1, 0, 0, 0], ["", "Perfect Emerald", "", "", "", ""]);

        database.addGoods(attrId, [16, 1, 1, 0, 3, 17], ["", "Small Amethyst", "", "", "", ""]);
        database.addGoods(attrId, [17, 1, 1, 0, 3, 18], ["", "Medium Amethyst", "", "", "", ""]);
        database.addGoods(attrId, [18, 1, 1, 0, 3, 19], ["", "Large Amethyst", "", "", "", ""]);
        database.addGoods(attrId, [19, 1, 1, 0, 0, 0], ["", "Perfect Amethyst", "", "", "", ""]);        
    }
}
