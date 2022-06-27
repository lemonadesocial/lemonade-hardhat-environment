// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AccessRegistry.sol";
import "./rarible/LibPart.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes4 constant ERC2981_INTERFACE_ID = 0x2a55205a;
bytes4 constant RaribleRoyaltiesV2_INTERFACE_ID = 0xcad96cca;

bytes32 constant TRUSTED_CLAIMER_ROLE = keccak256("TRUSTED_CLAIMER_ROLE");
bytes32 constant TRUSTED_OPERATOR_ROLE = keccak256("TRUSTED_OPERATOR_ROLE");

interface ILemonadePoapV1 is IERC721 {
    function claim() external;

    function hasClaimed(address[] calldata claimers)
        external
        view
        returns (bool[] memory);

    function supply() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);
}

contract LemonadePoapV1 is ERC721, ILemonadePoapV1, Ownable {
    using Counters for Counters.Counter;

    address private immutable _creator;
    string private _tokenURI;
    LibPart.Part[] private  _royalties;
    uint256 private _maxSupply;
    address private immutable _accessRegistry;

    Counters.Counter private _tokenIdTracker;
    mapping(address => bool) private _claimed;

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        string memory tokenURI_,
        LibPart.Part[] memory royalties,
        uint256 maxSupply,
        address accessRegistry
    ) ERC721(name, symbol) {
        _creator = creator;
        _tokenURI = tokenURI_;

        uint256 length = royalties.length;
        for (uint256 i; i < length; ) {
            _royalties.push(royalties[i]);
            unchecked {
                ++i;
            }
        }

        _maxSupply = maxSupply;
        _accessRegistry = accessRegistry;

        _claim(creator);
        _transferOwnership(creator);
    }

    function _claim(address claimer) internal virtual {
        uint256 tokenId = _tokenIdTracker.current();

        require(
            tokenId < _maxSupply || _maxSupply == 0,
            "LemonadePoap: all tokens claimed"
        );
        require(!_claimed[claimer], "LemonadePoap: already claimed");

        _mint(claimer, tokenId);

        _claimed[claimer] = true;
        _tokenIdTracker.increment();
    }

    function claim() public virtual override {
        address claimer = _msgSender();

        _claim(claimer);
    }

    function claimTo(address claimer) public virtual {
        require(
            AccessRegistry(_accessRegistry).hasRole(
                TRUSTED_CLAIMER_ROLE,
                _msgSender()
            ),
            "LemonadePoap: can only claim for self"
        );

        _claim(claimer);
    }

    function hasClaimed(address[] calldata claimers)
        public
        view
        virtual
        override
        returns (bool[] memory)
    {
        uint256 length = claimers.length;
        bool[] memory result = new bool[](length);

        for (uint256 i; i < length; ) {
            result[i] = _claimed[claimers[i]];
            unchecked {
                ++i;
            }
        }

        return result;
    }

    function supply() public view virtual override returns (uint256, uint256) {
        return (_tokenIdTracker.current(), _maxSupply);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return (_tokenIdTracker.current());
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (bool isOperator)
    {
        if (
            AccessRegistry(_accessRegistry).hasRole(
                TRUSTED_OPERATOR_ROLE,
                owner
            )
        ) {
            return true;
        }

        return ERC721.isApprovedForAll(owner, operator);
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
