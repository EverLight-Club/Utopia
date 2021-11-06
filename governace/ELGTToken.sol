// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract ELGTToken is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {

    //1. 初始直接mint 10%给一个地址就好
    //2. erc20合约支持一个mint & burn接口，允许调用方为gov合约
    //3. erc20合约需要有一个接口设置gov的地址

    uint256 public MaxTotalSupply = 21_000_000 * 10 ** 18;

    constructor() ERC20("ELGTToken", "ELGT") ERC20Permit("ELGTToken") {
        _mint(msg.sender, MaxTotalSupply * 10 / 100);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
        require(totalSupply() < MaxTotalSupply, "ELGTToken: total supply risks overflowing max");
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}