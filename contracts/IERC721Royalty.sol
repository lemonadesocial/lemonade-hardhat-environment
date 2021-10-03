// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional royalty extension
 */
interface IERC721Royalty is IERC721 {
    /**
     * @dev Returns the royalty maker and fraction for `tokenId` token.
     */
    function royalty(uint256 tokenId) external view returns (address, uint256);
}
