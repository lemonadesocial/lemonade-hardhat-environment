// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721LemonadeV1.sol";
import "./RelayRecipient.sol";

contract ERC721LemonadeV1Forwardable is ERC721LemonadeV1, RelayRecipient {
    constructor(
        string memory name,
        string memory symbol,
        address trustedForwarder_
    ) ERC721LemonadeV1(name, symbol) {
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
