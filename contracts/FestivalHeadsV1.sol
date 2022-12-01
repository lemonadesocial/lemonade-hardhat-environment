// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessRegistry.sol";
import "./ChainlinkRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes32 constant TRUSTED_CLAIMER_ROLE = keccak256("TRUSTED_CLAIMER_ROLE");
bytes32 constant TRUSTED_OPERATOR_ROLE = keccak256("TRUSTED_OPERATOR_ROLE");

interface IFestivalHeadsV1 is IERC721 {
    function hasClaimed(
        address[] calldata claimers
    ) external view returns (bool[] memory);

    function supply() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);
}

contract FestivalHeadsV1 is ERC721Burnable, Ownable, IFestivalHeadsV1 {
    using Counters for Counters.Counter;

    uint256 public immutable maxSupply;
    address public immutable accessRegistry;
    address public chainlinkRequest;

    Counters.Counter public tokenIdTracker;
    mapping(address => bool) public claimed;
    mapping(uint256 => string) public tokenURIs;

    event ClaimFailed(string reason);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        address accessRegistry_,
        address chainlinkRequest_
    ) ERC721(name, symbol) {
        maxSupply = maxSupply_;
        accessRegistry = accessRegistry_;
        chainlinkRequest = chainlinkRequest_;
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

        return ERC721.isApprovedForAll(owner, operator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IFestivalHeadsV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setChainlinkRequest(address chainlinkRequest_) public onlyOwner {
        chainlinkRequest = chainlinkRequest_;
    }
}
