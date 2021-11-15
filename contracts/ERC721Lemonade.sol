// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Royalty.sol";

contract ERC721Lemonade is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable, ERC721Royalty {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function mintToCaller(string memory tokenURI_)
        public
        virtual
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = _tokenIdTracker.current();

        _mint(_msgSender(), tokenId);
        _tokenURIs[tokenId] = tokenURI_;

        _tokenIdTracker.increment();

        return tokenId;
    }

    function mintToCallerWithRoyalty(string memory tokenURI_, uint256 fraction)
        public
        virtual
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = mintToCaller(tokenURI_);

        _setRoyalty(tokenId, _msgSender(), fraction);

        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Lemonade: URI query for nonexistent token");

        return _tokenURIs[tokenId];
    }

    function pause()
        public
        virtual
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721Lemonade: must have pauser role to pause");
        _pause();
    }

    function unpause()
        public
        virtual
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721Lemonade: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
