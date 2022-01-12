// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../proxy/ProxyAdmin.sol";

contract UtopiaAdmin is ProxyAdmin {
    /**
     * @dev Initializes owner of the admin contract.
     */
    constructor() ProxyAdmin() {
        
    }
}
