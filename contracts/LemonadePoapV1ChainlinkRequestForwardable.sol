// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadePoapV1ChainlinkRequest.sol";
import "./RelayRecipient.sol";

contract LemonadePoapV1ChainlinkRequestForwardable is
    LemonadePoapV1ChainlinkRequest,
    RelayRecipient
{
    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI,
        LibPart.Part[] memory royalties,
        uint256 totalSupply,
        address accessRegistry,
        address chainlinkRequest,
        address trustedForwarder
    )
        LemonadePoapV1ChainlinkRequest(
            name,
            symbol,
            creator,
            tokenURI,
            royalties,
            totalSupply,
            accessRegistry,
            chainlinkRequest
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

    function setTrustedForwarder(address trustedForwarder_) public onlyOwner {
        trustedForwarder = trustedForwarder_;
    }
}
