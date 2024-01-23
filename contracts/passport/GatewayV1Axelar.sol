// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Shared.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract GatewayV1Axelar is
    AccessControlUpgradeable,
    IAxelarExecutable
{
    IAxelarGateway public override gateway;
    IAxelarGasService public gasService;

    struct AxelarDestination {
        string chain;
        string contractAddress;
    }
    mapping(bytes32 => AxelarDestination) public axelarDestinations;
    mapping(string => mapping(string => bytes32)) public axelarSources;

    struct AxelarNetwork {
        bytes32 network;
        AxelarDestination axelarDestination;
    }

    function __GatewayV1Axelar_init(
        IAxelarGateway axelarGateway,
        IAxelarGasService axelarGasService,
        AxelarNetwork[] calldata axelarNetworks
    ) internal onlyInitializing {
        __GatewayV1Axelar_init_unchained(
            axelarGateway,
            axelarGasService,
            axelarNetworks
        );
    }

    function __GatewayV1Axelar_init_unchained(
        IAxelarGateway axelarGateway,
        IAxelarGasService axelarGasService,
        AxelarNetwork[] calldata axelarNetworks
    ) internal onlyInitializing {
        gateway = axelarGateway;
        gasService = axelarGasService;

        _addAxelarNetworks(axelarNetworks);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 network = axelarSources[sourceChain][sourceAddress];

        if (network == 0) {
            revert Forbidden();
        }

        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCall(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash
            )
        ) {
            revert NotApprovedByGateway();
        }

        (bytes32 method, bytes memory params) = abi.decode(
            payload,
            (bytes32, bytes)
        );

        _execute(network, method, params);
    }

    function executeWithToken(
        bytes32,
        string calldata,
        string calldata,
        bytes calldata,
        string calldata,
        uint256
    ) external pure override {
        revert NotImplemented();
    }

    function addAxelarNetworks(
        AxelarNetwork[] calldata axelarNetworks
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAxelarNetworks(axelarNetworks);
    }

    function removeAxelarNetworks(
        bytes32[] calldata axelarNetworks
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = axelarNetworks.length;

        for (uint256 i; i < length; ) {
            bytes32 axelarNetwork = axelarNetworks[i];

            AxelarDestination memory axelarDestination = axelarDestinations[
                axelarNetwork
            ];

            delete axelarSources[axelarDestination.chain][
                axelarDestination.contractAddress
            ];
            delete axelarDestinations[axelarNetwork];

            unchecked {
                ++i;
            }
        }
    }

    function _addAxelarNetworks(
        AxelarNetwork[] calldata axelarNetworks
    ) internal {
        uint256 length = axelarNetworks.length;

        for (uint256 i; i < length; ) {
            AxelarNetwork calldata axelarNetwork = axelarNetworks[i];

            axelarDestinations[axelarNetwork.network] = axelarNetwork
                .axelarDestination;
            axelarSources[axelarNetwork.axelarDestination.chain][
                axelarNetwork.axelarDestination.contractAddress
            ] = axelarNetwork.network;

            unchecked {
                ++i;
            }
        }
    }

    function _callContract(
        bytes32 network,
        bytes32 method,
        bytes memory params,
        uint256 gasFee,
        address refundAddress
    ) internal virtual {
        AxelarDestination memory axelarDestination = axelarDestinations[
            network
        ];

        if (bytes(axelarDestination.chain).length == 0) {
            revert Forbidden();
        }

        bytes memory payload = abi.encode(method, params);

        if (gasFee > 0) {
            gasService.payNativeGasForContractCall{value: gasFee}(
                address(this),
                axelarDestination.chain,
                axelarDestination.contractAddress,
                payload,
                refundAddress
            );
        }

        gateway.callContract(
            axelarDestination.chain,
            axelarDestination.contractAddress,
            payload
        );
    }

    function _execute(
        bytes32 network,
        bytes32 method,
        bytes memory params
    ) internal virtual;

    uint256[46] private __gap;
}
