// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../PaymentConfigRegistry.sol";
import "../PaymentSplitter.sol";

contract RelayPaymentSplitter is PaymentSplitter {
    address internal _owner;

    error Forbidden();

    constructor(
        address owner,
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) {
        _owner = owner;
    }

    function resetPayees(
        address[] memory payees,
        uint256[] memory shares
    ) public {
        if (_msgSender() != _owner) revert Forbidden();

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
    mapping(address => bool) public splitters;

    address internal _configRegistry;

    event OnRegister(address splitter);

    event OnPay(
        address splitter,
        bytes32 paymentId,
        address guest,
        address currency,
        uint256 amount
    );

    error NotRegistered();
    error AlreadyPay();
    error InvalidAmount();
    error CannotPayFee();
    error CannotPay();

    function initialize(address configRegistry) public initializer {
        _configRegistry = configRegistry;
    }

    /**
     * Register wallets to receive payments of a specific event
     * @param payees Param of payment splitter
     * @param shares Param of payment splitter
     */
    function register(
        address[] calldata payees,
        uint256[] calldata shares
    ) external {
        RelayPaymentSplitter splitter = new RelayPaymentSplitter(
            _msgSender(),
            payees,
            shares
        );

        address splitterAddress = address(splitter);

        splitters[splitterAddress] = true;

        emit OnRegister(splitterAddress);
    }

    /**
     * Guest pays the tickets
     * @param splitter The address of the registered splitter
     * @param paymentId The id of the payment
     * @param currency Token address of the currency, zero address for native currency
     * @param amount The ticket amount plus fee
     */
    function pay(
        address splitter,
        bytes32 paymentId,
        address currency,
        uint256 amount
    ) external payable {
        if (payments[paymentId].amount > 0) revert AlreadyPay();
        if (amount == 0) revert InvalidAmount();

        bool isNative = currency == address(0);

        if (isNative && msg.value != amount) revert InvalidAmount();

        if (!splitters[splitter]) revert NotRegistered();

        address guest = _msgSender();

        PaymentConfigRegistry registry = PaymentConfigRegistry(_configRegistry);

        address feeVault = registry.feeVault();
        uint256 feeAmount = (registry.feePPM() * amount) / 1000000;
        uint256 transferAmount = amount - feeAmount;

        if (isNative) {
            (bool success, ) = payable(feeVault).call{value: feeAmount}("");

            if (!success) revert CannotPayFee();

            (success, ) = payable(splitter).call{value: transferAmount}("");

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
                splitter,
                transferAmount
            );

            if (!success) revert CannotPay();
        }

        Payment memory payment = Payment(guest, currency, amount);

        payments[paymentId] = payment;

        emit OnPay(splitter, paymentId, guest, currency, transferAmount);
    }
}
