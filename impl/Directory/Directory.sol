// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../proxy/Initializable.sol";
import "../../proxy/OwnableUpgradeable.sol";
import "../../interfaces/IDirectory.sol";

contract Directory is IDirectory, Initializable, OwnableUpgradeable {
    //
    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    mapping(uint32 => address) private _contractAddress;
    mapping(address => uint32) private _contractIndex;

    event NewAddress(uint32 contractType, address contractAddress);

    function setAddress(uint32 contractType, address contractAddress) external onlyOwner{
        _contractAddress[contractType] = contractAddress;
        _contractIndex[contractAddress] = contractType;
        
        emit NewAddress(contractType, contractAddress);
    }

    function getAddress(uint32 contractType) public view override returns (address) {
        return _contractAddress[contractType];
    }

    function getType(address contractAddress) public view override returns (uint32) {
        return _contractIndex[contractAddress];
    }
}
