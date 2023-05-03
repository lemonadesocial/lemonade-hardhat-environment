// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadePoapV1.sol";
import "./unique/ICollection.sol";
import "./unique/ICollectionHelpers.sol";
import "./unique/LibPartAdapter.sol";

contract LemonadePoapV1Unique is LemonadePoapV1 {
    using Counters for Counters.Counter;

    address public collection;

    bytes public royaltiesBytes;

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

        collection_.addCollectionAdminCross(
            CrossAddress({eth: address(this), sub: 0})
        );
        collection_.changeCollectionOwnerCross(
            CrossAddress({eth: msg.sender, sub: 0})
        );

        if (royalties.length > 0) {
            PropertyPermission[] memory permissions = new PropertyPermission[](
                3
            );

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

            royaltiesBytes = LibPartAdapter.encode(royalties);
        }
    }

    function _mint(
        address claimer,
        uint256 tokenId_
    ) internal virtual override {
        if (tokenId_ == 0) {
            return super._mint(claimer, tokenId_);
        }

        ICollection collection_ = ICollection(collection);

        uint256 tokenId = collection_.mint(claimer);

        if (royaltiesBytes.length > 0) {
            Property[] memory properties = new Property[](1);
            properties[0] = Property({
                key: ROYALTIES_PROPERTY,
                value: royaltiesBytes
            });

            collection_.setProperties(tokenId, properties);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (tokenId == 0) {
            return super.transferFrom(from, to, tokenId);
        }

        ICollection collection_ = ICollection(collection);

        address owner = collection_.ownerOf(tokenId);

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Forbidden();
        }

        collection_.transferFrom(from, to, tokenId);
    }
}
