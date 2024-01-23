// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GatewayV1Axelar.sol";
import "./PassportV1.sol";

bytes32 constant BASE_NETWORK = keccak256("BASE_NETWORK");

contract PassportV1Axelar is GatewayV1Axelar, PassportV1 {
    function initialize(
        IAxelarGateway axelarGateway,
        IAxelarGasService axelarGasService,
        AxelarNetwork[] calldata axelarNetworks,
        string memory name,
        string memory symbol,
        uint256 priceAmount,
        AggregatorV3Interface priceFeed1,
        AggregatorV3Interface priceFeed2,
        uint256 incentive,
        address payable treasury,
        IDrawerV1 drawer
    ) public initializer {
        __GatewayV1Axelar_init(axelarGateway, axelarGasService, axelarNetworks);
        __PassportV1_init(
            name,
            symbol,
            priceAmount,
            priceFeed1,
            priceFeed2,
            incentive,
            treasury,
            drawer
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, PassportV1)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _callContract(
        bytes32 method,
        bytes memory params,
        uint256 gasFee,
        address refundAddress
    ) internal override {
        GatewayV1Axelar._callContract(
            BASE_NETWORK,
            method,
            params,
            gasFee,
            refundAddress
        );
    }

    function _execute(
        bytes32,
        bytes32 method,
        bytes memory params
    ) internal override {
        PassportV1._execute(method, params);
    }
}
