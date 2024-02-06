// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ILemonadeEscrow.sol";
import "./LemonadeEscrowV1.sol";

contract LemonadeEscrowFactoryV1 {
    event EscrowCreated(address escrow);

    function createEscrow(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) external {
        ILemonadeEscrow escrow = new LemonadeEscrowV1(
            owner,
            delegates,
            payees,
            shares,
            hostRefundPercent,
            refundPolicies
        );

        emit EscrowCreated(address(escrow));
    }
}
