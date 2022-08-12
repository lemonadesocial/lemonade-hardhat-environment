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
        LibPart.Part[] memory royalties,
        uint256 totalSupply,
        address accessRegistry,
        address trustedForwarder
    )
        LemonadePoapV1(
            name,
            symbol,
            creator,
            tokenURI,
            royalties,
            totalSupply,
            accessRegistry
        )
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
