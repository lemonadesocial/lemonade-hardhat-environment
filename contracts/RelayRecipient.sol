// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRelayRecipient.sol";

abstract contract RelayRecipient is IRelayRecipient {
    address public trustedForwarder;

    constructor(address forwarder) {
        trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        override
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}
