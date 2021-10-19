// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mint is ERC20 {
    constructor(string memory name, string memory symbol, address owner, uint256 initialSupply) ERC20(name, symbol) {
       _mint(owner, initialSupply);
    }
}
