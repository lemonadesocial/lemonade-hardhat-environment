// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./DelegateManager.sol";
import "./ILemonadeEscrow.sol";

contract LemonadeEscrowV1 is
    ILemonadeEscrow,
    Ownable,
    PaymentSplitter,
    DelegateManager
{
    event GuestDeposit(
        address guest,
        uint256 paymentId,
        address token,
        uint256 amount
    );
    event GuestClaimRefund(address guest, uint256 paymentId);
    event EscrowClosed();
    event PaymentCancelled(uint256 paymentId, bool byGuest);

    uint64 internal _startTime;
    uint64 internal _endTime;

    bool internal _closed;
    uint16 internal _hostRefundPercent;
    RefundPolicy[] internal _refundPolicies;

    mapping(uint256 => bool) _paymentCancelled; //-- map paymentId
    mapping(address => mapping(uint256 => Deposit[])) _deposits; //-- map user -> paymentId

    constructor(
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint64 startTime,
        uint64 endTime,
        uint16 hostRefundPercent,
        RefundPolicy[] memory refundPolicies
    ) PaymentSplitter(payees, shares) DelegateManager(delegates) {
        require(startTime < endTime, "startTime must be smaller than endTime");
        require(hostRefundPercent <= 100, "Invalid hostRefundPercent");

        //-- check valid refundPolicies
        if (refundPolicies.length == 1) {
            _assertValidRefundPercent(refundPolicies[0]);
        } else if (refundPolicies.length > 1) {
            _assertValidRefundPercent(refundPolicies[0]);

            for (uint256 i = 0; i < refundPolicies.length - 1; i++) {
                require(
                    refundPolicies[i].timestamp <
                        refundPolicies[i + 1].timestamp &&
                        refundPolicies[i].percent >
                        refundPolicies[i + 1].percent,
                    "Invalid refund policy order & percent"
                );

                _assertValidRefundPercent(refundPolicies[i + 1]);
            }
        }

        _startTime = startTime;
        _endTime = endTime;
        _hostRefundPercent = hostRefundPercent;

        for (uint256 i = 0; i < refundPolicies.length; i++) {
            _refundPolicies.push(refundPolicies[i]);
        }

        _transferOwnership(owner);
    }

    //- modifiers

    modifier onlyBeforeStart() {
        require(block.timestamp < _startTime, "Only before start");
        _;
    }

    modifier onlyOwnerOrDelegate() {
        require(
            msg.sender == owner() || isDelegate(msg.sender),
            "Must be owner or delegate"
        );
        _;
    }

    modifier escrowOpen() {
        require(!_closed, "Escrow had been closed");
        _;
    }

    //-- public write functions

    function addDelegates(
        address[] memory addresses
    ) public override onlyOwner {
        return super.addDelegates(addresses);
    }

    function removeDelegates(
        address[] memory addresses
    ) public override onlyOwner {
        return super.removeDelegates(addresses);
    }

    function deposit(
        uint256 paymentId,
        address token,
        uint256 amount
    ) external payable override onlyBeforeStart escrowOpen {
        require(!_paymentCancelled[paymentId], "Payment had been cancelled");
        require(amount > 0, "Amount must not be zero");

        if (token == address(0)) {
            require(msg.value == amount, "Amount not matched");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        _deposits[msg.sender][paymentId].push(Deposit(token, amount));

        emit GuestDeposit(msg.sender, paymentId, token, amount);
    }

    function cancelByGuest(
        uint256 paymentId
    ) external override onlyBeforeStart escrowOpen {
        require(
            !_paymentCancelled[paymentId],
            "Payment had already been cancelled"
        );

        //-- calculate refund percent based on policy
        uint256 percent = 0;

        for (uint256 i = _refundPolicies.length - 1; i >= 0; i--) {
            RefundPolicy memory policy = _refundPolicies[i];

            if (block.timestamp <= policy.timestamp) {
                percent = policy.percent;
            }
        }

        //-- perform refund
        _refundWithPercent(msg.sender, paymentId, percent);

        emit PaymentCancelled(paymentId, true);
    }

    function closeEscrow() external override onlyOwnerOrDelegate escrowOpen {
        _closed = true;

        emit EscrowClosed();
    }

    function cancel(uint256 paymentId) external override onlyOwnerOrDelegate {
        _paymentCancelled[paymentId] = true;

        emit PaymentCancelled(paymentId, false);
    }

    function claimRefund(uint256 paymentId) external override {
        require(
            canClaimRefund(paymentId),
            "Payment is not cancelled or escrow is not closed"
        );

        //-- perform refund with _hostRefundPercent
        _refundWithPercent(msg.sender, paymentId, _hostRefundPercent);

        emit GuestClaimRefund(msg.sender, paymentId);
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
        require(policy.percent <= 100, "Invalid refund percent");
    }

    function _refundWithPercent(
        address guest,
        uint256 paymentId,
        uint256 percent
    ) internal {
        /**
         * Note that, in theory, a same ERC20 transfer can happen multiple times because the deposit array can contain multiple deposits for a same token.
         * But the reason for this is because user had perform multiple deposits with the same payment and same token.
         * This function should only trigger by user. So it's up to user to optimize his calls.
         *  */

        if (percent == 0) return;

        Deposit[] memory deposits = getDeposits(paymentId, guest);

        require(deposits.length > 0, "No deposit found");

        //-- clear deposit array to prevent reentrance
        delete _deposits[msg.sender][paymentId];

        for (uint256 i = 0; i < deposits.length; i++) {
            Deposit memory dep = deposits[i];

            uint256 amount = (dep.amount * percent) / 100;

            if (dep.token == address(0)) {
                payable(msg.sender).transfer(amount);
            } else {
                IERC20(dep.token).transfer(msg.sender, amount);
            }
        }
    }
}
