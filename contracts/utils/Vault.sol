// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Transferable.sol";

abstract contract Vault is AccessControl, Transferable {
    function withdraw(
        address destination,
        address currency,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _transfer(destination, currency, amount);
    }

    receive() external payable {}
}
