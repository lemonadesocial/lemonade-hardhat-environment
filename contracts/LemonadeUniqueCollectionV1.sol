// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./rarible/LibPart.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";

contract LemonadeUniqueCollectionV1 {
    address private _collection;

    constructor(
        address collectionHelpers,
        string memory name,
        string memory description,
        string memory tokenPrefix
    ) payable {
        _collection = ICollectionHelpers(collectionHelpers)
            .createNonfungibleCollection(name, description, tokenPrefix);

        ICollection(_collection).setTokenPropertyPermission(
            ROYALTIES_PROPERTY,
            false,
            true,
            false
        );
    }

    function mintToCaller(string memory tokenURI)
        public
        virtual
        returns (uint256)
    {
        ICollection collection = ICollection(_collection);

        uint256 tokenId = collection.nextTokenId();

        collection.mintWithTokenURI(msg.sender, tokenId, tokenURI);

        return tokenId;
    }

    function mintToCallerWithRoyalty(
        string memory tokenURI,
        LibPart.Part[] memory royalties
    ) public virtual returns (uint256) {
        uint256 tokenId = mintToCaller(tokenURI);

        ICollection(_collection).setProperty(
            tokenId,
            ROYALTIES_PROPERTY,
            abi.encode(royalties)
        );

        return tokenId;
    }
}
