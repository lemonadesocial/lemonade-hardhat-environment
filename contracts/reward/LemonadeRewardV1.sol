// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./RewardVault.sol";

contract LemonadeRewardv1 is IRewardRegistry, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public configRegistry;
    mapping(bytes32 => EnumerableSet.AddressSet) rewardRegistry;

    event RewardVaultCreated(address vault);

    error NotRewardVault(address caller);

    function initialize(address registry) public initializer {
        __Ownable_init();
        configRegistry = registry;
    }

    /**
     * Create a reward vault and transfer the ownership to caller
     */
    function createVault() external {
        address sender = _msgSender();

        RewardVault vault = new RewardVault(sender, this);

        emit RewardVaultCreated(address(vault));
    }

    function registerRewards(bytes32[] calldata rewardIds) external override {
        address caller = _msgSender();

        if (
            !IERC165(caller).supportsInterface(type(IRewardVault).interfaceId)
        ) {
            revert NotRewardVault(caller);
        }

        uint256 length = rewardIds.length;

        for (uint256 i = 0; i < length; ) {
            rewardRegistry[rewardIds[i]].add(caller);

            unchecked {
                ++i;
            }
        }
    }
}
