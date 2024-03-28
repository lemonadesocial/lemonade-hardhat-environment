// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ILemonadeEscrowFactory.sol";
import "./ILemonadeEscrow.sol";
import "./LemonadeEscrowV1.sol";

contract LemonadeEscrowFactoryV1 is Ownable, ILemonadeEscrowFactory {
    address public _signer;
    address _feeCollector;
    uint256 _feeAmount;

    event EscrowCreated(address escrow);

    constructor(
        address initialSigner,
        address initialFeeCollector,
        uint256 initialFeeAmount
    ) {
        setSigner(initialSigner);
        setFeeCollector(initialFeeCollector);
        setFeeAmount(initialFeeAmount);
    }

    function createEscrow(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) external payable {
        if (_feeAmount > 0 && _feeCollector != address(0)) {
            (bool success, ) = payable(_feeCollector).call{
                value: _feeAmount
            }("");

            if (!success) revert CannotPayFee();
        }

        ILemonadeEscrow escrow = new LemonadeEscrowV1(
            owner,
            delegates,
            payees,
            shares,
            hostRefundPercent,
            refundPolicies,
            address(this)
        );

        emit EscrowCreated(address(escrow));
    }

    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    function getSigner() public view override returns (address) {
        return _signer;
    }

    function setFeeCollector(address feeCollector) public onlyOwner {
        _feeCollector = feeCollector;
    }

    function setFeeAmount(uint256 feeAmount) public onlyOwner {
        _feeAmount = feeAmount;
    }
}
