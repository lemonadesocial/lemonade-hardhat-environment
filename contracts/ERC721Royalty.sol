// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC721Royalty.sol";

/**
 * @dev This implements an optional extension of {ERC721} that adds royalties.
 */
abstract contract ERC721Royalty is Context, ERC721, IERC721Royalty {
    struct Royalty {
        address maker;
        uint256 fraction;
    }
    mapping (uint256 => Royalty) private _royalties;

    function royalty(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        require(_exists(tokenId), "ERC721Royalty: query for nonexistent token");
        require(_royalties[tokenId].maker != address(0), "ERC721Lemonade: query for nonexistent royalty");

        return (_royalties[tokenId].maker, _royalties[tokenId].fraction);
    }

    function _setRoyalty(uint256 tokenId, address maker, uint256 fraction)
      internal
      virtual
    {
        require(_exists(tokenId), "ERC721Royalty: set for nonexistent token");
        require(maker != address(0), "ERC721Royalty: set to the zero address");
        require(fraction > 0 && fraction < 10 ** 18, "ERC721Royalty: set for fraction not strictly between 0 and 1");

        _royalties[tokenId] = Royalty({
            maker: maker,
            fraction: fraction
        });
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721Royalty).interfaceId || super.supportsInterface(interfaceId);
    }
}
