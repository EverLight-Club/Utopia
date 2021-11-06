// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../proxy/OwnableUpgradeable.sol";
import "../../interfaces/IDirectory.sol";

abstract contract DirectoryBridge is OwnableUpgradeable {

    enum CONTRACT_TYPE {
        CHARACTER, EVER_LIGHT, EQUIPMENT, EVER_LIGHT_DB
    }

    address private _directory;

    function __DirectoryBridge_init() internal initializer {
        __Ownable_init_unchained();
    }

    /**
     * @dev Returns the address of the current directory.
     */
    function directory() public view virtual returns (address) {
        return _directory;
    }

    function setDirectory(address directory) external onlyOwner {
        require(directory != address(0), "directory is the zero address");
        _directory = directory;

        afterSetDirectory();
    }

    function getAddress(uint32 contractType) internal view returns (address) {
        return IDirectory(_directory).getAddress(contractType);
    }

    function afterSetDirectory() internal virtual {
    }

    /**
     * @dev Throws if called by any account not in directory.
     */
    modifier onlyDirectory() {
        require(IDirectory(_directory).getType(_msgSender()) > 0, "Not invalid caller");
        _;
    }
}
