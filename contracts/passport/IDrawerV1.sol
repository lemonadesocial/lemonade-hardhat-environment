// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPassportV1.sol";

interface IDrawerV1 {
    function tokenURI(
        IPassportV1 passport,
        uint256 tokenId
    ) external view returns (string memory);
}
