// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../proxy/TransparentUpgradeableProxy.sol";

contract DirectoryProxy is TransparentUpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `admin_`, backed by the implementation at `logic_`
     * bytes4(keccak256("initialize()")) == 0x8129fc1c
     */
    constructor(address logic_, address admin_) payable 
      TransparentUpgradeableProxy(logic_, admin_, hex"8129fc1c") {

    }
}
