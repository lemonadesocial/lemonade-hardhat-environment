// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RelayRecipient.sol";
import "./Royalties.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721ClaimableV2 is
    AccessControlEnumerable,
    ERC721,
    RelayRecipient,
    Royalties
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    address private _trustedOperator;
    address private _creator;
    string private _tokenURI;

    Counters.Counter private _claimIdTracker;
    mapping(address => bool) private _claimers;

    constructor(
        string memory name,
        string memory symbol,
        address trustedForwarder_,
        address trustedOperator,
        address creator,
        string memory tokenURI_,
        LibPart.Part[] memory royalties,
        uint256 initialSupply
    ) ERC721(name, symbol) {
        trustedForwarder = trustedForwarder_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, creator);

        _trustedOperator = trustedOperator;
        _creator = creator;
        _tokenURI = tokenURI_;

        mintBatch(initialSupply, royalties);

        _claimIdTracker.increment();
        _claimers[creator] = true;
    }

    function mintBatch(uint256 amount, LibPart.Part[] memory royalties)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < amount; i++) {
            uint256 tokenId = _tokenIdTracker.current();

            _mint(_creator, tokenId);
            _saveRoyalties(tokenId, royalties);

            _tokenIdTracker.increment();
        }
    }

    function claim() public virtual returns (uint256) {
        uint256 tokenId = _claimIdTracker.current();

        require(
            tokenId < _tokenIdTracker.current(),
            "ERC721ClaimableV2: all tokens claimed"
        );

        address from = ownerOf(tokenId);
        address to = _msgSender();

        require(!_claimers[to], "ERC721ClaimableV2: already claimed");

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
            "ERC721ClaimableV2: URI query for nonexistent token"
        );

        return _tokenURI;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool isOperator)
    {
        if (operator == address(_trustedOperator)) {
            return true;
        }

        return ERC721.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function setTrustedForwarder(address trustedForwarder_)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        trustedForwarder = trustedForwarder_;
    }

    function updateRoyalties(uint256 tokenId, LibPart.Part[] memory royalties_)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _exists(tokenId),
            "ERC721ClaimableV2: update royalties for nonexistent token"
        );

        delete royalties[tokenId];
        _saveRoyalties(tokenId, royalties_);
    }

    function updateRoyaltiesForAll(LibPart.Part[] memory royalties_)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 n = totalSupply();

        for (uint256 tokenId; tokenId < n; tokenId++) {
            delete royalties[tokenId];
            _saveRoyalties(tokenId, royalties_);
        }
    }
}
