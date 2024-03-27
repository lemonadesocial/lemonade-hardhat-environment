// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */

struct Payee {
    address account;
    uint256 shares;
}

contract PaymentSplitter is Context {
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    event PayeeAdded(address account, uint256 shares);
    event PayeesReset();
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    error LengthMismatch();
    error ZeroLength();
    error AccountHasNoShare();
    error AccountHasShare();
    error NoDueAmount();
    error InvalidShare();
    error InvalidAddress();

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        if (payees.length == 0) revert ZeroLength();

        if (payees.length != shares_.length) revert LengthMismatch();

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(
        IERC20 token,
        address account
    ) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function released(
        address[] calldata currencies,
        address account
    ) public view returns (uint256[] memory balances) {
        uint256 length = currencies.length;

        if (length == 0) revert ZeroLength();

        balances = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            address currency = currencies[i];

            if (currency == address(0)) {
                balances[i] = released(account);
            } else {
                balances[i] = released(IERC20(currency), account);
            }

            unchecked {
                ++i;
            }
        }

        return balances;
    }

    function pending(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    function pending(
        IERC20 token,
        address account
    ) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        return
            _pendingPayment(account, totalReceived, released(token, account));
    }

    function pending(
        address[] calldata currencies,
        address account
    ) public view returns (uint256[] memory balances) {
        uint256 length = currencies.length;

        if (length == 0) revert ZeroLength();

        balances = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            address currency = currencies[i];

            if (currency == address(0)) {
                balances[i] = pending(account);
            } else {
                balances[i] = pending(IERC20(currency), account);
            }

            unchecked {
                ++i;
            }
        }

        return balances;
    }

    function allPayees() public view returns (Payee[] memory payees) {
        uint256 length = _payees.length;

        payees = new Payee[](length);

        for (uint256 i; i < length; ) {
            address account = _payees[i];
            payees[i] = Payee(account, _shares[account]);

            unchecked {
                ++i;
            }
        }

        return payees;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        if (_shares[account] == 0) revert AccountHasNoShare();

        uint256 payment = pending(account);

        if (payment == 0) revert NoDueAmount();

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        if (_shares[account] == 0) revert AccountHasNoShare();

        uint256 payment = pending(token, account);

        if (payment == 0) revert NoDueAmount();

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    function release(
        address[] calldata currencies,
        address payable account
    ) public virtual {
        uint256 length = currencies.length;

        if (length == 0) revert ZeroLength();

        for (uint256 i = 0; i < length; ) {
            address currency = currencies[i];
            if (currency == address(0)) {
                release(account);
            } else {
                release(IERC20(currency), account);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        if (account == address(0)) revert InvalidAddress();

        if (shares_ == 0) revert InvalidShare();

        if (_shares[account] != 0) revert AccountHasShare();

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function _resetPayees(
        address[] memory payees,
        uint256[] memory shares_
    ) internal {
        //-- reset total share
        _totalShares = 0;

        //-- reset payees array
        delete _payees;

        for (uint256 i = 0; i < payees.length; i++) {
            address account = payees[i];
            uint256 shared = shares_[i];

            if (account == address(0)) revert InvalidAddress();

            if (shared == 0) revert InvalidShare();

            _payees.push(account);
            _shares[account] = shared;
            _totalShares = _totalShares + shared;
        }

        emit PayeesReset();
    }
}
