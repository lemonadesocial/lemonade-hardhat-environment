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
    address public signer;

    address public feeVault;
    uint256 public feePercent;

    function initialize(
        address _accessRegistry,
        address _signer,
        address _feeVault,
        uint256 _feePercent
    ) public initializer {
        accessRegistry = _accessRegistry;
        signer = _signer;
        feeVault = _feeVault;
        feePercent = _feePercent;
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

    function setAuthorizedSigner(address _signer) external onlyAdmin {
        signer = _signer;
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
        bytes memory encoded;
        uint256 length = _data.length;

        for (uint256 i = 0; i < length; ) {
            encoded = abi.encodePacked(encoded, _data[i]);

            unchecked {
                ++i;
            }
        }

        address actualSigner = encoded.toEthSignedMessageHash().recover(
            _signature
        );

        if (actualSigner != signer) {
            revert InvalidSignature();
        }
    }
}
