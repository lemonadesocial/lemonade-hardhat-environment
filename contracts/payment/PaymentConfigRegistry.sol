// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../AccessRegistry.sol";

bytes32 constant PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

contract PaymentConfigRegistry is OwnableUpgradeable {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    error InvalidSignature();
    error Forbidden();
    error CannotWithdraw();

    address public accessRegistry;
    address public authorizedSigner;
    uint256 public feePPM;
    uint256[20] __gap;

    event FeeCollected(string eventId, address token, uint256 amount);

    function initialize(
        address registry,
        address signer,
        uint256 ppm
    ) public initializer {
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

    function withdraw(
        address token,
        uint256 amount,
        address payable destination
    ) external onlyAdmin {
        bool success;

        if (token == address(0)) {
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
        address actualSigner = abi
            .encode(data)
            .toEthSignedMessageHash()
            .recover(signature);

        if (actualSigner != authorizedSigner) {
            revert InvalidSignature();
        }
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
