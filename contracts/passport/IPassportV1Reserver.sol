// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPassportV1Reserver {
    function onPassportV1Reserved(bool success, bytes calldata data) external;
}
