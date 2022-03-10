// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./rarible/LibPart.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes4 constant ERC2981_INTERFACE_ID = 0x2a55205a;
bytes4 constant RaribleRoyaltiesV2_INTERFACE_ID = 0xcad96cca;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721CollectionV1 is ERC165, ERC721, Ownable {
    address private _proxyRegistryAddress;
    address private _creator;
    uint96 private _royalty;
    string private _baseTokenURI;
    uint256 private _totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        address proxyRegistryAddress,
        address creator,
        uint96 royalty,
        string memory baseTokenURI,
        uint256 totalSupply_
    ) ERC721(name, symbol) {
        _transferOwnership(creator);

        _proxyRegistryAddress = proxyRegistryAddress;
        _creator = creator;
        _royalty = royalty;
        _baseTokenURI = baseTokenURI;
        _totalSupply = totalSupply_;

        for (uint256 tokenId; tokenId < totalSupply_; tokenId++) {
            _mint(creator, tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getRaribleV2Royalties(uint256)
        external
        view
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory result;
        if (_royalty == 0) {
            return result;
        }

        result = new LibPart.Part[](1);
        result[0].account = payable(_creator);
        result[0].value = _royalty;
        return result;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256, uint256 price)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (_royalty == 0) {
            return (address(0), 0);
        }

        return (_creator, (price * _royalty) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == ERC2981_INTERFACE_ID ||
            interfaceId == RaribleRoyaltiesV2_INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
