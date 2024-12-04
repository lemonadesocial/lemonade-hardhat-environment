// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../PaymentConfigRegistry.sol";

bytes32 constant STAKE_REFUND = keccak256(abi.encode("STAKE_REFUND"));
bytes32 constant STAKE_SLASH = keccak256(abi.encode("STAKE_SLASH"));

contract LemonadeStakePayment is OwnableUpgradeable {
    error NotAvailable();
    error InvalidData();
    error AlreadyStaked();
    error CannotPayFee();
    error CannotRelease();
    error CannotStake();

    event VaultRegistered(uint256 id);

    struct StakeConfig {
        address owner;
        address vault;
        uint256 refundPercent;
    }

    struct Staking {
        address guest;
        address currency;
        uint256 amount;
        uint256 stakeAmount;
        uint256 refundAmount;
        bool slashed;
        bool refunded;
    }

    address public configRegistry;
    uint256 public counter;
    address[] currencies; //-- all the currency ever staked
    uint256[5] _gap;

    mapping(address => uint256) currencyIndex;
    mapping(bytes32 => Staking) stakings;
    mapping(uint256 => StakeConfig) public configs;
    uint256[5] __gap;

    function initialize(address registry) public initializer {
        __Ownable_init();
        configRegistry = registry;
    }

    function setConfigRegistry(address registry) external onlyOwner {
        configRegistry = registry;
    }

    function register(address vault, uint256 refundPercent) external {
        if (refundPercent > 100 || refundPercent == 0) {
            revert InvalidData();
        }

        address owner = _msgSender();
        StakeConfig memory config = StakeConfig(owner, vault, refundPercent);

        counter += 1;
        configs[counter] = config;

        emit VaultRegistered(counter);
    }

    function stake(
        uint256 configId,
        string memory eventId,
        string memory paymentId,
        address currency,
        uint256 amount
    ) external payable {
        if (amount == 0) {
            revert InvalidData();
        }
        bytes32 id = _toId(paymentId);

        if (stakings[id].amount > 0) {
            revert AlreadyStaked();
        }

        bool isNative = currency == address(0);

        if (isNative && msg.value != amount) {
            revert InvalidData();
        }

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        StakeConfig storage config = configs[configId];

        uint256 stakeAmount = (amount * 1000000) /
            (registry.feePPM() + 1000000);
        uint256 feeAmount = amount - stakeAmount;
        uint256 refundAmount = (stakeAmount * config.refundPercent) / 100;

        address guest = _msgSender();

        if (isNative) {
            (bool success, ) = payable(configRegistry).call{value: feeAmount}(
                ""
            );

            if (!success) revert CannotPayFee();
        } else {
            bool success = IERC20(currency).transferFrom(
                guest,
                configRegistry,
                feeAmount
            );

            if (!success) revert CannotPayFee();

            success = IERC20(currency).transferFrom(
                guest,
                address(this),
                stakeAmount
            );

            if (!success) revert CannotStake();
        }

        if (currencyIndex[currency] == 0) {
            uint256 index = currencies.length + 1;
            currencies.push(currency);
            currencyIndex[currency] = index;
        }

        stakings[id] = Staking(
            guest,
            currency,
            amount,
            stakeAmount,
            refundAmount,
            false,
            false
        );

        registry.notifyFee(eventId, currency, feeAmount);
    }

    function getStakings(
        string[] memory ids
    ) public view returns (Staking[] memory result) {
        uint256 length = ids.length;

        result = new Staking[](length);

        for (uint256 i = 0; i < length; ) {
            bytes32 id = _toId(ids[i]);
            result[i] = stakings[id];

            unchecked {
                ++i;
            }
        }
    }

    function refund(
        string calldata paymentId,
        bytes calldata signature
    ) external {
        bytes32 id = _toId(paymentId);

        Staking storage staking = stakings[id];

        if (staking.slashed || staking.refunded) {
            revert NotAvailable();
        }

        address sender = _msgSender();

        //-- verify signature
        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        bytes32[] memory data = new bytes32[](2);

        data[0] = STAKE_REFUND;
        data[1] = id;

        registry.assertSignature(data, signature);

        //-- let's refund
        _release(sender, staking.currency, staking.refundAmount);

        staking.refunded = true;
    }

    function slash(
        string[] memory paymentIds,
        bytes[] memory signatures
    ) external {
        uint256 idsLength = paymentIds.length;
        uint256 sigsLength = signatures.length;

        if (idsLength != sigsLength) {
            revert InvalidData();
        }

        PaymentConfigRegistry registry = PaymentConfigRegistry(
            payable(configRegistry)
        );

        uint256 currenciesLength = currencies.length;
        uint256[] memory slashes = new uint256[](currenciesLength);

        for (uint256 i = 0; i < idsLength; ) {
            bytes32 id = _toId(paymentIds[i]);

            Staking storage staking = stakings[id];

            if (staking.slashed || staking.refunded) {
                revert NotAvailable();
            }

            //-- verify the signature
            bytes32[] memory data = new bytes32[](2);

            data[0] = STAKE_SLASH;
            data[1] = id;

            registry.assertSignature(data, signatures[i]);

            //-- add to slash sum
            uint256 index = currencyIndex[staking.currency] - 1;
            slashes[index] += staking.stakeAmount;

            //-- update the staking
            staking.slashed = true;

            unchecked {
                ++i;
            }
        }

        //-- release
        address sender = _msgSender();

        for (uint256 i = 0; i < currenciesLength; ) {
            address currency = currencies[i];
            uint256 amount = slashes[currencyIndex[currency] - 1];

            if (amount > 0) {
                _release(sender, currency, amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _release(
        address destination,
        address currency,
        uint256 amount
    ) internal {
        if (currency == address(0)) {
            (bool success, ) = payable(destination).call{value: amount}("");

            if (!success) revert CannotRelease();
        } else {
            bool success = IERC20(currency).transferFrom(
                address(this),
                destination,
                amount
            );

            if (!success) revert CannotRelease();
        }
    }

    function _toId(string memory id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id));
    }
}
