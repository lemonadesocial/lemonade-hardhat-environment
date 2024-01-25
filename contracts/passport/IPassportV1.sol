// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Shared.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IPassportV1 is
    IERC721EnumerableUpgradeable,
    IERC721MetadataUpgradeable
{
    event Assign(address sender, Assignment[] assignments);
    event Claim(address sender);
    event ExecuteClaim(address indexed sender, uint256 tokenId);
    event ExecutePurchase(
        uint256 indexed paymentId,
        address payable indexed sender,
        uint256 value,
        address payable referrer,
        uint256 tokenId,
        bool success
    );
    event ExecuteReserve(
        uint256 indexed paymentId,
        address payable indexed sender,
        uint256 value,
        bool referred,
        bool success
    );
    event Purchase(
        uint256 paymentId,
        address payable sender,
        uint256 value,
        address payable referrer
    );
    event Reserve(
        uint256 paymentId,
        address payable sender,
        uint256 value,
        Assignment[] assignments
    );
    event SetProperty(uint256 indexed tokenId, bytes32 key, bytes value);
    event SetPropertyBatch(uint256 indexed tokenId, Property[] properties);

    struct Property {
        bytes32 key;
        bytes value;
    }

    function assign(Assignment[] calldata assignments) external payable;

    function claim() external payable;

    function purchase(
        uint160 roundIds,
        address payable referrer,
        bytes calldata data
    ) external payable;

    function reserve(
        uint160 roundIds,
        Assignment[] calldata assignments,
        bytes calldata data
    ) external payable;

    function setProperty(bytes32 key, bytes calldata value) external;

    function setPropertyBatch(Property[] calldata properties) external;

    function createdAt(uint256 tokenId) external view returns (uint256);

    function price() external view returns (uint160 roundIds, uint256);

    function priceAt(uint160 roundIds) external view returns (uint256);

    function property(
        uint256 tokenId,
        bytes32 key
    ) external view returns (bytes memory value);

    function propertyBatch(
        uint256 tokenId,
        bytes32[] calldata keys
    ) external view returns (bytes[] memory values);

    function token(address owner) external view returns (uint256);

    function updatedAt(uint256 tokenId) external view returns (uint256);
}
