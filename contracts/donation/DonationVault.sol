// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Vault.sol";

bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

contract DonationVault is Vault {
    //-- DATA
    bool inited;
    address public destination;

    //-- ERRORS
    error InvalidData();
    error AlreadyInited();
    error InvalidDestination();

    //-- EVENTS
    event DestinationUpdated(
        address indexed sender,
        address indexed destination
    );

    event NewDonation(
        string indexed category,
        string indexed ref,
        address indexed from,
        address currency,
        uint256 amount
    );

    event Withdrawal(
        address indexed destination,
        address indexed currency,
        uint256 amount
    );

    constructor(address owner) {
        address registry = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, registry);
    }

    function initialize(
        address dest,
        address[] calldata admins
    ) public onlyRole(OPERATOR_ROLE) {
        if (inited) {
            revert AlreadyInited();
        }

        inited = true;
        destination = dest;

        uint256 adminLength = admins.length;

        for (uint256 i = 0; i < adminLength; ) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setDestination(
        address dest
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        destination = dest;

        emit DestinationUpdated(_msgSender(), dest);
    }

    function withdrawToDestination(
        address[] calldata currencies,
        uint256[] calldata amounts
    ) external {
        if (destination == address(0)) {
            revert InvalidDestination();
        }

        uint256 length = currencies.length;

        if (length == 0 || length != amounts.length) {
            revert InvalidData();
        }

        for (uint256 i = 0; i < length; ) {
            address currency = currencies[i];
            uint256 amount = amounts[i];

            _transfer(destination, currency, amount);

            emit Withdrawal(destination, currency, amount);
            unchecked {
                ++i;
            }
        }
    }

    function donate(
        address currency,
        uint256 amount,
        string calldata category,
        string calldata ref
    ) external payable {
        address sender = _msgSender();

        bool isNative = currency == address(0);

        //-- transfer the amount from caller to vault

        if (isNative) {
            if (msg.value != amount) {
                revert InvalidData();
            }
        } else {
            bool success = IERC20(currency).transferFrom(
                sender,
                address(this),
                amount
            );

            if (!success) {
                revert CannotTransfer();
            }
        }

        emit NewDonation(category, ref, sender, currency, amount);
    }
}
