// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Royalties.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721LemonadeV1 is ERC721, Royalties, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mintToCaller(string memory tokenURI_)
        public
        virtual
        returns (uint256)
    {
        uint256 tokenId = _tokenIdTracker.current();

        _mint(_msgSender(), tokenId);
        _tokenURIs[tokenId] = tokenURI_;

        _tokenIdTracker.increment();

        return tokenId;
    }

    function mintToCallerWithRoyalty(
        string memory tokenURI_,
        LibPart.Part[] memory royalties_
    ) public virtual returns (uint256) {
        uint256 tokenId = mintToCaller(tokenURI_);

        _saveRoyalties(tokenId, royalties_);

        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Lemonade: URI query for nonexistent token"
        );

        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
