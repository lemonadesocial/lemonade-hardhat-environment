// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

string constant ROYALTIES_PROPERTY = "royalties";

interface ICollection is IERC721 {
    function addCollectionAdmin(address newAdmin) external;

    function changeCollectionOwner(address newOwner) external;

    function mint(address to) external returns (uint256);

    function mintWithTokenURI(address to, string memory tokenUri)
        external
        returns (uint256);

    function setTokenPropertyPermission(
        string memory key,
        bool isMutable,
        bool collectionAdmin,
        bool tokenOwner
    ) external;

    function setProperty(
        uint256 tokenId,
        string memory key,
        bytes memory value
    ) external;

    function property(uint256 tokenId, string memory key)
        external
        view
        returns (bytes memory);
}
