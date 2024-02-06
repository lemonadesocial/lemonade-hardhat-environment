// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

import "./ILemonadeEscrow.sol";

bytes32 constant ESCROW_DELEGATE_ROLE = keccak256("ESCROW_DELEGATE_ROLE");

contract LemonadeEscrowV1 is
    ILemonadeEscrow,
    PaymentSplitter,
    AccessControlEnumerable
{
    bool internal _closed;
    uint16 internal _hostRefundPercent;
    RefundPolicy[] internal _refundPolicies;
    mapping(uint256 => bool) internal _paymentCancelled; //-- map paymentId
    mapping(address => mapping(uint256 => Deposit[])) internal _deposits; //-- map user -> paymentId

    constructor(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) PaymentSplitter(payees, shares) {
        if (hostRefundPercent > 100) {
            revert InvalidHostRefundPercent();
        }

        _hostRefundPercent = hostRefundPercent;

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

        _deposits[sender][paymentId].push(Deposit(token, amount));

        emit GuestDeposit(sender, paymentId, token, amount);
    }

    function cancelByGuest(uint256 paymentId) external override escrowOpen {
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
        _refundWithPercent(_msgSender(), paymentId, percent);

        emit PaymentCancelled(paymentId, true);
    }

    //-- pausable
    function closeEscrow() external override onlyDelegate escrowOpen {
        _closed = true;

        emit EscrowClosed();
    }

    function cancel(uint256 paymentId) external override onlyDelegate {
        _paymentCancelled[paymentId] = true;

        emit PaymentCancelled(paymentId, false);
    }

    function claimRefund(uint256 paymentId) external override {
        address sender = _msgSender();

        if (!canClaimRefund(paymentId)) {
            revert CannotClaimRefund();
        }

        //-- perform refund with _hostRefundPercent
        _refundWithPercent(sender, paymentId, _hostRefundPercent);

        emit GuestClaimRefund(sender, paymentId);
    }

    //-- public read functions

    function canClaimRefund(
        uint256 paymentId
    ) public view override returns (bool) {
        return _closed || _paymentCancelled[paymentId];
    }

    function getDeposits(
        uint256 paymentId,
        address guest
    ) public view override returns (Deposit[] memory) {
        return _deposits[guest][paymentId];
    }

    //-- internal & private functions

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
        uint16 percent
    ) internal {
        /**
         * Note that, in theory, a same ERC20 transfer can happen multiple times because the deposit array can contain multiple deposits for a same token.
         * But the reason for this is because user had perform multiple deposits with the same payment and same token.
         * This function should only trigger by user. So it's up to user to optimize his calls.
         *  */

        if (percent == 0) return;

        Deposit[] memory deposits = getDeposits(paymentId, guest);

        if (deposits.length == 0) {
            revert NoDepositFound();
        }

        address sender = _msgSender();

        //-- clear deposit array to prevent reentrance
        delete _deposits[sender][paymentId];

        uint256 depositsLength = deposits.length;

        for (uint16 i = 0; i < depositsLength; ) {
            Deposit memory dep = deposits[i];

            uint256 amount = (dep.amount * percent) / 100;

            if (dep.token == address(0)) {
                payable(sender).transfer(amount);
            } else {
                IERC20(dep.token).transfer(sender, amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    //- modifiers

    modifier onlyDelegate() {
        if (!hasRole(ESCROW_DELEGATE_ROLE, _msgSender())) {
            revert AccessDenied();
        }
        _;
    }

    modifier escrowOpen() {
        if (_closed) {
            revert EscrowHadClosed();
        }
        _;
    }
}
