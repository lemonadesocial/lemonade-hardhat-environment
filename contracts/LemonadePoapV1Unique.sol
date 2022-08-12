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
        address chainlinkRequest,
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
            accessRegistry,
            chainlinkRequest
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

    function _mint(address claimer)
        internal
        virtual
        override
        returns (string memory err)
    {
        uint256 tokenId = tokenIdTracker.current();

        if (tokenId == 0) {
            return LemonadePoapV1._mint(claimer);
        }

        ICollection collection_ = ICollection(collection);
        collection_.mintWithTokenURI(claimer, tokenId, tokenURI_);
        collection_.setProperty(
            tokenId,
            ROYALTIES_PROPERTY,
            abi.encode(royalties)
        );
        return "";
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
