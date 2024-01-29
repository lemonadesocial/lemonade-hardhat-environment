// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPassportV1.sol";

interface ICrowdfundV1 {
    event Create(
        address creator,
        string title,
        string description,
        Assignment[] assignments,
        uint256 campaignId
    );
    event Fund(uint256 indexed campaignId, uint256 amount);
    event Execute(uint256 indexed campaignId);

    enum State {
        PENDING,
        EXECUTED,
        CONFIRMED,
        REFUNDED
    }

    function create(
        string memory title_,
        string memory description_,
        Assignment[] calldata assignments_
    ) external returns (uint256 campaignId);

    function execute(uint256 campaignId, uint160 roundIds) external payable;

    function fund(uint256 campaignId) external payable;

    function refund(uint256 campaignId) external;

    function assignments(
        uint256 campaignId
    ) external view returns (Assignment[] memory);

    function contributors(
        uint256 campaignId
    ) external view returns (address[] memory);

    function creator(uint256 campaignId) external view returns (address);

    function description(
        uint256 campaignId
    ) external view returns (string memory);

    function goal(
        uint256 campaignId
    ) external view returns (uint160 roundIds, uint256 amount);

    function state(uint256 campaignId) external view returns (State);

    function title(uint256 campaignId) external view returns (string memory);

    function total(uint256 campaignId) external view returns (uint256);
}
