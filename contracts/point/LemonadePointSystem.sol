// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "../utils/Transferable.sol";
import "../AccessRegistry.sol";

bytes32 constant PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

struct ERC20Redeemable {
    uint256 points;
    uint256 amount;
}

struct ERC20RedeemableSetting {
    address token;
    uint256 points;
    uint256 amount;
}

contract LemonadePointSystem is OwnableUpgradeable, Transferable {
    using EnumerableSet for EnumerableSet.AddressSet;

    //-- STORAGE
    address public accessRegistry;
    mapping(address => uint256) public userPoints;

    mapping(address => ERC20Redeemable) private erc20Redeemables;
    EnumerableSet.AddressSet private erc20Addresses;

    uint256[20] _gap;

    //-- ERRORS
    error InvalidData();
    error Forbidden();
    error InsufficientPoint();

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAccessRegistry(address registry) external onlyOwner {
        accessRegistry = registry;
    }

    function setERC20Redeemable(
        address token,
        uint256 amount,
        uint256 points
    ) external onlyAdmin {
        erc20Addresses.add(token);
        erc20Redeemables[token].amount = amount;
        erc20Redeemables[token].points = points;
    }

    function listERC20RedeemableSettings()
        external
        view
        returns (ERC20RedeemableSetting[] memory settings)
    {
        uint256 length = erc20Addresses.length();

        if (length == 0) {
            return settings;
        }

        settings = new ERC20RedeemableSetting[](length);

        for (uint256 i = 0; i < length; ) {
            address token = erc20Addresses.at(i);
            ERC20Redeemable storage redeemable = erc20Redeemables[token];

            settings[i] = ERC20RedeemableSetting(
                token,
                redeemable.points,
                redeemable.amount
            );

            unchecked {
                ++i;
            }
        }
    }

    function addPoints(
        address[] calldata wallets,
        uint256[] calldata points
    ) external onlyAdmin {
        uint256 length = wallets.length;

        if (length == 0 || length != points.length) {
            revert InvalidData();
        }

        for (uint256 i = 0; i < length; ) {
            address wallet = wallets[i];
            userPoints[wallet] += points[i];

            unchecked {
                ++i;
            }
        }
    }

    function redeemERC20(address token, uint256 points) external {
        address sender = _msgSender();

        ERC20Redeemable storage redeemable = erc20Redeemables[token];

        if (points > userPoints[sender]) {
            revert InsufficientPoint();
        }

        uint256 amount = (points * redeemable.amount) / redeemable.points;

        if (amount == 0) {
            revert InsufficientPoint();
        }

        //-- deduce points & transfer tokens
        userPoints[sender] -= points;

        _transfer(sender, token, amount);
    }

    receive() external payable {}

    modifier onlyAdmin() {
        if (
            !AccessRegistry(accessRegistry).hasRole(
                PAYMENT_ADMIN_ROLE,
                _msgSender()
            )
        ) {
            revert Forbidden();
        }
        _;
    }
}
