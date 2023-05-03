// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

string constant ROYALTIES_PROPERTY = "royalties";

struct Property {
    string key;
    bytes value;
}

enum TokenPermissionField {
    Mutable,
    TokenOwner,
    CollectionAdmin
}

struct PropertyPermission {
    TokenPermissionField code;
    bool value;
}

struct TokenPropertyPermission {
    string key;
    PropertyPermission[] permissions;
}

struct CrossAddress {
    address eth;
    uint256 sub;
}

interface ICollection is IERC721 {
    function addCollectionAdminCross(CrossAddress memory newAdmin)
    external;

    function changeCollectionOwnerCross(CrossAddress memory newOwner)
    external;

    function mint(address to) external returns (uint256);

    function mintWithTokenURI(address to, string memory tokenUri)
    external
    returns (uint256);

    function setTokenPropertyPermissions(TokenPropertyPermission[] memory permissions)
    external;

    function setProperties(uint256 tokenId, Property[] memory properties)
    external;

    function property(uint256 tokenId, string memory key)
    external
    view
    returns (bytes memory);
}
