// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessRegistry.sol";
import "./ChainlinkRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

bytes32 constant FESTIVAL_HEADS_OPERATOR_ROLE = keccak256("FESTIVAL_HEADS_OPERATOR_ROLE");
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

    error AllClaimed();
    error AlreadyClaimed();
    error Forbidden();
    error NotFound();

    event ClaimFailed(string reason);
    event ClaimFailedBytes(bytes reason);

    uint256 public maxSupply;
    address public immutable accessRegistry;
    address public chainlinkRequest;

    Counters.Counter public tokenIdTracker;
    mapping(address => bool) public claimed;
    mapping(uint256 => string) public tokenURIs;

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

    function _checkBeforeMint(
        address claimer,
        uint256 tokenId
    ) internal virtual {
        if (tokenId >= maxSupply) {
            revert AllClaimed();
        }
        if (claimed[claimer]) {
            revert AlreadyClaimed();
        }
    }

    function _mint(address claimer, string memory tokenURI_) internal virtual {
        uint256 tokenId = tokenIdTracker.current();

        _checkBeforeMint(claimer, tokenId);
        _mint(claimer, tokenId);

        claimed[claimer] = true;
        tokenURIs[tokenId] = tokenURI_;
        tokenIdTracker.increment();
    }

    function claimTo(address claimer, string memory tokenURI_) public virtual {
        if (
            !AccessRegistry(accessRegistry).hasRole(
                TRUSTED_CLAIMER_ROLE,
                _msgSender()
            )
        ) {
            revert Forbidden();
        }

        if (chainlinkRequest == address(0)) {
            return _mint(claimer, tokenURI_);
        }

        _checkBeforeMint(claimer, tokenIdTracker.current());

        bytes memory state = abi.encode(claimer, tokenURI_);

        ChainlinkRequest(chainlinkRequest).requestBytes(
            this.fulfillClaim.selector,
            state
        );
    }

    function fulfillMint(address claimer, string memory tokenURI_) external {
        if (_msgSender() != address(this)) {
            revert Forbidden();
        }

        _mint(claimer, tokenURI_);
    }

    function fulfillClaim(
        bytes memory state,
        bytes memory bytesData
    ) public virtual {
        if (_msgSender() != chainlinkRequest) {
            revert Forbidden();
        }

        (bool ok, string memory err) = abi.decode(bytesData, (bool, string));

        if (ok) {
            (address claimer, string memory tokenURI_) = abi.decode(
                state,
                (address, string)
            );

            try this.fulfillMint(claimer, tokenURI_) {
                /* no-op */
            } catch Error(string memory reason) {
                err = reason;
            } catch (bytes memory reason) {
                emit ClaimFailedBytes(reason);
            }
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
                FESTIVAL_HEADS_OPERATOR_ROLE,
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
        if (!_exists(tokenId)) {
            revert NotFound();
        }

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

        if (tokenId > nextTokenId) {
            revert NotFound();
        }

        _mint(claimer, tokenId);

        claimed[claimer] = true;
        tokenURIs[tokenId] = tokenURI_;

        if (tokenId == nextTokenId) {
            tokenIdTracker.increment();
        }
    }

    modifier onlyFestivalHeadsOperator() {
        if (
            !AccessRegistry(accessRegistry).hasRole(
                FESTIVAL_HEADS_OPERATOR_ROLE,
                _msgSender()
            )
        ) {
            revert Forbidden();
        }
        _;
    }
}
