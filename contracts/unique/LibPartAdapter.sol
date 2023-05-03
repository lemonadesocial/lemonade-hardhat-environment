// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../rarible/LibPart.sol";

library LibPartAdapter {
    function encode(LibPart.Part[] memory parts) internal pure returns (bytes memory) {
        if (parts.length == 0) return "";

        uint256[] memory encoded = new uint256[](parts.length * 2);

        for (uint i = 0; i < parts.length; i++) {
            encoded[i * 2] = 0x0100000000000000000000000000000000000000000000040000000000000000 | uint256(parts[i].value);
            encoded[i * 2 + 1] = uint256(uint160(address(parts[i].account)));
        }

        return abi.encodePacked(encoded);
    }

    function decode(bytes memory b) internal pure returns (LibPart.Part[] memory) {
        if (b.length == 0) return new LibPart.Part[](0);

        require((b.length % (32 * 2)) == 0, "Invalid bytes length, expected (32 * 2) * UniqueRoyaltyParts count");
        uint partsCount = b.length / (32 * 2);
        uint numbersCount = partsCount * 2;

        LibPart.Part[] memory parts = new LibPart.Part[](partsCount);

        // need this because numbers encoded via abi.encodePacked
        bytes memory prefix = new bytes(64);

        assembly {
            mstore(add(prefix, 32), 32)
            mstore(add(prefix, 64), numbersCount)
        }

        uint256[] memory encoded = abi.decode(bytes.concat(prefix, b), (uint256[]));

        for (uint i = 0; i < partsCount; i++) {
            uint96 value = uint96(encoded[i * 2] & 0xFFFFFFFFFFFFFFFF);
            address account = address(uint160(encoded[i * 2 + 1]));

            parts[i] = LibPart.Part({
            account: payable(account),
            value: value
            });
        }

        return parts;
    }
}