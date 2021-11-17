// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../proxy/Ownable.sol";
import "../../interfaces/IDirectory.sol";

abstract contract DirectoryBridge is Ownable {

    enum CONTRACT_TYPE {
        INVALID, CHARACTER, EVER_LIGHT, EQUIPMENT, EQUIPMENT3664
    }

    address private _directory;

    function __DirectoryBridge_init() internal {
        __Ownable_init();
    }

    /**
     * @dev Returns the address of the current directory.
     */
    function directory() public view virtual returns (address) {
        return _directory;
    }

    function setDirectory(address directoryAddr) external onlyOwner {
        require(directoryAddr != address(0), "directory is the zero address");
        _directory = directoryAddr;

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
        require(_directory != address(0), "directory not setting");
        require(IDirectory(_directory).getType(_msgSender()) > 0, "Not invalid caller");
        _;
    }
}
