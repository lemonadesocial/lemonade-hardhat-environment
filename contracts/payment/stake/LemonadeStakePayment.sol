// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

import "../../utils/Data.sol";
import "../PaymentConfigRegistry.sol";
import "./StakeVault.sol";

bytes32 constant STAKE_REFUND = keccak256(abi.encode("STAKE_REFUND"));
bytes32 constant STAKE_SLASH = keccak256(abi.encode("STAKE_SLASH"));

contract LemonadeStakePayment is OwnableUpgradeable, Transferable {
    //-- STORAGE
    address public configRegistry;
    uint256 public counter;
    mapping(bytes32 => address) stakings; //-- key is payment id
    uint256[5] __gap;

    //-- ERRORS
    error InvalidData();

    //-- EVENTS
    event VaultRegistered(address vault);

    function initialize(address registry) public initializer {
        __Ownable_init();
        configRegistry = registry;
    }

    function setConfigRegistry(address registry) external onlyOwner {
        configRegistry = registry;
    }

    function register(address payout, uint256 refundPPM) external {
        address owner = _msgSender();

        StakeVault vault = new StakeVault(
            owner,
            payout,
            address(this),
            refundPPM
        );

        emit VaultRegistered(address(vault));
    }

    function stake(
        address vault,
        string calldata eventId,
        string calldata paymentId,
        address currency,
        uint256 amount
    ) external payable {
        if (amount == 0) {
            revert InvalidData();
        }

        bytes32 stakeId = stringToId(paymentId);

        if (stakings[stakeId] != address(0)) {
            revert AlreadyStaked();
        }

        bool isNative = currency == address(0);

        if (isNative && msg.value != amount) {
            revert InvalidData();
        }

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        uint256 stakeAmount = (amount * 1000000) /
            (registry.feePPM() + 1000000);
        uint256 feeAmount = amount - stakeAmount;

        //-- transfer fee and notify
        _transfer(configRegistry, currency, feeAmount);
        registry.notifyFee(eventId, currency, feeAmount);

        address guest = _msgSender();

        _stake(stakeId, guest, vault, stakeAmount, currency);
    }

    function _stake(
        bytes32 stakeId,
        address guest,
        address vault,
        uint256 stakeAmount,
        address currency
    ) internal {
        bool isNative = currency == address(0);

        StakeVault stakeVault = StakeVault(payable(vault));

        if (!isNative) {
            //-- first transfer the ERC20 to the contract
            bool success = IERC20(currency).transferFrom(
                guest,
                address(this),
                stakeAmount
            );

            if (!success) {
                revert CannotTransfer();
            }

            //-- then allow the vault to transfer the amount to itself
            IERC20(currency).approve(vault, stakeAmount);
        }

        stakeVault.stake{value: isNative ? stakeAmount : 0}(
            stakeId,
            currency,
            stakeAmount,
            guest
        );

        stakings[stakeId] = vault;
    }

    function getStakings(
        string[] calldata ids
    ) public view returns (Staking[] memory result) {
        uint256 length = ids.length;

        result = new Staking[](length);

        for (uint256 i = 0; i < length; ) {
            bytes32 stakeId = stringToId(ids[i]);
            address vault = stakings[stakeId];

            if (vault == address(0)) continue;

            StakeVault stakeVault = StakeVault(payable(vault));

            (
                address guest,
                address currency,
                uint256 stakeAmount,
                uint256 refundAmount,
                bool slashed,
                bool refunded
            ) = stakeVault.stakings(stakeId);

            result[i] = Staking(
                guest,
                currency,
                stakeAmount,
                refundAmount,
                slashed,
                refunded
            );

            unchecked {
                ++i;
            }
        }

        return result;
    }

    function refund(
        string calldata paymentId,
        bytes calldata signature
    ) external {
        bytes32 stakeId = stringToId(paymentId);

        address vault = stakings[stakeId];

        if (vault == address(0)) {
            revert NoStaking();
        }

        //-- verify signature
        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        bytes32[] memory data = new bytes32[](2);

        data[0] = STAKE_REFUND;
        data[1] = stakeId;

        registry.assertSignature(data, signature);

        StakeVault stakeVault = StakeVault(payable(vault));

        stakeVault.refund(stakeId);
    }

    function slash(
        address vault,
        string[] memory paymentIds,
        bytes memory signature
    ) external {
        uint256 idsLength = paymentIds.length;

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        //-- collect data to verify the signature
        bytes32[] memory data = new bytes32[](paymentIds.length + 1);
        bytes32[] memory stakeIds = new bytes32[](paymentIds.length);
        data[0] = STAKE_SLASH;

        for (uint256 i = 0; i < idsLength; ) {
            bytes32 stakeId = stringToId(paymentIds[i]);

            stakeIds[i] = stakeId;

            unchecked {
                ++i;
            }

            data[i] = stakeId;
        }

        registry.assertSignature(data, signature);

        StakeVault stakeVault = StakeVault(payable(vault));

        stakeVault.slash(stakeIds);
    }
}
