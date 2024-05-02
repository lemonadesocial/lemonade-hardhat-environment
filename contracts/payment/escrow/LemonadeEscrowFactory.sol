// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./LemonadeEscrowV1.sol";

contract LemonadeEscrowFactory is OwnableUpgradeable {
    address public registry;
    uint256 public feeAmount;

    event EscrowCreated(address escrow, uint256 fee);

    error CannotPayFee();
    error NotOwner();

    function initialize(
        address _registry,
        uint256 _feeAmount
    ) public initializer {
        __Ownable_init();

        registry = _registry;
        feeAmount = _feeAmount;
    }

    function createEscrow(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) external payable {
        if (feeAmount > 0) {
            PaymentConfigRegistry registry_ = PaymentConfigRegistry(registry);

            (bool success, ) = payable(registry_.feeVault()).call{
                value: feeAmount
            }("");

            if (!success) revert CannotPayFee();
        }

        LemonadeEscrowV1 escrow = new LemonadeEscrowV1(
            registry,
            owner,
            delegates,
            payees,
            shares,
            hostRefundPercent,
            refundPolicies
        );

        emit EscrowCreated(address(escrow), feeAmount);
    }

    function setFeeAmount(uint256 _feeAmount) public onlyOwner {
        feeAmount = _feeAmount;
    }

    function _checkOwner() internal view virtual override {
        if (owner() != _msgSender()) revert NotOwner();
    }
}
