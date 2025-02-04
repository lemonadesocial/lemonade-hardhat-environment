// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "../utils/Data.sol";
import "../payment/PaymentConfigRegistry.sol";
import "./RewardVault.sol";

contract RewardRegistry is IRewardRegistry, OwnableUpgradeable {
    //-- TYPE DEFINITION
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Reward {
        address vault;
        RewardSetting[] settings;
    }

    //-- STORAGE AREA
    address public configRegistry;
    mapping(bytes32 => EnumerableSet.AddressSet) rewardRegistry; //-- key is rewardId
    mapping(bytes32 => bool) public claimed; //-- key is unique claim id

    //-- EVENTS
    event RewardVaultCreated(address indexed vault);
    event RewardClaimed(
        bytes32 indexed claimId,
        address indexed vault,
        address destination
    );

    //-- ERRORS
    error NotRewardVault(address caller);
    error InvalidData();
    error AlreadyClaimed();

    function initialize() public initializer {
        __Ownable_init();
    }

    function setConfigRegistry(address registry) external onlyOwner {
        configRegistry = registry;
    }

    function createVault(bytes32 salt, address[] calldata admins) external {
        address owner = _msgSender();

        bytes memory bytecode = abi.encodePacked(
            type(RewardVault).creationCode,
            abi.encode(owner)
        );

        address vault = Create2.deploy(0, salt, bytecode);

        RewardVault rewardVault = RewardVault(payable(vault));
        rewardVault.initialize(admins);

        emit RewardVaultCreated(vault);
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

            if (vaultLength > 0) {
                Reward[] memory rewardVaults = new Reward[](vaultLength);

                for (uint256 j = 0; j < vaultLength; ) {
                    IRewardVault vault = IRewardVault(payable(vaults.at(j)));

                    RewardSetting[] memory settings = vault.listRewards(
                        rewardId
                    );

                    rewardVaults[j] = Reward(address(vault), settings);

                    unchecked {
                        ++j;
                    }
                }

                rewards[i] = rewardVaults;
            }

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    function claimRewards(
        bytes32 claimId,
        bytes32[] calldata rewardIds,
        uint256[] calldata counts,
        bytes calldata signature
    ) external {
        if (claimed[claimId]) {
            revert AlreadyClaimed();
        }

        uint256 rewardLength = rewardIds.length;
        uint256 countLength = counts.length;

        if (rewardLength == 0 || rewardLength != countLength) {
            revert InvalidData();
        }

        address sender = _msgSender();

        bytes32[] memory payload = new bytes32[](
            rewardLength + countLength + 2
        );

        payload[0] = stringToId("REWARD");
        payload[1] = claimId;

        for (uint256 i = 0; i < rewardLength; ) {
            payload[2 + i] = rewardIds[i];
            payload[2 + i + rewardLength] = bytes32(counts[i]);

            unchecked {
                ++i;
            }
        }

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        registry.assertSignature(payload, signature);

        claimed[claimId] = true;

        for (uint256 i = 0; i < rewardLength; ) {
            bytes32 rewardId = rewardIds[i];
            uint256 count = counts[i];

            _reward(claimId, rewardId, count, sender);

            unchecked {
                ++i;
            }
        }
    }

    function _reward(
        bytes32 claimId,
        bytes32 rewardId,
        uint256 count,
        address destination
    ) internal {
        EnumerableSet.AddressSet storage vaults = rewardRegistry[rewardId];

        uint256 vaultLength = vaults.length();

        if (vaultLength == 0) return;

        for (uint256 i = 0; i < vaultLength; ) {
            address vaultAddress = vaults.at(i);
            IRewardVault vault = IRewardVault(vaultAddress);

            vault.reward(claimId, destination, rewardId, count);

            emit RewardClaimed(claimId, vaultAddress, destination);

            unchecked {
                ++i;
            }
        }
    }
}
