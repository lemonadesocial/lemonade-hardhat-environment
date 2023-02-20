// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ChainlinkRequest.sol";
import "./LemonadePoapV1.sol";

contract LemonadePoapV1ChainlinkRequest is LemonadePoapV1 {
    address public chainlinkRequest;

    event ClaimFailed(string reason);
    event ClaimFailedBytes(bytes reason);

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

    function _mint(address claimer) internal virtual override {
        if (chainlinkRequest == address(0)) {
            super._mint(claimer);
        } else {
            bytes memory state = abi.encode(claimer);

            ChainlinkRequest(chainlinkRequest).requestBytes(
                this.fulfillClaim.selector,
                state
            );
        }
    }

    function fulfillMint(address claimer) external {
        if (_msgSender() != address(this)) {
            revert Forbidden();
        }

        super._mint(claimer);
    }

    function fulfillClaim(
        bytes memory state,
        bytes memory bytesData
    ) public virtual {
        if (_msgSender() != chainlinkRequest) {
            revert Forbidden();
        }

        (bool ok, string memory err) = abi.decode(bytesData, (bool, string));

        if (ok) {
            address claimer = abi.decode(state, (address));

            try this.fulfillMint(claimer) {
                /* no-op */
            } catch Error(string memory reason) {
                err = reason;
            } catch (bytes memory reason) {
                emit ClaimFailedBytes(reason);
            }
        }
        if (bytes(err).length > 0) {
            emit ClaimFailed(err);
        }
    }

    function setChainlinkRequest(address chainlinkRequest_) public onlyOwner {
        chainlinkRequest = chainlinkRequest_;
    }
}
