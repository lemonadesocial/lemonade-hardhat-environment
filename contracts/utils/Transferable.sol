// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Transferable {
    error CannotTransfer();

    function _transfer(
        address destination,
        address currency,
        uint256 amount,
        bool isNative
    ) internal {
        if (isNative) {
            (bool success, ) = payable(destination).call{value: amount}("");

            if (!success) revert CannotTransfer();
        } else {
            bool success = IERC20(currency).transfer(
                destination,
                amount
            );

            if (!success) revert CannotTransfer();
        }
    }
}
