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
    uint256 public feePercent;

    function initialize(
        address _accessRegistry,
        uint256 _feePercent
    ) public initializer {
        accessRegistry = _accessRegistry;
        feePercent = _feePercent;
    }

    function setAuthorizedSigner(address _authorizedSigner) external onlyAdmin {
        authorizedSigner = _authorizedSigner;
    }

    function setFeeVault(address payable _feeVault) external onlyAdmin {
        feeVault = _feeVault;
    }

    function setFeePercent(uint256 _feePercent) external onlyAdmin {
        feePercent = _feePercent;
    }

    function assertSignature(
        bytes32[] calldata _data,
        bytes calldata _signature
    ) public view {
        address actualSigner = abi
            .encode(_data)
            .toEthSignedMessageHash()
            .recover(_signature);

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
