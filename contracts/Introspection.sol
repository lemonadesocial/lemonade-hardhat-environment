// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract Introspection {
    using ERC165Checker for address;

    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) public view returns (bool[] memory) {
        return account.getSupportedInterfaces(interfaceIds);
    }
}
