// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/Vault.sol";

struct Staking {
    address guest;
    address currency;
    uint256 stakeAmount;
    uint256 refundAmount;
    bool slashed;
    bool refunded;
}

error NoStaking();
error AlreadyStaked();
error FundsNotAvailable();

bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

contract StakeVault is Vault {
    //-- STORAGE
    address public payoutAddress;
    uint256 public refundPPM; //-- key is setting id and value is refund PPM value
    mapping(bytes32 => Staking) public stakings; //-- key is stake id and value is staking info

    bytes32[] stakingIds;
    address[] currencies; //-- all the currency ever staked
    mapping(address => uint256) currencyIndex;

    uint256[5] _gap;

    //-- ERRORS
    error AccessDenied();
    error InvalidData();

    constructor(address owner, address payout, address operator, uint256 ppm) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);

        _setRefundPPM(ppm);
        payoutAddress = payout;
    }

    function setPayoutAddress(
        address payout
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payoutAddress = payout;
    }

    function setRefundPPM(uint256 ppm) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRefundPPM(ppm);
    }

    function stake(
        bytes32 stakeId,
        address currency,
        uint256 stakeAmount,
        address guest
    ) external payable onlyRole(OPERATOR_ROLE) {
        address sender = _msgSender();

        if (guest == address(0)) {
            revert InvalidData();
        }

        if (stakings[stakeId].guest != address(0)) {
            revert AlreadyStaked();
        }

        bool isNative = currency == address(0);

        //-- transfer the amount from caller to vault
        if (isNative) {
            if (msg.value != stakeAmount) {
                revert InvalidData();
            }
        } else {
            bool success = IERC20(currency).transferFrom(
                sender,
                address(this),
                stakeAmount
            );

            if (!success) {
                revert CannotTransfer();
            }
        }

        if (currencyIndex[currency] == 0) {
            uint256 index = currencies.length + 1;
            currencies.push(currency);
            currencyIndex[currency] = index;
        }

        uint256 refundAmount = (stakeAmount * refundPPM) / 1000000;

        Staking memory staking = Staking(
            guest,
            currency,
            stakeAmount,
            refundAmount,
            false,
            false
        );

        stakingIds.push(stakeId);
        stakings[stakeId] = staking;
    }

    function refund(bytes32 stakeId) external onlyRole(OPERATOR_ROLE) {
        Staking storage staking = stakings[stakeId];

        if (staking.guest == address(0)) {
            revert NoStaking();
        }

        staking.refunded = true;

        _transfer(staking.guest, staking.currency, staking.refundAmount);
    }

    function slash(
        bytes32[] calldata stakeIds
    ) external onlyRole(OPERATOR_ROLE) {
        uint256 idsLength = stakeIds.length;

        uint256 currenciesLength = currencies.length;
        uint256[] memory slashes = new uint256[](currenciesLength);

        for (uint256 i = 0; i < idsLength; ) {
            bytes32 stakeId = stakeIds[i];

            Staking storage staking = stakings[stakeId];

            if (staking.guest == address(0)) continue;

            if (staking.slashed || staking.refunded) {
                revert FundsNotAvailable();
            }

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
        for (uint256 i = 0; i < currenciesLength; ) {
            address currency = currencies[i];
            uint256 amount = slashes[currencyIndex[currency] - 1];

            if (amount > 0) {
                _transfer(payoutAddress, currency, amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _setRefundPPM(uint256 ppm) internal {
        if (ppm > 1000000 || ppm == 0) {
            revert InvalidData();
        }

        refundPPM = ppm;
    }
}
