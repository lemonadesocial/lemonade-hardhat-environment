// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        bytes32 paymentRef
    );

    mapping(bytes32 => PaymentInfo) public payments;

    error ReferenceAlreadyUsed();
    error AmountMustBePositive();
    error InvalidDestination();
    error InvalidToken();

    function pay(
        address token,
        uint256 amount,
        address destination,
        bytes32 paymentRef
    ) external {
        if (payments[paymentRef].payer != address(0)) revert ReferenceAlreadyUsed();
        if (token == address(0)) revert InvalidToken();
        if (amount == 0) revert AmountMustBePositive();
        if (destination == address(0)) revert InvalidDestination();

        payments[paymentRef] = PaymentInfo(msg.sender, token, amount, destination);

        IERC20(token).safeTransferFrom(msg.sender, destination, amount);

        emit PaymentForwarded(msg.sender, token, destination, amount, paymentRef);
    }
}
