// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ILemonadeEscrowFactory.sol";
import "./ILemonadeEscrow.sol";
import "./LemonadeEscrowV1.sol";

contract LemonadeEscrowFactoryV1 is Ownable, ILemonadeEscrowFactory {
    address _signer;
    address _feeCollector;
    uint256 _feeAmount;

    event EscrowCreated(address escrow);

    constructor(
        address _initialSigner,
        address _initialFeeCollector,
        uint256 _initialFeeAmount
    ) {
        setSigner(_initialSigner);
        setFeeCollector(_initialFeeCollector);
        setFeeAmount(_initialFeeAmount);
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

    function getFeeCollector() public view returns (address) {
        return _feeCollector;
    }

    function setFeeAmount(uint256 feeAmount) public onlyOwner {
        _feeAmount = feeAmount;
    }

    function getFeeAmount() public view returns (uint256) {
        return _feeAmount;
    }

    function createEscrow(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) external {
        if (_feeAmount > 0 && _feeCollector != address(0)) {
            payable(_feeCollector).transfer(_feeAmount);
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
}
