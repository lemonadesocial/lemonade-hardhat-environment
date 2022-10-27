// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721LemonadeV1.sol";
import "./rarible/LibPart.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";

contract LemonadeUniqueCollectionV1 is IMintable {
    address public collection;

    constructor(
        address collectionHelpers,
        string memory name,
        string memory description,
        string memory tokenPrefix
    ) payable {
        ICollectionHelpers collectionHelpers_ = ICollectionHelpers(
            collectionHelpers
        );

        collection = collectionHelpers_.createNFTCollection{value: msg.value}(
            name,
            description,
            tokenPrefix
        );
        collectionHelpers_.makeCollectionERC721MetadataCompatible(
            collection,
            ""
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

    function mintToCaller(string memory tokenURI)
        public
        override
        returns (uint256)
    {
        return ICollection(collection).mintWithTokenURI(msg.sender, tokenURI);
    }

    function mintToCallerWithRoyalty(
        string memory tokenURI,
        LibPart.Part[] memory royalties
    ) public override returns (uint256) {
        uint256 tokenId = mintToCaller(tokenURI);

        ICollection(collection).setProperty(
            tokenId,
            ROYALTIES_PROPERTY,
            abi.encode(royalties)
        );

        return tokenId;
    }
}
