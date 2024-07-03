// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AccessRegistry.sol";
import "./IERC2981.sol";
import "./rarible/RoyaltiesV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes32 constant TRUSTED_CLAIMER_ROLE = keccak256("TRUSTED_CLAIMER_ROLE");
bytes32 constant TRUSTED_OPERATOR_ROLE = keccak256("TRUSTED_OPERATOR_ROLE");

interface ILemonadePoapV1 is IERC721 {
    function claim() external;

    function hasClaimed(
        address[] calldata claimers
    ) external view returns (bool[] memory);

    function supply() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);
}

contract LemonadePoapV1 is
    ERC721,
    IERC2981,
    ILemonadePoapV1,
    Ownable,
    RoyaltiesV2
{
    using Counters for Counters.Counter;

    error AllClaimed();
    error AlreadyClaimed();
    error Forbidden();
    error NotFound();

    address public immutable creator;
    string public tokenURI_;
    LibPart.Part[] public royalties;
    uint256 public maxSupply;
    address public immutable accessRegistry;

    Counters.Counter public tokenIdTracker;
    mapping(address => bool) public claimed;

    constructor(
        string memory name,
        string memory symbol,
        address creator_,
        string memory tokenURI__,
        LibPart.Part[] memory royalties_,
        uint256 maxSupply_,
        address accessRegistry_
    ) ERC721(name, symbol) {
        creator = creator_;
        tokenURI_ = tokenURI__;

        uint256 length = royalties_.length;
        for (uint256 i; i < length; ) {
            royalties.push(royalties_[i]);
            unchecked {
                ++i;
            }
        }

        maxSupply = maxSupply_;
        accessRegistry = accessRegistry_;

        _mint(creator_);
    }

    function _checkBeforeMint(
        address claimer,
        uint256 tokenId
    ) internal virtual {
        if (maxSupply != 0 && tokenId == maxSupply) {
            revert AllClaimed();
        }
        if (claimed[claimer]) {
            revert AlreadyClaimed();
        }
    }

    function _mint(address claimer) internal virtual {
        uint256 tokenId = tokenIdTracker.current();

        _checkBeforeMint(claimer, tokenId);
        _mint(claimer, tokenId);

        claimed[claimer] = true;
        tokenIdTracker.increment();
    }

    function _afterTokenTransfer(
        address,
        address to,
        uint256 tokenId
    ) internal {
        if (tokenId == 0 && owner() != to) {
            _transferOwnership(to);
        }
    }

    function claim() public virtual override {
        address claimer = _msgSender();

        _mint(claimer);
    }

    function claimTo(address claimer) public virtual {
        if (
            !AccessRegistry(accessRegistry).hasRole(
                TRUSTED_CLAIMER_ROLE,
                _msgSender()
            )
        ) {
            revert Forbidden();
        }

        _mint(claimer);
    }

    function hasClaimed(
        address[] calldata claimers
    ) public view virtual override returns (bool[] memory) {
        uint256 length = claimers.length;
        bool[] memory result = new bool[](length);

        for (uint256 i; i < length; i++) {
            result[i] = claimed[claimers[i]];
        }
        return result;
    }

    function supply() public view virtual override returns (uint256, uint256) {
        return (tokenIdTracker.current(), maxSupply);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return (tokenIdTracker.current());
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override(ERC721, IERC721) returns (bool isOperator) {
        if (
            AccessRegistry(accessRegistry).hasRole(
                TRUSTED_OPERATOR_ROLE,
                operator
            )
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(ILemonadePoapV1).interfaceId ||
            interfaceId == type(RoyaltiesV2).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NotFound();
        }

        return tokenURI_;
    }

    function getRaribleV2Royalties(
        uint256
    ) public view override returns (LibPart.Part[] memory) {
        return royalties;
    }

    function royaltyInfo(
        uint256,
        uint256 price
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        uint256 length = royalties.length;

        if (length == 0) {
            return (address(0), 0);
        }

        uint256 totalValue;
        for (uint256 i; i < length; i++) {
            totalValue += royalties[i].value;
        }
        return (royalties[0].account, (price * totalValue) / 10000);
    }
}
