// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ASSIGN_METHOD = keccak256("ASSIGN_METHOD");
bytes32 constant CLAIM_METHOD = keccak256("CLAIM_METHOD");
bytes32 constant PURCHASE_METHOD = keccak256("PURCHASE_METHOD");
bytes32 constant RESERVE_METHOD = keccak256("RESERVE_METHOD");

error Forbidden();
error NotFound();
error NotImplemented();
error SendValueFailed();

struct Assignment {
    address to;
    uint256 count;
}
