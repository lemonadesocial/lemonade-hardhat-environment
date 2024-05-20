// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../AccessRegistry.sol";

bytes32 constant PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

contract PaymentConfigRegistry is Context, Initializable {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    error InvalidSignature();
    error Forbidden();

    address public accessRegistry;
    address public authorizedSigner;

    address public feeVault;
    uint256 public feePPM;

    function initialize(
        address registry,
        address signer,
        address vault,
        uint256 ppm
    ) public initializer {
        accessRegistry = registry;
        authorizedSigner = signer;
        feeVault = vault;
        feePPM = ppm;
    }

    function setAuthorizedSigner(address signer) external onlyAdmin {
        authorizedSigner = signer;
    }

    function setFeeVault(address vault) external onlyAdmin {
        feeVault = vault;
    }

    function setFeePPM(uint256 ppm) external onlyAdmin {
        feePPM = ppm;
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
