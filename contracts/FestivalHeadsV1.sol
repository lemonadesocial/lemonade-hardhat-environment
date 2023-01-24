// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessRegistry.sol";
import "./ChainlinkRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes32 constant FESTIVAL_HEADS_OPERATOR = keccak256("FESTIVAL_HEADS_OPERATOR");
bytes32 constant TRUSTED_CLAIMER_ROLE = keccak256("TRUSTED_CLAIMER_ROLE");

interface IFestivalHeadsV1 is IERC721 {
    function hasClaimed(
        address[] calldata claimers
    ) external view returns (bool[] memory);

    function supply() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);
}

contract FestivalHeadsV1 is ERC721, Ownable, IFestivalHeadsV1 {
    using Counters for Counters.Counter;

    uint256 public maxSupply;
    address public immutable accessRegistry;
    address public chainlinkRequest;

    Counters.Counter public tokenIdTracker;
    mapping(address => bool) public claimed;
    mapping(uint256 => string) public tokenURIs;

    event ClaimFailed(string reason);

    constructor(
        string memory name,
        string memory symbol,
        address creator,
        uint256 maxSupply_,
        address accessRegistry_,
        address chainlinkRequest_
    ) ERC721(name, symbol) {
        _transferOwnership(creator);

        maxSupply = maxSupply_;
        accessRegistry = accessRegistry_;
        chainlinkRequest = chainlinkRequest_;
    }

    function _mint(
        address claimer,
        string memory tokenURI_
    ) internal virtual returns (string memory err) {
        uint256 tokenId = tokenIdTracker.current();

        if (maxSupply != 0 && tokenId == maxSupply) {
            return "FestivalHeadsV1: all tokens claimed";
        }
        if (claimed[claimer]) {
            return "FestivalHeadsV1: already claimed";
        }

        _mint(claimer, tokenId);

        claimed[claimer] = true;
        tokenURIs[tokenId] = tokenURI_;
        tokenIdTracker.increment();
        return "";
    }

    function claimTo(address claimer, string memory tokenURI_) public virtual {
        require(
            AccessRegistry(accessRegistry).hasRole(
                TRUSTED_CLAIMER_ROLE,
                _msgSender()
            ),
            "FestivalHeadsV1: missing trusted claimer role"
        );

        if (chainlinkRequest == address(0)) {
            string memory err = _mint(claimer, tokenURI_);

            if (bytes(err).length > 0) {
                revert(err);
            }
        } else {
            bytes memory state = abi.encode(claimer, tokenURI_);

            ChainlinkRequest(chainlinkRequest).requestBytes(
                this.fulfillClaim.selector,
                state
            );
        }
    }

    function fulfillClaim(
        bytes memory state,
        bytes memory bytesData
    ) public virtual {
        require(
            _msgSender() == chainlinkRequest,
            "FestivalHeadsV1: caller must be access request"
        );

        (bool ok, string memory err) = abi.decode(bytesData, (bool, string));

        if (ok) {
            (address claimer, string memory tokenURI_) = abi.decode(
                state,
                (address, string)
            );

            err = _mint(claimer, tokenURI_);
        }
        if (bytes(err).length > 0) {
            emit ClaimFailed(err);
        }
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

    function _isApprovedOrOwner(
        address spender,
        uint256
    ) internal view virtual override returns (bool) {
        return
            AccessRegistry(accessRegistry).hasRole(
                FESTIVAL_HEADS_OPERATOR,
                spender
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IFestivalHeadsV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "FestivalHeadsV1: URI query for nonexistent token"
        );

        return tokenURIs[tokenId];
    }

    function setChainlinkRequest(
        address chainlinkRequest_
    ) public onlyFestivalHeadsOperator {
        chainlinkRequest = chainlinkRequest_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyFestivalHeadsOperator {
        maxSupply = maxSupply_;
    }

    function burn(
        uint256 tokenId,
        bool reset
    ) public onlyFestivalHeadsOperator {
        if (reset) {
            claimed[ownerOf(tokenId)] = false;
        }

        _burn(tokenId);
    }

    function mint(
        address claimer,
        string memory tokenURI_,
        uint256 tokenId
    ) public onlyFestivalHeadsOperator {
        uint256 nextTokenId = tokenIdTracker.current();

        require(
            tokenId <= nextTokenId && tokenId != maxSupply,
            "FestivalHeadsV1: token out of range"
        );

        _mint(claimer, tokenId);

        claimed[claimer] = true;
        tokenURIs[tokenId] = tokenURI_;

        if (tokenId == nextTokenId) {
            tokenIdTracker.increment();
        }
    }

    modifier onlyFestivalHeadsOperator() {
        require(
            AccessRegistry(accessRegistry).hasRole(
                FESTIVAL_HEADS_OPERATOR,
                _msgSender()
            ),
            "FestivalHeadsV1: caller must be festival heads operator"
        );
        _;
    }
}
