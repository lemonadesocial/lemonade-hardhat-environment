// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionHelpers {
    function createNFTCollection(
        string memory name,
        string memory description,
        string memory tokenPrefix
    ) external payable returns (address);

    function makeCollectionERC721MetadataCompatible(
        address collection,
        string memory baseUri
    ) external;
}
