// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721 is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("TestERC721", "T721") {}

    function mint(address to) external onlyOwner {
        _safeMint(to, _nextTokenId);
        _nextTokenId++;
    }

    function batchMint(address to, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _nextTokenId);
            _nextTokenId++;
        }
    }
}
