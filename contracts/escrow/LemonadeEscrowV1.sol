// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ILemonadeEscrow.sol";
import "./ILemonadeEscrowFactory.sol";

bytes32 constant ESCROW_DELEGATE_ROLE = keccak256("ESCROW_DELEGATE_ROLE");

contract LemonadeEscrowV1 is
    ILemonadeEscrow,
    PaymentSplitter,
    AccessControlEnumerable
{
    using ECDSA for bytes;
    using ECDSA for bytes32;

    bool public closed;
    uint16 public hostRefundPercent;

    RefundPolicy[] _refundPolicies;
    mapping(uint256 => bool) _paymentCancelled;
    mapping(uint256 => Deposit[]) _deposits;
    ILemonadeEscrowFactory _factory;

    constructor(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 refundPercent,
        RefundPolicy[] memory refundPolicies,
        address factory
    ) PaymentSplitter(payees, shares) {
        if (refundPercent > 100) {
            revert InvalidHostRefundPercent();
        }

        hostRefundPercent = refundPercent;

        //-- check valid refundPolicies
        uint256 refundPoliciesLength = refundPolicies.length;

        if (refundPoliciesLength == 1) {
            RefundPolicy memory policy = refundPolicies[0];

            _assertValidRefundPercent(policy);
            _refundPolicies.push(policy);
        } else if (refundPoliciesLength > 1) {
            RefundPolicy memory current;
            RefundPolicy memory next;

            next = refundPolicies[0];

            _assertValidRefundPercent(next);
            _refundPolicies.push(next);

            for (uint256 i = 1; i < refundPoliciesLength; ) {
                current = next;
                next = refundPolicies[i];

                if (
                    current.timestamp >= next.timestamp ||
                    current.percent <= next.percent
                ) {
                    revert InvalidRefundPolicies();
                }

                _assertValidRefundPercent(next);
                _refundPolicies.push(next);

                unchecked {
                    ++i;
                }
            }
        }

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ESCROW_DELEGATE_ROLE, owner);

        uint256 delegatesLength = delegates.length;
        for (uint256 i; i < delegatesLength; ) {
            _grantRole(ESCROW_DELEGATE_ROLE, delegates[i]);
            unchecked {
                ++i;
            }
        }

        _factory = ILemonadeEscrowFactory(factory);
    }

    //- modifiers

    modifier onlyDelegate() {
        if (!hasRole(ESCROW_DELEGATE_ROLE, _msgSender())) {
            revert AccessDenied();
        }
        _;
    }

    modifier escrowOpen() {
        if (closed) {
            revert EscrowHadClosed();
        }
        _;
    }

    //-- public write functions

    function deposit(
        uint256 paymentId,
        address token,
        uint256 amount
    ) external payable override escrowOpen {
        uint256 value = msg.value;

        if (amount == 0) {
            revert InvalidAmount();
        }

        if (_paymentCancelled[paymentId]) {
            revert PaymentHadCancelled();
        }

        bool isErc20 = token != address(0);
        if ((isErc20 && value != 0) || (!isErc20 && value != amount)) {
            revert InvalidDepositAmount();
        }

        address sender = _msgSender();

        if (isErc20) {
            IERC20(token).transferFrom(sender, address(this), amount);
        }

        _deposits[paymentId].push(Deposit(token, amount));

        emit GuestDeposit(sender, paymentId, token, amount);
    }

    function cancelByGuest(
        uint256 paymentId,
        bytes calldata signature
    ) external override escrowOpen {
        if (_paymentCancelled[paymentId]) {
            revert PaymentHadCancelled();
        }

        //-- calculate refund percent based on policy
        uint16 percent;

        uint256 refundPoliciesLength = _refundPolicies.length;

        for (uint256 i; i < refundPoliciesLength; ) {
            RefundPolicy memory policy = _refundPolicies[
                _refundPolicies.length - 1 - i
            ];

            if (block.timestamp < policy.timestamp) {
                percent = policy.percent;
            }

            unchecked {
                ++i;
            }
        }

        //-- perform refund
        _paymentCancelled[paymentId] = true;
        _refundWithPercent(_msgSender(), paymentId, percent, signature);

        emit PaymentCancelled(paymentId, true);
    }

    function closeEscrow() external override onlyDelegate escrowOpen {
        closed = true;

        emit EscrowClosed();
    }

    function cancel(uint256 paymentId) external override onlyDelegate {
        _paymentCancelled[paymentId] = true;

        emit PaymentCancelled(paymentId, false);
    }

    function claimRefund(
        uint256 paymentId,
        bytes calldata signature
    ) external override {
        address sender = _msgSender();

        if (!canClaimRefund(paymentId)) {
            revert CannotClaimRefund();
        }

        //-- perform refund with hostRefundPercent
        _refundWithPercent(sender, paymentId, hostRefundPercent, signature);

        emit GuestClaimRefund(sender, paymentId);
    }

    //-- public read functions

    function getRefundPolicies()
        external
        view
        override
        returns (RefundPolicy[] memory)
    {
        uint256 length = _refundPolicies.length;

        RefundPolicy[] memory policies = new RefundPolicy[](length);

        for (uint256 i; i < length; ) {
            RefundPolicy memory policy = _refundPolicies[i];

            policies[i] = RefundPolicy(policy.timestamp, policy.percent);

            unchecked {
                ++i;
            }
        }

        return policies;
    }

    function canClaimRefund(
        uint256 paymentId
    ) public view override returns (bool) {
        return closed || _paymentCancelled[paymentId];
    }

    function getDeposits(
        uint256 paymentId
    ) public view override returns (Deposit[] memory) {
        return _deposits[paymentId];
    }

    //-- internal & private functions
    function _assertRefundSigner(
        uint256 paymentId,
        bytes memory signature
    ) internal {
        address actualSigner = abi
            .encode(paymentId)
            .toEthSignedMessageHash()
            .recover(signature);

        address expectedSigner = _factory.getSigner();

        if (actualSigner != expectedSigner) {
            revert InvalidSigner();
        }
    }

    function _assertValidRefundPercent(
        RefundPolicy memory policy
    ) internal pure {
        if (policy.percent > 100) {
            revert InvalidRefundPercent();
        }
    }

    function _refundWithPercent(
        address guest,
        uint256 paymentId,
        uint16 percent,
        bytes memory signature
    ) internal {
        _assertRefundSigner(paymentId, signature);

        if (percent == 0) return;

        Deposit[] memory deposits = getDeposits(paymentId);

        if (deposits.length == 0) {
            revert NoDepositFound();
        }

        //-- clear deposit array to prevent reentrance
        delete _deposits[paymentId];

        uint256 depositsLength = deposits.length;

        for (uint16 i = 0; i < depositsLength; ) {
            Deposit memory dep = deposits[i];

            uint256 amount = (dep.amount * percent) / 100;

            if (dep.token == address(0)) {
                payable(guest).transfer(amount);
            } else {
                IERC20(dep.token).transfer(guest, amount);
            }

            unchecked {
                ++i;
            }
        }
    }
}
