// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GatewayV1Axelar.sol";
import "./GatewayV1Call.sol";
import "./IBaseV1.sol";
import "./Shared.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

contract BaseV1 is ERC165Upgradeable, GatewayV1Axelar, GatewayV1Call, IBaseV1 {
    bytes32 public callNetwork;
    uint256 public maxSupply;

    uint256 private _tokenIdCounter;
    mapping(address => uint256) private _ownedTokens;

    uint256 private _totalReservations;
    mapping(address => uint256) private _ownedReservations;

    mapping(uint256 => address) private _owners;
    mapping(uint256 => bytes32) private _networks;

    function initialize(
        IAxelarGateway axelarGateway,
        IAxelarGasService axelarGasService,
        AxelarNetwork[] calldata axelarNetworks,
        address callAddress,
        bytes32 callNetwork_,
        uint256 maxSupply_
    ) public initializer {
        __GatewayV1Axelar_init(axelarGateway, axelarGasService, axelarNetworks);
        __GatewayV1Call_init(callAddress);

        callNetwork = callNetwork_;
        maxSupply = maxSupply_;

        _tokenIdCounter = 1;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function assign(Assignment[] calldata assignments) public override {
        address sender = _msgSender();

        _assign(sender, assignments);

        emit Assign(sender, assignments);
    }

    function claim(bytes32 network) public payable override {
        address sender = _msgSender();

        uint256 tokenId = _claim(network, sender, msg.value, sender);

        emit Claim(sender, network, tokenId);
    }

    function grant(
        Assignment[] calldata assignments
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _reserve(assignments);
    }

    function balanceOf(
        address owner
    ) public view override returns (uint256 balance) {
        if (_ownedTokens[owner] != 0) {
            balance = 1;
        }
    }

    function networkOf(
        uint256 tokenId
    ) public view override returns (bytes32) {
        if (_owners[tokenId] == address(0)) {
            revert NotFound();
        }

        return _networks[tokenId];
    }

    function ownerOf(
        uint256 tokenId
    ) public view override returns (address owner) {
        owner = _owners[tokenId];

        if (owner == address(0)) {
            revert NotFound();
        }
    }

    function reservations(
        address owner
    ) public view override returns (uint256) {
        return _ownedReservations[owner];
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC165Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IBaseV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token(address owner) public view override returns (uint256) {
        return tokenOfOwnerByIndex(owner, 0);
    }

    function tokenByIndex(
        uint256 index
    ) public view override returns (uint256) {
        if (index >= totalSupply()) {
            revert NotFound();
        }

        return index + 1;
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view override returns (uint256 tokenId) {
        tokenId = _ownedTokens[owner];

        if (tokenId == 0 || index > 0) {
            revert NotFound();
        }
    }

    function totalReservations() public view override returns (uint256) {
        return _totalReservations;
    }

    function totalSupply() public view override returns (uint256) {
        unchecked {
            return _tokenIdCounter - 1;
        }
    }

    function _assign(address sender, Assignment[] memory assignments) internal {
        uint256 count = _increaseOwnedReservations(assignments);

        _requireReservationsDecrease(sender, count);
    }

    function _callContract(
        bytes32 network,
        bytes32 method,
        bytes memory params,
        uint256 gasFee,
        address refundAddress
    ) internal override {
        if (network == callNetwork) {
            return GatewayV1Call._callContract(method, params);
        }

        GatewayV1Axelar._callContract(
            network,
            method,
            params,
            gasFee,
            refundAddress
        );
    }

    function _claim(
        bytes32 network,
        address sender,
        uint256 gasFee,
        address refundAddress
    ) internal returns (uint256 tokenId) {
        tokenId = _mint(network, sender);

        _requireReservationsDecrease(sender, 1);

        unchecked {
            --_totalReservations;
        }

        _callContract(
            network,
            CLAIM_METHOD,
            abi.encode(sender, tokenId),
            gasFee,
            refundAddress
        );
    }

    function _executeAssign(bytes32 network, bytes memory params) internal {
        (address sender, Assignment[] memory assignments) = abi.decode(
            params,
            (address, Assignment[])
        );

        _assign(sender, assignments);

        emit ExecuteAssign(network, sender, assignments);
    }

    function _executeClaim(bytes32 network, bytes memory params) internal {
        address sender = abi.decode(params, (address));

        uint256 tokenId = _claim(network, sender, 0, address(0));

        emit ExecuteClaim(network, sender, tokenId);
    }

    function _executePurchase(bytes32 network, bytes memory params) internal {
        (uint256 purchaseId, address sender, address payable referrer) = abi
            .decode(params, (uint256, address, address));

        if (_ownedTokens[referrer] == 0) {
            delete referrer;
        }

        uint256 tokenId = _mint(network, sender);

        if (tokenId + _totalReservations > maxSupply) {
            revert Forbidden();
        }

        emit ExecutePurchase(network, purchaseId, sender, referrer, tokenId);

        _callContract(
            network,
            PURCHASE_METHOD,
            abi.encode(purchaseId, referrer, tokenId),
            0,
            address(0)
        );
    }

    function _executeReserve(bytes32 network, bytes memory params) internal {
        (
            uint256 paymentId,
            address sender,
            Assignment[] memory assignments
        ) = abi.decode(params, (uint256, address, Assignment[]));

        _reserve(assignments);

        emit ExecuteReserve(network, paymentId, sender, assignments);

        _callContract(
            network,
            RESERVE_METHOD,
            abi.encode(paymentId, _ownedTokens[sender] != 0),
            0,
            address(0)
        );
    }

    function _execute(
        bytes32 network,
        bytes32 method,
        bytes memory params
    ) internal override {
        if (method == ASSIGN_METHOD) {
            _executeAssign(network, params);
        } else if (method == CLAIM_METHOD) {
            _executeClaim(network, params);
        } else if (method == PURCHASE_METHOD) {
            _executePurchase(network, params);
        } else if (method == RESERVE_METHOD) {
            _executeReserve(network, params);
        } else {
            revert NotImplemented();
        }
    }

    function _execute(bytes32 method, bytes memory params) internal override {
        _execute(callNetwork, method, params);
    }

    function _increaseOwnedReservations(
        Assignment[] memory assignments
    ) internal returns (uint256 count) {
        uint256 length = assignments.length;

        for (uint256 i; i < length; ) {
            Assignment memory assignment = assignments[i];

            _ownedReservations[assignment.to] += assignment.count;

            count += assignment.count;

            unchecked {
                ++i;
            }
        }
    }

    function _mint(
        bytes32 network,
        address to
    ) internal returns (uint256 tokenId) {
        if (_ownedTokens[to] != 0) {
            revert Forbidden();
        }

        unchecked {
            tokenId = _tokenIdCounter++;
        }

        _ownedTokens[to] = tokenId;
        _owners[tokenId] = to;
        _networks[tokenId] = network;

        emit Mint(network, to, tokenId);
    }

    function _requireReservationsDecrease(
        address owner,
        uint256 count
    ) internal {
        uint256 ownedReservations = _ownedReservations[owner];

        if (ownedReservations < count) {
            revert Forbidden();
        }

        unchecked {
            _ownedReservations[owner] = ownedReservations - count;
        }
    }

    function _reserve(Assignment[] memory assignments) internal {
        uint256 count = _increaseOwnedReservations(assignments);

        uint256 totalReservations_ = _totalReservations + count;

        if (totalSupply() + totalReservations_ > maxSupply) {
            revert Forbidden();
        }

        _totalReservations = totalReservations_;
    }
}
