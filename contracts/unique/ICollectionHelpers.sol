// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionHelpers {
    function createNonfungibleCollection(
        string memory name,
        string memory description,
        string memory tokenPrefix
    ) external returns (address);
}
