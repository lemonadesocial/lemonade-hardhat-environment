// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./forwarder/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract RelayRecipient is BaseRelayRecipient {
    function _msgSender()
        internal
        view
        virtual
        override(BaseRelayRecipient)
        returns (address)
    {
        return BaseRelayRecipient._msgSender();
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}
