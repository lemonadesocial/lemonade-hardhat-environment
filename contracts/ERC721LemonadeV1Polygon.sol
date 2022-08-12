// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721LemonadeV1.sol";
import "./RelayRecipient.sol";

contract ERC721LemonadeV1Polygon is ERC721LemonadeV1, RelayRecipient {
    address private _trustedOperator;

    constructor(
        string memory name,
        string memory symbol,
        address trustedForwarder,
        address trustedOperator
    ) ERC721LemonadeV1(name, symbol) RelayRecipient(trustedForwarder) {
        _trustedOperator = trustedOperator;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (operator == address(_trustedOperator)) {
            return true;
        }

        return ERC721.isApprovedForAll(owner, operator);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, RelayRecipient)
        returns (address)
    {
        address payable sender;
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(RelayRecipient._msgSender());
        }
        return sender;
    }
}
