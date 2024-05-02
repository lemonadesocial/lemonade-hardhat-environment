// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../PaymentConfigRegistry.sol";
import "../PaymentSplitter.sol";

contract RelayPaymentSplitter is PaymentSplitter {
    address internal _relay;

    error Forbidden();

    constructor(
        address relay,
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) {
        _relay = relay;
    }

    function resetPayees(
        address[] memory payees,
        uint256[] memory shares
    ) public {
        if (_msgSender() != _relay) revert Forbidden();

        _resetPayees(payees, shares);
    }
}

contract LemonadeRelayPayment is Context, Initializable {
    struct Payment {
        address guest;
        address currency;
        uint256 amount;
    }

    mapping(bytes32 => Payment) public payments;

    address internal _configRegistry;
    mapping(bytes32 => address) internal _paymentSplitters;
    mapping(bytes32 => uint256) internal _nonces;

    event OnPay(
        bytes32 eventId,
        address guest,
        address currency,
        uint256 amount
    );

    error NotRegistered();
    error AlreadyPay();
    error InvalidNonce();
    error InvalidAmount();
    error CannotPayFee();
    error CannotPay();

    function initialize(address configRegistry) public initializer {
        _configRegistry = configRegistry;
    }

    /**
     * Register wallets to receive payments of a specific event
     * @param eventId The event to register
     * @param nonce The nonce to prevent replay attack
     * @param signature The signature of Lemonade Backend
     * @param payees Param of payment splitter
     * @param shares Param of payment spliter
     */
    function register(
        bytes32 eventId,
        uint256 nonce,
        bytes calldata signature,
        address[] calldata payees,
        uint256[] calldata shares
    ) external {
        if (nonce < _nonces[eventId]) revert InvalidNonce();

        bytes32[] memory data = new bytes32[](2);

        data[0] = eventId;
        data[1] = bytes32(nonce);

        PaymentConfigRegistry(_configRegistry).assertSignature(data, signature);
        _nonces[eventId] = nonce;

        address oldSplitter = _paymentSplitters[eventId];

        RelayPaymentSplitter splitter;

        if (oldSplitter != address(0)) {
            splitter = RelayPaymentSplitter(payable(oldSplitter));

            splitter.resetPayees(payees, shares);
        } else {
            splitter = new RelayPaymentSplitter(address(this), payees, shares);

            _paymentSplitters[eventId] = address(splitter);
        }
    }

    /**
     * Guest pays the tickets
     * @param paymentId The id of the payment
     * @param eventId The corresponding id of the event
     * @param currency Token address of the currency, zero address for native currency
     * @param amount The ticket amount plus fee
     */
    function pay(
        bytes32 paymentId,
        bytes32 eventId,
        address currency,
        uint256 amount
    ) external payable {
        if (payments[paymentId].amount > 0) revert AlreadyPay();
        if (amount == 0) revert InvalidAmount();

        bool isNative = currency == address(0);

        if (isNative && msg.value != amount) revert InvalidAmount();

        address spliter = _paymentSplitters[eventId];

        if (spliter == address(0)) revert NotRegistered();

        address guest = _msgSender();

        PaymentConfigRegistry registry = PaymentConfigRegistry(_configRegistry);

        address feeVault = registry.feeVault();
        uint256 feeAmount = (registry.feePercent() * amount) / 100;
        uint256 transferAmount = amount - feeAmount;

        if (isNative) {
            (bool success, ) = payable(feeVault).call{value: feeAmount}("");

            if (!success) revert CannotPayFee();

            (success, ) = payable(spliter).call{value: transferAmount}("");

            if (!success) revert CannotPay();
        } else {
            bool success = IERC20(currency).transferFrom(
                guest,
                feeVault,
                feeAmount
            );

            if (!success) revert CannotPayFee();

            success = IERC20(currency).transferFrom(
                guest,
                spliter,
                transferAmount
            );

            if (!success) revert CannotPay();
        }

        Payment memory payment = Payment(guest, currency, amount);

        payments[paymentId] = payment;

        emit OnPay(eventId, guest, currency, transferAmount);
    }

    /**
     * Release the pending amount to caller
     * @param eventId The id of the event
     * @param currencies Array of token addresses, zero address for native currency
     */
    function release(bytes32 eventId, address[] calldata currencies) external {
        RelayPaymentSplitter splitter = _getSplitter(eventId);

        return splitter.release(currencies, payable(_msgSender()));
    }

    //-- public read functions

    /**
     * Get the pending amount can be released to the payee
     * @param eventId The id of the event
     * @param payee Account address of the payee
     * @param currencies Array of token addresses, zero address for native currency
     */
    function pending(
        bytes32 eventId,
        address payee,
        address[] calldata currencies
    ) public view returns (uint256[] memory balances) {
        RelayPaymentSplitter splitter = _getSplitter(eventId);

        return splitter.pending(currencies, payee);
    }

    /**
     * Return all payees registered for the event
     * @param eventId The id of the event
     */
    function allPayees(bytes32 eventId) public view returns (Payee[] memory) {
        RelayPaymentSplitter splitter = _getSplitter(eventId);

        return splitter.allPayees();
    }

    //-- internal functions

    function _getSplitter(
        bytes32 eventId
    ) internal view returns (RelayPaymentSplitter) {
        address splitterAddress = _paymentSplitters[eventId];

        if (splitterAddress == address(0)) revert NotRegistered();

        return RelayPaymentSplitter(payable(splitterAddress));
    }
}
