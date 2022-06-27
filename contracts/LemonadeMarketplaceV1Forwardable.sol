// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadeMarketplaceV1.sol";
import "./RelayRecipient.sol";

contract LemonadeMarketplaceV1Forwardable is
    LemonadeMarketplaceV1,
    RelayRecipient
{
    constructor(
        address feeAccount,
        uint96 feeValue,
        address trustedForwarder_
    ) LemonadeMarketplaceV1(feeAccount, feeValue) {
        trustedForwarder = trustedForwarder_;
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, RelayRecipient)
        returns (address)
    {
        return RelayRecipient._msgSender();
    }
}
