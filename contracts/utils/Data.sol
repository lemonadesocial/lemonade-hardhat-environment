// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

function stringToId(string memory id) pure returns (bytes32) {
    return keccak256(abi.encode(id));
}
