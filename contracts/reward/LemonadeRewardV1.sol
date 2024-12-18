// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./RewardVault.sol";

contract LemonadeRewardv1 is IRewardRegistry, OwnableUpgradeable {
    //-- TYPE DEFINITION
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Reward {
        address vault;
        RewardSetting[] settings;
    }

    //-- STORAGE AREA
    address public configRegistry;
    mapping(bytes32 => EnumerableSet.AddressSet) rewardRegistry; //-- key is rewardId

    //-- EVENTS
    event RewardVaultCreated(address vault);

    //-- ERRORS
    error NotRewardVault(address caller);
    error InvalidData();

    function initialize(address registry) public initializer {
        __Ownable_init();
        configRegistry = registry;
    }

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

    function checkRewards(
        bytes32[] calldata rewardIds
    ) external view returns (Reward[][] memory rewards) {
        uint256 rewardLength = rewardIds.length;

        if (rewardLength == 0) {
            revert InvalidData();
        }

        rewards = new Reward[][](rewardLength);

        for (uint256 i = 0; i < rewardLength; ) {
            bytes32 rewardId = rewardIds[i];
            EnumerableSet.AddressSet storage vaults = rewardRegistry[rewardId];

            uint256 vaultLength = vaults.length();

            if (vaultLength == 0) continue;

            Reward[] memory rewardVaults = new Reward[](vaultLength);

            for (uint256 j = 0; j < vaultLength; ) {
                IRewardVault vault = IRewardVault(payable(vaults.at(j)));

                RewardSetting[] memory settings = vault.listRewards(rewardId);

                rewardVaults[j] = Reward(address(vault), settings);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    function claimRewards() external {

    }
}
