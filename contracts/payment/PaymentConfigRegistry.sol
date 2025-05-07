// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../utils/NativeCurrencyCheck.sol";
import "../AccessRegistry.sol";

bytes32 constant PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

contract PaymentConfigRegistry is OwnableUpgradeable, NativeCurrencyCheck {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    error InvalidSignature();
    error Forbidden();
    error CannotWithdraw();

    address public accessRegistry;
    address public authorizedSigner;
    uint256 public feePPM;
    address public nativeCurrency;

    uint256[19] __gap;

    event FeeCollected(string eventId, address token, uint256 amount);

    function initialize(
        address registry,
        address signer,
        uint256 ppm
    ) public initializer {
        __Ownable_init();
        accessRegistry = registry;
        authorizedSigner = signer;
        feePPM = ppm;
    }

    function setAccessRegistry(address registry) external onlyOwner {
        accessRegistry = registry;
    }

    function setAuthorizedSigner(address signer) external onlyAdmin {
        authorizedSigner = signer;
    }

    function setFeePPM(uint256 ppm) external onlyAdmin {
        feePPM = ppm;
    }

    function setNativeCurrency(address currency) external onlyAdmin {
        nativeCurrency = currency;
    }

    function withdraw(
        address token,
        uint256 amount,
        address payable destination
    ) external onlyAdmin {
        bool success;

        if (isNative(token)) {
            (success, ) = destination.call{value: amount}("");
        } else {
            success = IERC20(token).transfer(destination, amount);
        }

        if (!success) revert CannotWithdraw();
    }

    function notifyFee(
        string calldata eventId,
        address token,
        uint256 amount
    ) external {
        emit FeeCollected(eventId, token, amount);
    }

    function assertSignature(
        bytes32[] calldata data,
        bytes calldata signature
    ) public view {
        bytes memory encoded;
        uint256 length = data.length;

        for (uint256 i = 0; i < length; ) {
            encoded = abi.encodePacked(encoded, data[i]);

            unchecked {
                ++i;
            }
        }

        address actualSigner = encoded.toEthSignedMessageHash().recover(
            signature
        );

        if (actualSigner != authorizedSigner) {
            revert InvalidSignature();
        }
    }

    function balances(
        address[] calldata currencies
    ) external view returns (uint256[] memory balance_) {
        uint256 length = currencies.length;

        balance_ = new uint256[](length);

        address contractAddress = address(this);

        for (uint256 i = 0; i < length; ) {
            address currency = currencies[i];

            if (isNative(currency)) {
                balance_[i] = contractAddress.balance;
            } else {
                balance_[i] = IERC20(currency).balanceOf(contractAddress);
            }

            unchecked {
                ++i;
            }
        }

        return balance_;
    }

    function isNative(address currency) public view override returns (bool) {
        return currency == nativeCurrency;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyAdmin() {
        if (
            !AccessRegistry(accessRegistry).hasRole(
                PAYMENT_ADMIN_ROLE,
                _msgSender()
            )
        ) {
            revert Forbidden();
        }
        _;
    }
}
