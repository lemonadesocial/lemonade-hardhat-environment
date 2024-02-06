// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ILemonadeEscrowFactory.sol";
import "./ILemonadeEscrow.sol";
import "./LemonadeEscrowV1.sol";

contract LemonadeEscrowFactoryV1 is Ownable, ILemonadeEscrowFactory {
    address _signer;

    event EscrowCreated(address escrow);

    constructor(address _initialSigner) {
        setSigner(_initialSigner);
    }

    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    function getSigner() public view override returns (address) {
        return _signer;
    }

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
            refundPolicies,
            address(this)
        );

        emit EscrowCreated(address(escrow));
    }
}
