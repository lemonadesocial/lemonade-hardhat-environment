// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ChainlinkRequest.sol";
import "./LemonadePoapV1.sol";

contract LemonadePoapV1ChainlinkRequest is LemonadePoapV1 {
    address public chainlinkRequest;

    event ClaimFailed(string reason);

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI,
        LibPart.Part[] memory royalties,
        uint256 totalSupply,
        address accessRegistry,
        address chainlinkRequest_
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
    {
        chainlinkRequest = chainlinkRequest_;
    }

    function _claim(address claimer) internal virtual override {
        if (chainlinkRequest == address(0)) {
            super._claim(claimer);
        } else {
            bytes memory state = abi.encode(claimer);

            ChainlinkRequest(chainlinkRequest).requestBytes(
                this.fulfillClaim.selector,
                state
            );
        }
    }

    function fulfillClaim(bytes memory state, bytes memory bytesData)
        public
        virtual
    {
        require(
            _msgSender() == chainlinkRequest,
            "LemonadePoap: caller must be access request"
        );

        (bool ok, string memory err) = abi.decode(bytesData, (bool, string));

        if (ok) {
            address claimer = abi.decode(state, (address));

            err = _mint(claimer);
        }
        if (bytes(err).length > 0) {
            emit ClaimFailed(err);
        }
    }

    function setChainlinkRequest(address chainlinkRequest_) public onlyOwner {
        chainlinkRequest = chainlinkRequest_;
    }
}
