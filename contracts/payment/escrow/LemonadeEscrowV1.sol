// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "../PaymentConfigRegistry.sol";
import "../PaymentSplitter.sol";

bytes32 constant ESCROW_DELEGATE_ROLE = keccak256("ESCROW_DELEGATE_ROLE");

struct RefundPolicy {
    uint256 timestamp;
    uint16 percent;
}

struct Deposit {
    address token;
    uint256 amount;
}

contract LemonadeEscrowV1 is AccessControlEnumerable, PaymentSplitter {
    bool public closed;
    uint16 public hostRefundPercent;
    RefundPolicy[] public refundPolicies;

    PaymentConfigRegistry internal _registry;
    mapping(bytes32 => uint256) internal _paymentRefundAt;
    mapping(bytes32 => Deposit[]) internal _paymentRefund;
    mapping(bytes32 => Deposit[]) internal _deposits;
    mapping(bytes32 => bool) internal _feeCollected;

    event GuestDeposit(
        address guest,
        bytes32 paymentId,
        address token,
        uint256 amount
    );
    event GuestClaimRefund(address guest, string paymentId);
    event EscrowClosed();
    event PaymentCancelled(bytes32 paymentId, bool byGuest);

    error AccessDenied();
    error CannotRefund();
    error EscrowHadClosed();
    error InvalidAmount();
    error InvalidRefundPercent();
    error InvalidRefundPolicies();
    error PaymentRefunded();

    constructor(
        address registry,
        address owner,
        address[] memory delegates,
        address[] memory payees,
        uint256[] memory shares,
        uint16 refundPercent,
        RefundPolicy[] memory policies
    ) PaymentSplitter(payees, shares) {
        _registry = PaymentConfigRegistry(registry);

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ESCROW_DELEGATE_ROLE, owner);

        _setupEscrow(delegates, refundPercent, policies);
    }

    //- modifiers

    modifier onlyDelegate() {
        if (!hasRole(ESCROW_DELEGATE_ROLE, _msgSender())) {
            revert AccessDenied();
        }
        _;
    }

    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
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

    function updateEscrow(
        address[] calldata delegates,
        address[] calldata payees,
        uint256[] calldata shares,
        uint16 refundPercent,
        RefundPolicy[] calldata policies
    ) public onlyOwner escrowOpen {
        //-- reset refund policies
        delete refundPolicies;

        //-- reset delegates
        uint256 count = getRoleMemberCount(ESCROW_DELEGATE_ROLE);

        for (uint256 i = count - 1; i > 0; ) {
            address member = getRoleMember(ESCROW_DELEGATE_ROLE, i);

            if (!hasRole(DEFAULT_ADMIN_ROLE, member)) {
                _revokeRole(ESCROW_DELEGATE_ROLE, member);
            }

            unchecked {
                --i;
            }
        }

        _setupEscrow(delegates, refundPercent, policies);

        _resetPayees(payees, shares);
    }

    function deposit(
        bytes32 paymentId,
        address token,
        uint256 amount
    ) external payable escrowOpen {
        if (_paymentRefundAt[paymentId] > 0) {
            revert PaymentRefunded();
        }

        uint256 value = msg.value;

        if (amount == 0) {
            revert InvalidAmount();
        }

        bool isErc20 = token != address(0);
        if ((isErc20 && value != 0) || (!isErc20 && value != amount)) {
            revert InvalidAmount();
        }

        uint256 feeAmount = 0;
        uint256 feePercent = _registry.feePercent();

        //-- transfer fee to registry
        if (feePercent > 0 && !_feeCollected[paymentId]) {
            feeAmount = feePercent * amount / 100;
        }

        uint256 paymentAmount = amount - feeAmount;

        address sender = _msgSender();

        //-- if there is still amount to split
        if (paymentAmount > 0) {
            if (isErc20) {
                IERC20(token).transferFrom(
                    sender,
                    address(this),
                    paymentAmount
                );
            }
        }

        _deposits[paymentId].push(Deposit(token, amount));

        emit GuestDeposit(sender, paymentId, token, amount);
    }

    function cancelAndRefund(
        bytes32 paymentId,
        bool fullRefund,
        bytes calldata signature
    ) external escrowOpen {
        if (!canRefund(paymentId)) {
            revert CannotRefund();
        }

        uint16 percent;

        _assertRefundSigner(paymentId, fullRefund, signature);

        if (fullRefund) {
            percent = hostRefundPercent;
        } else {
            //-- calculate refund percent based on policy

            uint256 refundPoliciesLength = refundPolicies.length;

            for (uint256 i = refundPoliciesLength; i > 0; ) {
                RefundPolicy memory policy = refundPolicies[i - 1];

                if (block.timestamp < policy.timestamp) {
                    percent = policy.percent;
                }

                unchecked {
                    --i;
                }
            }
        }

        //-- perform refund with the corresponding percent
        _refundWithPercent(_msgSender(), paymentId, percent);

        emit PaymentCancelled(paymentId, true);
    }

    function closeEscrow() external onlyDelegate escrowOpen {
        closed = true;

        emit EscrowClosed();
    }

    //-- public read functions

    function getRefundAt(bytes32 paymentId) external view returns (uint256) {
        return _paymentRefundAt[paymentId];
    }

    function getRefundPolicies() external view returns (RefundPolicy[] memory) {
        uint256 length = refundPolicies.length;

        RefundPolicy[] memory policies = new RefundPolicy[](length);

        for (uint256 i; i < length; ) {
            RefundPolicy memory policy = refundPolicies[i];

            policies[i] = RefundPolicy(policy.timestamp, policy.percent);

            unchecked {
                ++i;
            }
        }

        return policies;
    }

    function canRefund(bytes32 paymentId) public view returns (bool) {
        return
            _deposits[paymentId].length > 0 && _paymentRefundAt[paymentId] == 0;
    }

    function getDeposits(
        bytes32[] calldata paymentIds
    ) public view returns (Deposit[][] memory allPaymentDeposits) {
        uint256 paymentIdsLength = paymentIds.length;

        allPaymentDeposits = new Deposit[][](paymentIdsLength);

        for (uint16 i = 0; i < paymentIdsLength; ) {
            Deposit[] memory deposits = _loadDeposits(paymentIds[i]);

            allPaymentDeposits[i] = deposits;

            unchecked {
                ++i;
            }
        }

        return allPaymentDeposits;
    }

    function getRefunds(
        bytes32[] calldata paymentIds
    ) external view returns (Deposit[][] memory allRefunds) {
        uint256 paymentIdsLength = paymentIds.length;

        allRefunds = new Deposit[][](paymentIdsLength);

        for (uint16 i = 0; i < paymentIdsLength; ) {
            Deposit[] memory deposits = _loadRefunds(paymentIds[i]);

            allRefunds[i] = deposits;

            unchecked {
                ++i;
            }
        }

        return allRefunds;
    }

    //-- internal & private functions

    function _setupEscrow(
        address[] memory delegates,
        uint16 refundPercent,
        RefundPolicy[] memory policies
    ) internal {
        if (refundPercent > 100) {
            revert InvalidRefundPercent();
        }

        hostRefundPercent = refundPercent;

        //-- check valid refundPolicies
        uint256 refundPoliciesLength = policies.length;

        if (refundPoliciesLength == 1) {
            RefundPolicy memory policy = policies[0];

            _assertValidRefundPercent(policy);
            refundPolicies.push(policy);
        } else if (refundPoliciesLength > 1) {
            RefundPolicy memory current;
            RefundPolicy memory next;

            next = policies[0];

            _assertValidRefundPercent(next);
            refundPolicies.push(next);

            for (uint256 i = 1; i < refundPoliciesLength; ) {
                current = next;
                next = policies[i];

                if (
                    current.timestamp >= next.timestamp ||
                    current.percent <= next.percent
                ) {
                    revert InvalidRefundPolicies();
                }

                _assertValidRefundPercent(next);
                refundPolicies.push(next);

                unchecked {
                    ++i;
                }
            }
        }

        uint256 delegatesLength = delegates.length;
        for (uint256 i; i < delegatesLength; ) {
            _grantRole(ESCROW_DELEGATE_ROLE, delegates[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _refundWithPercent(
        address guest,
        bytes32 paymentId,
        uint16 percent
    ) internal {
        _paymentRefundAt[paymentId] = block.timestamp;

        if (percent == 0) return;

        Deposit[] memory deposits = _loadDeposits(paymentId);

        //-- clear deposit array to prevent reentrance
        delete _deposits[paymentId];

        uint256 depositsLength = deposits.length;

        for (uint16 i = 0; i < depositsLength; ) {
            Deposit memory dep = deposits[i];

            uint256 amount = (dep.amount * percent) / 100;

            if (dep.token == address(0)) {
                (bool success, ) = payable(guest).call{value: amount}("");
                if (!success) revert CannotRefund();
            } else {
                bool success = IERC20(dep.token).transfer(guest, amount);
                if (!success) revert CannotRefund();
            }

            _paymentRefund[paymentId].push(Deposit(dep.token, amount));

            unchecked {
                ++i;
            }
        }
    }

    function _loadDeposits(
        bytes32 paymentId
    ) internal view returns (Deposit[] memory) {
        return _deposits[paymentId];
    }

    function _loadRefunds(
        bytes32 paymentId
    ) internal view returns (Deposit[] memory) {
        return _paymentRefund[paymentId];
    }

    function _assertRefundSigner(
        bytes32 paymentId,
        bool fullRefund,
        bytes memory signature
    ) internal view {
        bytes32[] memory data = new bytes32[](2);

        data[0] = bytes32(paymentId);
        data[1] = bytes32(uint256(fullRefund ? 1 : 0));

        _registry.assertSignature(data, signature);
    }

    function _assertValidRefundPercent(
        RefundPolicy memory policy
    ) internal pure {
        if (policy.percent > 100) {
            revert InvalidRefundPercent();
        }
    }
}
