// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadeMarketplaceV2.sol";
import "./RelayRecipient.sol";

contract LemonadeMarketplaceV2Forwardable is
    LemonadeMarketplaceV2,
    RelayRecipient
{
    constructor(
        address feeAccount,
        uint96 feeValue,
        address trustedForwarder
    )
        LemonadeMarketplaceV2(feeAccount, feeValue)
        RelayRecipient(trustedForwarder)
    {}

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
