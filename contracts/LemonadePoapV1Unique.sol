// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadePoapV1.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";

contract LemonadePoapV1Unique is LemonadePoapV1 {
    using Counters for Counters.Counter;

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
        ICollectionHelpers collectionHelpers_ = ICollectionHelpers(
            collectionHelpers
        );

        collection = collectionHelpers_.createNFTCollection{value: msg.value}(
            name,
            name,
            symbol
        );
        collectionHelpers_.makeCollectionERC721MetadataCompatible(
            collection,
            tokenURI
        );

        ICollection collection_ = ICollection(collection);

        collection_.addCollectionAdmin(address(this));
        collection_.addToCollectionAllowList(address(this));
        collection_.changeCollectionOwner(msg.sender);
        collection_.setTokenPropertyPermission(
            ROYALTIES_PROPERTY,
            false,
            true,
            false
        );
    }

    function _mint(address claimer, uint256 tokenId_)
        internal
        virtual
        override
    {
        if (tokenId_ == 0) {
            return ERC721._mint(claimer, tokenId_);
        }

        ICollection collection_ = ICollection(collection);

        uint256 tokenId = collection_.mint(claimer);

        collection_.setProperty(
            tokenId,
            ROYALTIES_PROPERTY,
            abi.encode(royalties)
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

        address owner = collection_.ownerOf(tokenId);

        require(
            owner == from,
            "LemonadePoapV1Unique: transfer from incorrect owner"
        );
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "LemonadePoapV1Unique: transfer caller is not owner nor approved"
        );

        collection_.transferFrom(from, to, tokenId);
    }
}
