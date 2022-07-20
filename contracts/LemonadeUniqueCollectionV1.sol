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
        collection = ICollectionHelpers(collectionHelpers)
            .createNonfungibleCollection(name, description, tokenPrefix);

        ICollection(collection).setTokenPropertyPermission(
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
        ICollection collection_ = ICollection(collection);

        uint256 tokenId = collection_.nextTokenId();

        collection_.mintWithTokenURI(msg.sender, tokenId, tokenURI);

        return tokenId;
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
