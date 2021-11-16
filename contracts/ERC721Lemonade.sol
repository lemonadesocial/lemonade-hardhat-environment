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

    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant WITHDRAW_BATCH_LIMIT = 20;

    Counters.Counter private _tokenIdTracker;

    mapping (uint256 => bool) public _tokenWithdrawn;
    mapping (uint256 => string) private _tokenURIs;

    event TransferWithMetadata(address indexed from, address indexed to, uint256 indexed tokenId, bytes metaData);
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    constructor(string memory name, string memory symbol, address childChainManager) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
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
        onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    function unpause()
        public
        virtual
        onlyRole(PAUSER_ROLE)
    {
        _unpause();
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/ChildMintableERC721.sol#L2160
     */
    function deposit(address user, bytes calldata depositData)
        external
        onlyRole(DEPOSITOR_ROLE)
    {
        if (depositData.length == 32) { // deposit single
            uint256 tokenId = abi.decode(depositData, (uint256));

            _tokenWithdrawn[tokenId] = false;
            _mint(user, tokenId);
        } else { // deposit batch
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;

            for (uint256 i; i < length; i++) {
                _tokenWithdrawn[tokenIds[i]] = false;
                _mint(user, tokenIds[i]);
            }
        }
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/ChildMintableERC721.sol#L2191
     */
    function withdraw(uint256 tokenId)
        external
    {
        require(_msgSender() == ownerOf(tokenId), "ERC721Lemonade: INVALID_TOKEN_OWNER");

        _tokenWithdrawn[tokenId] = true;
        _burn(tokenId);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/ChildMintableERC721.sol#L2202
     */
    function withdrawBatch(uint256[] calldata tokenIds)
        external
    {
        uint256 length = tokenIds.length;
        require(length <= WITHDRAW_BATCH_LIMIT, "ERC721Lemonade: EXCEEDS_BATCH_LIMIT");

        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];

            require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("ERC721Lemonade: INVALID_TOKEN_OWNER ", tokenId)));

            _tokenWithdrawn[tokenId] = true;
            _burn(tokenId);
        }

        emit WithdrawnBatch(_msgSender(), tokenIds);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/ChildMintableERC721.sol#L2234
     */
    function withdrawWithMetadata(uint256 tokenId)
        external
    {
        require(_msgSender() == ownerOf(tokenId), "ERC721Lemonade: INVALID_TOKEN_OWNER");

        _tokenWithdrawn[tokenId] = true;

        emit TransferWithMetadata(ownerOf(tokenId), address(0), tokenId, this.encodeState(tokenId));

        _burn(tokenId);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/ChildMintableERC721.sol#L2255
     */
    function encodeState(uint256 tokenId)
        external
        view
        virtual
        returns (bytes memory)
    {
        string memory tokenURI_ = tokenURI(tokenId);
        address royaltyMaker;
        uint256 royaltyFraction;

        try this.royalty(tokenId) returns (address maker, uint256 fraction) {
            royaltyMaker = maker;
            royaltyFraction = fraction;
        } catch { }

        return abi.encode(tokenURI_, royaltyMaker, royaltyFraction);
    }
}
