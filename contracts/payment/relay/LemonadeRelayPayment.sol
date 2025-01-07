// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../PaymentConfigRegistry.sol";
import "../PaymentSplitter.sol";

contract RelayPaymentSplitter is PaymentSplitter, AccessControl {
    constructor(
        address owner,
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function resetPayees(
        address[] memory payees,
        uint256[] memory shares
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetPayees(payees, shares);
    }
}

contract LemonadeRelayPayment is OwnableUpgradeable {
    struct Payment {
        address guest;
        address currency;
        uint256 amount;
    }

    address public configRegistry;
    mapping(bytes32 => Payment) internal payments;
    mapping(address => bool) internal splitters;
    uint256[20] __gap;

    event OnRegister(address splitter);

    event OnPay(
        address splitter,
        string eventId,
        string paymentId,
        address guest,
        address currency,
        uint256 amount
    );

    error NotRegistered();
    error AlreadyPay();
    error InvalidAmount();
    error CannotPayFee();
    error CannotPay();

    function initialize() public initializer {
        __Ownable_init();
    }

    function setConfigRegistry(address registry) external onlyOwner {
        configRegistry = registry;
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

    function getPayment(
        string calldata paymentId
    ) external view returns (Payment memory) {
        bytes32 id = _toId(paymentId);

        return payments[id];
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
        string memory eventId,
        string memory paymentId,
        address currency,
        uint256 amount
    ) external payable {
        if (amount == 0) revert InvalidAmount();

        bytes32 id = _toId(paymentId);

        if (payments[id].amount > 0) revert AlreadyPay();

        if (!splitters[splitter]) revert NotRegistered();

        bool isNative = currency == address(0);

        if (isNative && msg.value != amount) revert InvalidAmount();

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        uint256 transferAmount = (amount * 1000000) /
            (registry.feePPM() + 1000000);
        uint256 feeAmount = amount - transferAmount;

        address guest = _msgSender();

        if (isNative) {
            (bool success, ) = payable(configRegistry).call{value: feeAmount}(
                ""
            );

            if (!success) revert CannotPayFee();

            (success, ) = payable(splitter).call{value: transferAmount}("");

            if (!success) revert CannotPay();
        } else {
            bool success = IERC20(currency).transferFrom(
                guest,
                configRegistry,
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

        registry.notifyFee(eventId, currency, feeAmount);

        Payment memory payment = Payment(guest, currency, amount);

        payments[id] = payment;

        emit OnPay(
            splitter,
            eventId,
            paymentId,
            guest,
            currency,
            transferAmount
        );
    }

    function _toId(string memory id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id));
    }
}
