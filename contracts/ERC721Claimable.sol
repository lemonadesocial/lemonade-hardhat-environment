// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Claimable is Context, AccessControlEnumerable, ERC721Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;
    address private _creator;
    string private _tokenURI;

    Counters.Counter private _claimIdTracker;
    mapping(address => bool) private _claimers;

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI_,
        uint256 initialSupply
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _creator = creator;
        _tokenURI = tokenURI_;

        mintBatch(initialSupply);

        _claimIdTracker.increment();
        _claimers[creator] = true;
    }

    function mintBatch(uint256 amount)
        public
        virtual
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        for (uint256 i; i < amount; i++) {
            uint256 tokenId = _tokenIdTracker.current();

            _mint(_creator, tokenId);

            _tokenIdTracker.increment();
        }
    }

    function claim() public virtual whenNotPaused returns (uint256) {
        uint256 tokenId = _claimIdTracker.current();

        require(
            tokenId < _tokenIdTracker.current(),
            "ERC721Claimable: all tokens claimed"
        );

        address from = ownerOf(tokenId);
        address to = _msgSender();

        require(!_claimers[to], "ERC721Claimable: already claimed");

        _transfer(from, to, tokenId);

        _claimIdTracker.increment();
        _claimers[to] = true;

        return tokenId;
    }

    function hasClaimed(address claimer) public view virtual returns (bool) {
        return _claimers[claimer];
    }

    function totalClaims() public view virtual returns (uint256) {
        return _claimIdTracker.current();
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalUnclaimed() public view virtual returns (uint256) {
        return _tokenIdTracker.current() - _claimIdTracker.current();
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
            "ERC721Claimable: URI query for nonexistent token"
        );

        return _tokenURI;
    }

    function pause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
