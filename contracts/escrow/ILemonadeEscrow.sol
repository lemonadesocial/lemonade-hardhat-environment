// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct RefundPolicy {
    uint256 timestamp;
    uint16 percent;
}

struct Deposit {
    address token;
    uint256 amount;
}

interface ILemonadeEscrow {
    error AccessDenied();
    error CannotClaimRefund();
    error CannotRefund();
    error EscrowHadClosed();
    error InvalidAmount();
    error InvalidDepositAmount();
    error InvalidHostRefundPercent();
    error InvalidRefundPercent();
    error InvalidRefundPolicies();
    error InvalidSigner();
    error NoDepositFound();
    error PaymentRefunded();

    event GuestDeposit(
        address guest,
        uint256 paymentId,
        address token,
        uint256 amount
    );
    event GuestClaimRefund(address guest, uint256 paymentId);
    event EscrowClosed();
    event PaymentCancelled(uint256 paymentId, bool byGuest);

    /**
     * Update the escrow config
     * @param delegates array of delegate address
     * @param payees array of payees
     * @param shares array of shares of payees
     * @param refundPercent host refund percent
     * @param refundPolicies new refund policies
     */
    function updateEscrow(
        address[] calldata delegates,
        address[] calldata payees,
        uint256[] calldata shares,
        uint16 refundPercent,
        RefundPolicy[] calldata refundPolicies
    ) external;

    /**
     * Deposit an amount of ERC20 / native token to the payment.
     * Incase of ERC20 deposit, guest have to approve the allowance to the contract before calling this.
     * Revert if both ERC20 and native token are sent at a same time.
     * @param paymentId id of the payment to deposit
     * @param token contract address of token, zero address for native token
     * @param amount the amount to deposit, if native token then this must match msg.value
     */
    function deposit(
        uint256 paymentId,
        address token,
        uint256 amount
    ) external payable;

    /**
     * Return the all deposits for the payments
     * @param paymentIds ids of the payments
     */
    function getDeposits(
        uint256[] calldata paymentIds
    ) external view returns (Deposit[][] memory);

    /**
     * Return the all refunded amount for the payments
     * @param paymentIds ids of the payments
     */
    function getRefunds(
        uint256[] calldata paymentIds
    ) external view returns (Deposit[][] memory);

    /**
     * Get the refund timestamp
     * @param paymentId Id of the payment
     */
    function getRefundAt(uint256 paymentId) external view returns (uint256);

    /**
     * Cancel and refund the deposit amount to caller, both ERC20 and native token if any.
     * Refund amount affected by policies. If escrow is closed then must call claimRefund instead.
     * @param paymentId id of the payment
     */
    function cancelAndRefund(
        uint256 paymentId,
        bool fullRefund,
        bytes calldata signature
    ) external;

    /**
     * After escrow is closed, guests can no more deposit.
     */
    function closeEscrow() external;

    /**
     * Check if the caller can claim refund for the payment.
     * @param paymentId id of the payment to check
     */
    function canRefund(uint256 paymentId) external view returns (bool);

    /**
     * Return the refund policies
     */
    function getRefundPolicies() external view returns (RefundPolicy[] memory);
}
