// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadePoapV1.sol";
import "./RelayRecipient.sol";

contract LemonadePoapV1Forwardable is LemonadePoapV1, RelayRecipient {
    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI,
        uint256 totalSupply,
        LibPart.Part[] memory royalties,
        address trustedForwarder_
    ) LemonadePoapV1(name, symbol, creator, tokenURI, totalSupply, royalties) {
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
