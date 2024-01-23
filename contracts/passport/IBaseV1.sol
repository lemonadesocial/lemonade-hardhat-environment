// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Shared.sol";

interface IBaseV1 {
    event Assign(address sender, Assignment[] assignments);
    event Claim(address sender, bytes32 network, uint256 tokenId);
    event ExecuteAssign(
        bytes32 indexed network,
        address indexed sender,
        Assignment[] assignments
    );
    event ExecuteClaim(
        bytes32 indexed network,
        address indexed sender,
        uint256 tokenId
    );
    event ExecutePurchase(
        bytes32 indexed network,
        uint256 indexed paymentId,
        address indexed sender,
        address referrer,
        uint256 tokenId,
        bool success
    );
    event ExecuteReserve(
        bytes32 indexed network,
        uint256 indexed paymentId,
        address indexed sender,
        Assignment[] assignments,
        bool success
    );
    event Mint(bytes32 indexed network, address indexed to, uint256 tokenId);

    function assign(Assignment[] calldata assignments) external;

    function claim(bytes32 network) external payable;

    function balanceOf(address owner) external view returns (uint256 balance);

    function networkOf(uint256 tokenId) external view returns (bytes32 network);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function referrals(address referrer) external view returns (uint256);

    function reservations(address owner) external view returns (uint256);

    function token(address owner) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);

    function totalReservations() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
