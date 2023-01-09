// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

uint256 constant maxPurchases = 5;
uint256 constant price = 0.001 ether;

contract DirtyBurgerClub is AccessControl, ERC721 {
    using Strings for uint256;

    error IncorrectCount();
    error IncorrectProof();
    error IncorrectValue();
    error NotFound();

    string public baseURI;
    uint256 public maxSupply;
    uint public publicDate;
    bytes32 public merkleRoot;

    mapping(address => uint256) public purchases;
    uint256 public totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        uint256 maxSupply_,
        uint publicDate_,
        bytes32 merkleRoot_
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        baseURI = baseURI_;
        maxSupply = maxSupply_;
        publicDate = publicDate_;
        merkleRoot = merkleRoot_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NotFound();
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function purchase(
        uint256 count,
        bytes32[] calldata merkleProof
    ) public payable virtual {
        address to = _msgSender();

        if (
            block.timestamp < publicDate &&
            !MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(bytes.concat(keccak256(abi.encode(to))))
            )
        ) {
            revert IncorrectProof();
        }

        if (
            count > maxPurchases ||
            purchases[to] + count > maxPurchases ||
            totalSupply + count > maxSupply
        ) {
            revert IncorrectCount();
        }

        if (price * count != msg.value) {
            revert IncorrectValue();
        }

        uint256 currentSupply = totalSupply;

        for (uint256 i; i < count; ) {
            _mint(to, currentSupply + i);
            unchecked {
                ++i;
            }
        }

        purchases[to] = purchases[to] + count;
        totalSupply = totalSupply + count;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function configure(
        string memory baseURI_,
        uint256 maxSupply_,
        uint publicDate_,
        bytes32 merkleRoot_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
        maxSupply = maxSupply_;
        publicDate = publicDate_;
        merkleRoot = merkleRoot_;
    }

    function withdraw(
        address payable to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        to.transfer(amount);
    }
}
