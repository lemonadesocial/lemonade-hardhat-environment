// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./DonationVault.sol";

contract DonationVaultRegistry is OwnableUpgradeable {
    //-- EVENTS
    event DonationVaultCreated(address indexed vault);

    function initialize() public initializer {
        __Ownable_init();
    }

    function createVault(
        address destination,
        bytes32 salt,
        address[] calldata admins
    ) external {
        address owner = _msgSender();

        bytes memory bytecode = abi.encodePacked(
            type(DonationVault).creationCode,
            abi.encode(owner)
        );

        address vault = Create2.deploy(0, salt, bytecode);

        DonationVault donationVault = DonationVault(payable(vault));
        donationVault.initialize(destination, admins);

        emit DonationVaultCreated(vault);
    }
}
