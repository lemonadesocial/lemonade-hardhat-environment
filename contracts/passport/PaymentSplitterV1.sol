// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract PaymentSplitterV1 is Initializable {
    using AddressUpgradeable for address payable;

    struct Recipient {
        address payable account;
        uint256 shares;
    }
    Recipient[] public recipients;

    uint256 private _totalShares;

    function initialize(Recipient[] calldata recipients_) public initializer {
        _addRecipients(recipients_);
    }

    receive() external payable {
        _sendValue(address(this).balance);
    }

    function _addRecipients(Recipient[] calldata recipients_) internal {
        uint256 length = recipients_.length;

        for (uint256 i; i < length; ) {
            Recipient calldata recipient = recipients_[i];

            recipients.push(recipient);

            _totalShares += recipient.shares;

            unchecked {
                ++i;
            }
        }
    }

    function _sendValue(uint256 amount) internal {
        uint256 length = recipients.length;

        for (uint256 i; i < length; ) {
            Recipient memory recipient = recipients[i];

            recipient.account.sendValue(
                (amount * recipient.shares) / _totalShares
            );

            unchecked {
                ++i;
            }
        }
    }
}
