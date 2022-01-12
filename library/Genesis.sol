// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Genesis {
	// base price
    uint256 public constant MINT_PRICE = 25 * 10 ** 18;
    uint256 public constant WASH_POINTS_PRICE = 15 * 10 ** 18;
    uint256 public constant RECOMMENDER_REWARD = 50;
    uint256 public constant MAX_EQUIPMENT = 16;
    address payable public constant TREASURY = payable(0xed1819fa53cF62276702F2A9B40EDB3ED43bd341);

}
