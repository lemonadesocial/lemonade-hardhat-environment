// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegateManager {
    mapping(address => bool) internal _delegates;

    constructor(address[] memory delegates) {
        addDelegates(delegates);
    }

    function addDelegates(address[] memory addresses) public virtual {
        for (uint256 i = 0; i < addresses.length; i++) {
            _delegates[addresses[i]] = true;
        }
    }

    function removeDelegates(address[] memory addresses) public virtual {
        for (uint256 i = 0; i < addresses.length; i++) {
            _delegates[addresses[i]] = false;
        }
    }

    function isDelegate(address delegate) public view returns (bool) {
        return _delegates[delegate];
    }
}
