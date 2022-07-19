// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadePoapV1.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";

contract LemonadePoapV1Unique is LemonadePoapV1 {
    address public collection;

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI,
        LibPart.Part[] memory royalties,
        uint256 totalSupply,
        address accessRegistry,
        address collectionHelpers
    )
        payable
        LemonadePoapV1(
            name,
            symbol,
            creator,
            tokenURI,
            royalties,
            totalSupply,
            accessRegistry
        )
    {
        collection = ICollectionHelpers(collectionHelpers)
            .createNonfungibleCollection(name, name, symbol);

        ICollection(collection).setTokenPropertyPermission(
            ROYALTIES_PROPERTY,
            false,
            true,
            false
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        if (tokenId == 0) {
            return ERC721._mint(to, tokenId);
        }

        ICollection collection_ = ICollection(collection);

        collection_.mintWithTokenURI(to, tokenId, _tokenURI);

        collection_.setProperty(
            tokenId,
            ROYALTIES_PROPERTY,
            abi.encode(_royalties)
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (tokenId == 0) {
            return ERC721.transferFrom(from, to, tokenId);
        }

        ICollection collection_ = ICollection(collection);

        require(
            collection_.ownerOf(tokenId) == from,
            "LemonadePoapV1Unique: transfer from incorrect owner"
        );
        require(
            isApprovedForAll(from, msg.sender),
            "LemonadePoapV1Unique: transfer caller is not approved"
        );

        collection_.transferFrom(from, to, tokenId);
    }
}
