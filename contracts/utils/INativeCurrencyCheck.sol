// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INativeCurrencyCheck {
    function isNative(address currency) external view returns (bool);
}
