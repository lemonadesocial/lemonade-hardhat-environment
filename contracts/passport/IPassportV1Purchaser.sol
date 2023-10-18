// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPassportV1Purchaser {
    function onPassportV1Purchased(bool success, bytes calldata data) external;
}
