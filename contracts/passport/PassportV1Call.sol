// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GatewayV1Call.sol";
import "./PassportV1.sol";

contract PassportV1Call is GatewayV1Call, PassportV1 {
    function initialize(
        address callAddress,
        string memory name,
        string memory symbol,
        uint256 priceAmount,
        AggregatorV3Interface priceFeed1,
        AggregatorV3Interface priceFeed2,
        address payable treasury,
        IDrawerV1 drawer
    ) public initializer {
        __GatewayV1Call_init(callAddress);
        __PassportV1_init(
            name,
            symbol,
            priceAmount,
            priceFeed1,
            priceFeed2,
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
        uint256,
        address
    ) internal override {
        GatewayV1Call._callContract(method, params);
    }

    function _execute(
        bytes32 method,
        bytes memory params
    ) internal override(GatewayV1Call, PassportV1) {
        PassportV1._execute(method, params);
    }

    function _afterExecutePurchase(bool success) internal pure override {
        if (!success) {
            revert Forbidden();
        }
    }

    function _afterExecuteReserve(bool success) internal pure override {
        if (!success) {
            revert Forbidden();
        }
    }
}
