// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Shared.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract GatewayV1Call is AccessControlUpgradeable {
    using AddressUpgradeable for address;

    address public callAddress;

    function __GatewayV1Call_init(
        address callAddress_
    ) internal onlyInitializing {
        __GatewayV1Call_init_unchained(callAddress_);
    }

    function __GatewayV1Call_init_unchained(
        address callAddress_
    ) internal onlyInitializing {
        callAddress = callAddress_;
    }

    function execute(bytes32 method, bytes memory params) external {
        if (_msgSender() != callAddress) {
            revert Forbidden();
        }

        _execute(method, params);
    }

    function setCallAddress(
        address callAddress_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callAddress = callAddress_;
    }

    function _callContract(bytes32 method, bytes memory params) internal {
        callAddress.functionCall(
            abi.encodeWithSelector(this.execute.selector, method, params)
        );
    }

    function _execute(bytes32 method, bytes memory params) internal virtual;

    uint256[49] private __gap;
}
