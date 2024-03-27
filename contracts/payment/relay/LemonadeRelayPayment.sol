// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../PaymentConfigRegistry.sol";
import "../PaymentSplitter.sol";

contract RelayPaymentSplitter is PaymentSplitter {
    address relay;

    error Forbidden();

    constructor(
        address _relay,
        address[] memory _payees,
        uint256[] memory _shares
    ) PaymentSplitter(_payees, _shares) {
        relay = _relay;
    }

    function resetPayees(
        address[] memory payees,
        uint256[] memory shares
    ) public {
        if (_msgSender() != relay) revert Forbidden();

        _resetPayees(payees, shares);
    }
}

contract LemonadeRelayPayment is Context, Initializable {
    struct Payment {
        address guest;
        address currency;
        uint256 amount;
    }

    address configRegistry;
    mapping(uint256 => address) paymentSplitters;
    mapping(uint256 => Payment) payments;
    mapping(uint256 => uint256) nonces;

    event OnPay(
        uint256 eventId,
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

    function initialize(address _configRegistry) public initializer {
        configRegistry = _configRegistry;
    }

    /**
     * Register wallets to receive payments of a specific event
     * @param _eventId The event to register
     * @param _nonce The nonce to prevent replay attack
     * @param _signature The signature of Lemonade Backend
     * @param _payees Param of payment splitter
     * @param _shares Param of payment spliter
     */
    function register(
        uint256 _eventId,
        uint256 _nonce,
        bytes calldata _signature,
        address[] calldata _payees,
        uint256[] calldata _shares
    ) external {
        if (_nonce < nonces[_eventId]) revert InvalidNonce();

        bytes32[] memory data = new bytes32[](2);

        data[0] = bytes32(_eventId);
        data[1] = bytes32(_nonce);

        PaymentConfigRegistry(configRegistry).assertSignature(data, _signature);

        address oldSplitter = paymentSplitters[_eventId];

        RelayPaymentSplitter splitter;

        if (oldSplitter != address(0)) {
            splitter = RelayPaymentSplitter(payable(oldSplitter));

            splitter.resetPayees(_payees, _shares);
        } else {
            splitter = new RelayPaymentSplitter(
                address(this),
                _payees,
                _shares
            );

            paymentSplitters[_eventId] = address(splitter);
        }
    }

    /**
     * Guest pays the tickets
     * @param _paymentId The id of the payment
     * @param _eventId The corresponding id of the event
     * @param _currency Token address of the currency, zero address for native currency
     * @param _amount The ticket amount plus fee
     */
    function pay(
        uint256 _paymentId,
        uint256 _eventId,
        address _currency,
        uint256 _amount
    ) external payable {
        if (payments[_paymentId].amount > 0) revert AlreadyPay();
        if (_amount == 0) revert InvalidAmount();

        bool isNative = _currency == address(0);

        if (isNative && msg.value != _amount) revert InvalidAmount();

        address spliter = paymentSplitters[_eventId];

        if (spliter == address(0)) revert NotRegistered();

        address guest = _msgSender();

        PaymentConfigRegistry registry = PaymentConfigRegistry(configRegistry);

        address feeVault = registry.feeVault();
        uint256 feeAmount = (registry.feePercent() * _amount) / 100;
        uint256 transferAmount = _amount - feeAmount;

        if (isNative) {
            (bool success, ) = payable(feeVault).call{value: feeAmount}("");

            if (!success) revert CannotPayFee();

            (success, ) = payable(spliter).call{value: transferAmount}("");

            if (!success) revert CannotPay();
        } else {
            bool success = IERC20(_currency).transferFrom(
                guest,
                feeVault,
                feeAmount
            );

            if (!success) revert CannotPayFee();

            success = IERC20(_currency).transferFrom(
                guest,
                spliter,
                transferAmount
            );

            if (!success) revert CannotPay();
        }

        Payment memory payment = Payment(guest, _currency, _amount);

        payments[_paymentId] = payment;

        emit OnPay(_eventId, guest, _currency, transferAmount);
    }

    /**
     * Release the pending amount to caller
     * @param _eventId The id of the event
     * @param _currencies Array of token addresses, zero address for native currency
     */
    function release(
        uint256 _eventId,
        address[] calldata _currencies
    ) external {
        RelayPaymentSplitter splitter = _getSplitter(_eventId);

        return splitter.release(_currencies, payable(_msgSender()));
    }

    //-- public read functions

    /**
     * Get the pending amount can be released to the payee
     * @param _eventId The id of the event
     * @param _payee Account address of the payee
     * @param _currencies Array of token addresses, zero address for native currency
     */
    function pending(
        uint256 _eventId,
        address _payee,
        address[] calldata _currencies
    ) public view returns (uint256[] memory balances) {
        RelayPaymentSplitter splitter = _getSplitter(_eventId);

        return splitter.pending(_currencies, _payee);
    }

    /**
     * Return all payees registered for the event
     * @param _eventId The id of the event
     */
    function payees(uint256 _eventId) public view returns (Payee[] memory) {
        RelayPaymentSplitter splitter = _getSplitter(_eventId);

        return splitter.allPayees();
    }

    //-- internal functions

    function _getSplitter(
        uint256 _eventId
    ) internal view returns (RelayPaymentSplitter) {
        address splitterAddress = paymentSplitters[_eventId];

        if (splitterAddress == address(0)) revert NotRegistered();

        return RelayPaymentSplitter(payable(splitterAddress));
    }
}
