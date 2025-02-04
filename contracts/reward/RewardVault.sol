// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../utils/Vault.sol";

bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

interface IRewardRegistry {
    function registerRewards(bytes32[] calldata rewardIds) external;
}

interface IRewardVault {
    function reward(
        bytes32 claimId,
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

contract RewardVault is Vault, IRewardVault {
    //-- TYPE DEFINITION
    using EnumerableSet for EnumerableSet.AddressSet;

    //-- STORAGE AREA
    IRewardRegistry rewardRegistry;
    mapping(bytes32 => EnumerableSet.AddressSet) rewardCurrencies;
    mapping(bytes32 => mapping(address => uint256)) rewardSettings; //-- first key is reward id, second key is currency, value is reward amount
    bool inited;

    uint256[10] ___gap;

    //-- ERRORS
    error InvalidData();
    error AlreadyInited();

    //-- EVENTS
    event RewardSent(
        bytes32 indexed claimId,
        address indexed destination,
        address currency,
        uint256 total
    );

    constructor(address owner) {
        address registry = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, registry);

        rewardRegistry = IRewardRegistry(registry);
    }

    function initialize(address[] calldata admins) public onlyRole(OPERATOR_ROLE) {
        if (inited) {
            revert AlreadyInited();
        }

        inited = true;

        uint256 adminLength = admins.length;

        for (uint256 i = 0; i < adminLength; ) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
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
        bytes32 claimId,
        address destination,
        bytes32 rewardId,
        uint256 count
    ) external override onlyRole(OPERATOR_ROLE) {
        if (count == 0) {
            revert InvalidData();
        }

        EnumerableSet.AddressSet storage currencies = rewardCurrencies[
            rewardId
        ];

        uint256 currencyLength = currencies.length();

        for (uint256 i = 0; i < currencyLength; ) {
            address currency = currencies.at(i);

            uint256 amount = rewardSettings[rewardId][currency];

            if (amount == 0) continue;

            uint256 total = amount * count;

            _transfer(destination, currency, total);

            emit RewardSent(claimId, destination, currency, total);

            unchecked {
                ++i;
            }
        }
    }

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

        settings = new RewardSetting[](currencyLength);

        for (uint256 i = 0; i < currencyLength; ) {
            address currency = currencies.at(i);

            settings[i] = RewardSetting(
                currency,
                rewardSettings[rewardId][currency]
            );

            unchecked {
                ++i;
            }
        }

        return settings;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IRewardVault).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
