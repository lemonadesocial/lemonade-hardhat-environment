// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./rarible/LibPart.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

bytes4 constant ERC2981_INTERFACE_ID = 0x2a55205a;
bytes4 constant RaribleRoyaltiesV2_INTERFACE_ID = 0xcad96cca;

interface IMintable {
    function mintToCaller(string memory tokenURI) external returns (uint256);

    function mintToCallerWithRoyalty(
        string memory tokenURI,
        LibPart.Part[] memory royalties
    ) external returns (uint256);
}

contract ERC721LemonadeV1 is ERC721, Ownable, IMintable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdTracker;

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => LibPart.Part[]) public royalties;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mintToCaller(string memory tokenURI_)
        public
        override
        returns (uint256)
    {
        uint256 tokenId = tokenIdTracker.current();

        _mint(_msgSender(), tokenId);
        tokenURIs[tokenId] = tokenURI_;

        tokenIdTracker.increment();

        return tokenId;
    }

    function mintToCallerWithRoyalty(
        string memory tokenURI_,
        LibPart.Part[] memory royalties_
    ) public override returns (uint256) {
        uint256 tokenId = mintToCaller(tokenURI_);

        uint256 length = royalties_.length;
        for (uint256 i; i < length; ) {
            royalties[tokenId].push(royalties_[i]);
            unchecked {
                ++i;
            }
        }

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

        return tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == ERC2981_INTERFACE_ID ||
            interfaceId == RaribleRoyaltiesV2_INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }

    function getRaribleV2Royalties(uint256 tokenId)
        public
        view
        returns (LibPart.Part[] memory)
    {
        return royalties[tokenId];
    }

    function royaltyInfo(uint256 tokenId, uint256 price)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 length = royalties[tokenId].length;

        if (length == 0) {
            return (address(0), 0);
        }

        uint256 totalValue;
        for (uint256 i; i < length; i++) {
            totalValue += royalties[tokenId][i].value;
        }
        return (royalties[tokenId][0].account, (price * totalValue) / 10000);
    }
}
