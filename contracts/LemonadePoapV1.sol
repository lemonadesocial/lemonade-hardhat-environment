// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./rarible/LibPart.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes4 constant ERC2981_INTERFACE_ID = 0x2a55205a;
bytes4 constant RaribleRoyaltiesV2_INTERFACE_ID = 0xcad96cca;

interface ILemonadePoapV1 is IERC721 {
    function claim() external;

    function hasClaimed(address claimer) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function totalUnclaimed() external view returns (uint256);
}

contract LemonadePoapV1 is ERC721, ILemonadePoapV1, Ownable {
    using Counters for Counters.Counter;

    address private _creator;
    string private _tokenURI;
    uint256 private _totalSupply;
    LibPart.Part[] private _royalties;

    Counters.Counter private _tokenIdTracker;
    mapping(address => bool) private _claimers;

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI_,
        uint256 totalSupply_,
        LibPart.Part[] memory royalties
    ) ERC721(name, symbol) {
        _creator = creator;
        _tokenURI = tokenURI_;
        _totalSupply = totalSupply_;

        uint256 length = royalties.length;
        for (uint256 i; i < length; i++) {
            _royalties.push(royalties[i]);
        }

        _claim(creator);
        _transferOwnership(creator);
    }

    function _claim(address claimer) internal virtual {
        uint256 tokenId = _tokenIdTracker.current();

        _mint(claimer, tokenId);

        _tokenIdTracker.increment();
        _claimers[claimer] = true;
    }

    function claim() public virtual override {
        uint256 tokenId = _tokenIdTracker.current();
        address claimer = _msgSender();

        require(tokenId < _totalSupply, "LemonadePoap: all tokens claimed");
        require(!_claimers[claimer], "LemonadePoap: already claimed");

        _claim(claimer);
    }

    function hasClaimed(address claimer)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _claimers[claimer];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function totalUnclaimed() public view virtual override returns (uint256) {
        return _totalSupply - _tokenIdTracker.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == ERC2981_INTERFACE_ID ||
            interfaceId == RaribleRoyaltiesV2_INTERFACE_ID ||
            interfaceId == type(ILemonadePoapV1).interfaceId ||
            super.supportsInterface(interfaceId);
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
            "LemonadePoap: URI query for nonexistent token"
        );

        return _tokenURI;
    }

    function getRaribleV2Royalties(uint256)
        external
        view
        returns (LibPart.Part[] memory)
    {
        return _royalties;
    }

    function royaltyInfo(uint256, uint256 price)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 length = _royalties.length;

        if (length == 0) {
            return (address(0), 0);
        }

        uint256 totalValue;
        for (uint256 i; i < length; i++) {
            totalValue += _royalties[i].value;
        }
        return (_royalties[0].account, (price * totalValue) / 10000);
    }
}
