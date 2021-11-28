// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Royalties.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ERC721LemonadeParent is Context, AccessControlEnumerable, ERC721Burnable, ERC721Pausable, Royalties {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol, address mintableAssetProxy) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, mintableAssetProxy);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721LemonadeParent: URI query for nonexistent token");

        return _tokenURIs[tokenId];
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/DummyMintableERC721.sol#L2172
     */
    function mint(address to, uint256 tokenId)
        external
        onlyRole(PREDICATE_ROLE)
    {
        _mint(to, tokenId);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/DummyMintableERC721.sol#L2199
     */
    function mint(address to, uint256 tokenId, bytes calldata data)
        external
        onlyRole(PREDICATE_ROLE)
    {
        _mint(to, tokenId);

        _saveState(tokenId, data);
    }

    /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/DummyMintableERC721.sol#L2209
     */
    function exists(uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _exists(tokenId);
    }

   /**
     * @dev see https://github.com/maticnetwork/pos-portal/blob/88dbf0a88fd68fa11f7a3b9d36629930f6b93a05/flat/DummyMintableERC721.sol#L2181
     */
    function _saveState(uint256 tokenId, bytes memory data)
        internal
        virtual
    {
        (string memory tokenURI_, LibPart.Part[] memory royalties) = abi.decode(data, (string, LibPart.Part[]));

        _tokenURIs[tokenId] = tokenURI_;

        _saveRoyalties(tokenId, royalties);
    }
}
