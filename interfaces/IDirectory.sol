// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Directory.
 */
interface IDirectory {
    enum CONTRACTTYPE {
        UTOPIA,
        DIRECTORY,
        CHARACTER,
        EQUIPMENT,
        EQUIPMENTDB,
        GOODSDB,
        GOODS,
        NPC
    }
    
    function getAddress(uint32 contractType) external view returns (address);
    function getType(address contractAddress) external view returns (uint32);
}
