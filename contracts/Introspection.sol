// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract Introspection {
    using ERC165Checker for address;

    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) public view returns (bool[] memory) {
        require(account.code.length > 0, "Introspection: account not a contract");

        return account.getSupportedInterfaces(interfaceIds);
    }
}
