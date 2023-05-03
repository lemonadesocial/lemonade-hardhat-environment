// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721LemonadeV1.sol";
import "./rarible/LibPart.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";
import "./unique/LibPartAdapter.sol";

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

        collection_.addCollectionAdminCross(
            CrossAddress({eth: address(this), sub: 0})
        );
        collection_.changeCollectionOwnerCross(
            CrossAddress({eth: msg.sender, sub: 0})
        );

        PropertyPermission[] memory permissions = new PropertyPermission[](3);

        permissions[0] = PropertyPermission({
            code: TokenPermissionField.Mutable,
            value: false
        });
        permissions[1] = PropertyPermission({
            code: TokenPermissionField.CollectionAdmin,
            value: true
        });
        permissions[2] = PropertyPermission({
            code: TokenPermissionField.TokenOwner,
            value: false
        });

        TokenPropertyPermission[]
            memory permissionsArray = new TokenPropertyPermission[](1);
        permissionsArray[0] = TokenPropertyPermission({
            key: ROYALTIES_PROPERTY,
            permissions: permissions
        });

        collection_.setTokenPropertyPermissions(permissionsArray);
    }

    function mintToCaller(
        string memory tokenURI
    ) public override returns (uint256) {
        return ICollection(collection).mintWithTokenURI(msg.sender, tokenURI);
    }

    function mintToCallerWithRoyalty(
        string memory tokenURI,
        LibPart.Part[] memory royalties
    ) public override returns (uint256) {
        uint256 tokenId = mintToCaller(tokenURI);

        bytes memory royaltiesBytes = LibPartAdapter.encode(royalties);
        Property[] memory properties = new Property[](1);
        properties[0] = Property({
            key: ROYALTIES_PROPERTY,
            value: royaltiesBytes
        });

        ICollection(collection).setProperties(tokenId, properties);

        return tokenId;
    }
}
