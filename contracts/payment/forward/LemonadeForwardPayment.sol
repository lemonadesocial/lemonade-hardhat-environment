// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LemonadeForwardPayment {
    using SafeERC20 for IERC20;

    struct PaymentInfo {
        address payer;
        address token;
        uint256 amount;
        address destination;
    }

    event PaymentForwarded(
        address indexed payer,
        address indexed token,
        address indexed destination,
        uint256 amount,
        bytes32 reference
    );

    mapping(bytes32 => PaymentInfo) public payments;

    error ReferenceAlreadyUsed();
    error AmountMustBePositive();
    error InvalidDestination();

    function pay(
        address token,
        uint256 amount,
        address destination,
        bytes32 reference
    ) external {
        if (payments[reference].payer != address(0)) revert ReferenceAlreadyUsed();
        if (amount == 0) revert AmountMustBePositive();
        if (destination == address(0)) revert InvalidDestination();

        payments[reference] = PaymentInfo(msg.sender, token, amount, destination);

        IERC20(token).safeTransferFrom(msg.sender, destination, amount);

        emit PaymentForwarded(msg.sender, token, destination, amount, reference);
    }
}
