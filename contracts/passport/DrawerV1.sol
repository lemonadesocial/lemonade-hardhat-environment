// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DateTime.sol";
import "./IDrawerV1.sol";
import "./IPassportV1.sol";
import "./Shared.sol";

abstract contract DrawerV1 is IDrawerV1 {
    function _createdAt(
        IPassportV1 passport,
        uint256 tokenId
    ) internal view returns (string memory) {
        uint256 timestamp = passport.createdAt(tokenId);

        return _timestamp(timestamp);
    }

    function _updatedAt(
        IPassportV1 passport,
        uint256 tokenId
    ) internal view returns (string memory) {
        uint256 timestamp = passport.updatedAt(tokenId);

        if (timestamp == 0) {
            return _createdAt(passport, tokenId);
        }

        return _timestamp(timestamp);
    }

    function _username(
        IPassportV1 passport,
        uint256 tokenId
    ) internal view returns (string memory) {
        return string(passport.property(tokenId, keccak256("username")));
    }

    function _date(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure virtual returns (string memory);

    function _padStart(
        string memory str,
        uint256 length,
        bytes1 char
    ) internal pure returns (string memory) {
        bytes memory strb = bytes(str);
        uint256 strl = strb.length;

        if (strl >= length) {
            return str;
        }

        uint256 padl;
        unchecked {
            padl = length - strl;
        }
        bytes memory padb = new bytes(padl);

        for (; padl > 0; ) {
            unchecked {
                padb[--padl] = char;
            }
        }

        return string(bytes.concat(padb, strb));
    }

    function _timestamp(
        uint256 timestamp
    ) internal pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(
            timestamp
        );

        return _date(year, month, day);
    }

    modifier whenMinted(IPassportV1 passport, uint256 tokenId) {
        try passport.ownerOf(tokenId) {
            _;
        } catch {
            revert NotFound();
        }
    }

    uint256[50] private __gap;
}
