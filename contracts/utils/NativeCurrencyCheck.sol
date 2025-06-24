// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INativeCurrencyCheck.sol";

abstract contract NativeCurrencyCheck is INativeCurrencyCheck {
    function isNative(
        address currency
    ) public view virtual override returns (bool);
}
