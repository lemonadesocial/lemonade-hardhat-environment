// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";

import "../ILemonadeEventAttestation.sol";
import "./EventHostSchemaResolver.sol";

contract TicketIssuingSchemaResolver is SchemaResolver {
    EventHostSchemaResolver internal hostResolver;

    constructor(
        IEAS _eas,
        EventHostSchemaResolver _hostResolver
    ) SchemaResolver(_eas) {
        hostResolver = _hostResolver;
    }

    function onAttest(
        Attestation calldata _attestation,
        uint256
    ) internal view override returns (bool) {
        address attester = _attestation.attester;

        bytes32 ticketTypeUID = abi.decode(_attestation.data, (bytes32));

        Attestation memory ticketTypeAttestation = _eas.getAttestation(
            ticketTypeUID
        );

        return
            isValidAttestation(ticketTypeAttestation) &&
            hostResolver.isHost(
                attester,
                ticketTypeAttestation.recipient,
                _attestation.refUID
            );
    }

    function onRevoke(
        Attestation calldata,
        uint256
    ) internal pure override returns (bool) {
        return true;
    }
}
