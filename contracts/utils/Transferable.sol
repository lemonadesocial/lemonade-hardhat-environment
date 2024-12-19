// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Transferable {
    error CannotTransfer();

    function _transfer(
        address destination,
        address currency,
        uint256 amount
    ) internal {
        if (currency == address(0)) {
            (bool success, ) = payable(destination).call{value: amount}("");

            if (!success) revert CannotTransfer();
        } else {
            bool success = IERC20(currency).transferFrom(
                address(this),
                destination,
                amount
            );

            if (!success) revert CannotTransfer();
        }
    }
}
