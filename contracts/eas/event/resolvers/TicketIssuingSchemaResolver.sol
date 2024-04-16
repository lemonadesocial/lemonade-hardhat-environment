// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";

import "../ILemonadeEventAttestation.sol";
import "./EventHostSchemaResolver.sol";

contract TicketIssuingSchemaResolver is SchemaResolver {
    ILemonadeEventAttestation internal lea;
    EventHostSchemaResolver internal hostResolver;

    constructor(
        IEAS _eas,
        ILemonadeEventAttestation _lea,
        EventHostSchemaResolver _hostResolver
    ) SchemaResolver(_eas) {
        lea = _lea;
        hostResolver = _hostResolver;
    }

    function onAttest(
        Attestation calldata _attestation,
        uint256
    ) internal view override returns (bool) {
        address attester = _attestation.attester;

        if (attester == _attestation.recipient) {
            //-- it's user trying to attest his owned ticket
            Attestation memory ticketAttestation = _eas.getAttestation(
                _attestation.refUID
            );

            return
                isValidAttestation(ticketAttestation) &&
                ticketAttestation.schema == lea.ticketSchemaId() &&
                ticketAttestation.recipient == attester;
        } else {
            //-- it's host attesting ticket for user
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
    }

    function onRevoke(
        Attestation calldata,
        uint256
    ) internal pure override returns (bool) {
        return true;
    }
}
