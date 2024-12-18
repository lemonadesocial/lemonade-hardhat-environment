// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

interface IRewardRegistry {
    function registerRewards(bytes32[] calldata rewardIds) external;
}

interface IRewardVault {
    function reward(
        address destination,
        bytes32 rewardId,
        uint256 count
    ) external;

    function listRewards(
        bytes32 rewardId
    ) external view returns (RewardSetting[] memory settings);
}

struct RewardSetting {
    address currency;
    uint256 amount;
}

contract RewardVault is IRewardVault, AccessControl {
    //-- TYPE DEFINITION
    using EnumerableSet for EnumerableSet.AddressSet;

    //-- STORAGE AREA
    IRewardRegistry rewardRegistry;
    mapping(bytes32 => EnumerableSet.AddressSet) rewardCurrencies;
    mapping(bytes32 => mapping(address => uint256)) rewardSettings; //-- first key is reward id, second key is currency, value is reward amount

    uint256[10] ___gap;

    //-- ERRORS
    error CannotWithdraw();
    error InvalidData();

    constructor(address owner, IRewardRegistry registry) {
        grantRole(DEFAULT_ADMIN_ROLE, owner);
        grantRole(OPERATOR_ROLE, address(rewardRegistry));

        rewardRegistry = registry;
    }

    function withdraw(
        address currency,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address sender = _msgSender();

        if (currency == address(0)) {
            (bool success, ) = payable(sender).call{value: amount}("");

            if (!success) revert CannotWithdraw();
        } else {
            bool success = IERC20(currency).transferFrom(
                address(this),
                sender,
                amount
            );

            if (!success) revert CannotWithdraw();
        }
    }

    function setRewards(
        bytes32[] calldata rewardIds,
        RewardSetting[] calldata settings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 rewardLength = rewardIds.length;
        uint256 settingLength = settings.length;

        if (rewardLength == 0 || rewardLength != settingLength) {
            revert InvalidData();
        }

        rewardRegistry.registerRewards(rewardIds);

        for (uint256 i = 0; i < rewardLength; ) {
            RewardSetting calldata setting = settings[i];
            bytes32 rewardId = rewardIds[i];
            address currency = setting.currency;

            rewardSettings[rewardId][currency] = setting.amount;
            rewardCurrencies[rewardId].add(currency);

            unchecked {
                ++i;
            }
        }
    }

    function reward(
        address destination,
        bytes32 rewardId,
        uint256 count
    ) external override onlyRole(OPERATOR_ROLE) {}

    function listRewards(
        bytes32 rewardId
    ) external view override returns (RewardSetting[] memory settings) {
        EnumerableSet.AddressSet storage currencies = rewardCurrencies[
            rewardId
        ];

        uint256 currencyLength = currencies.length();

        if (currencyLength == 0) {
            return settings;
        }

        RewardSetting[] memory currencySettings = new RewardSetting[](
            currencyLength
        );

        for (uint256 i = 0; i < currencyLength; ) {
            address currency = currencies.at(i);

            currencySettings[i] = RewardSetting(
                currency,
                rewardSettings[rewardId][currency]
            );

            unchecked {
                ++i;
            }
        }

        return settings;
    }

    receive() external payable {}
}
