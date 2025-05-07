// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./Transferable.sol";
import "./NativeCurrencyCheck.sol";

abstract contract Vault is AccessControlEnumerable, Transferable, NativeCurrencyCheck {
    function withdraw(
        address destination,
        address currency,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _transfer(destination, currency, amount, isNative(currency));
    }

    receive() external payable {}
}
