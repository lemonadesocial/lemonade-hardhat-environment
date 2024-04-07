// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";

import "../ILemonadeEventAttestation.sol";

contract EventHostSchemaResolver is SchemaResolver {
    bool internal onlyCreator;
    ILemonadeEventAttestation internal lea;

    constructor(
        IEAS _eas,
        ILemonadeEventAttestation _lea,
        bool _onlyCreator
    ) SchemaResolver(_eas) {
        onlyCreator = _onlyCreator;
        lea = _lea;
    }

    function isHost(
        address user,
        address eventAddress,
        bytes32 attestation
    ) public view returns (bool) {
        Attestation memory hostAttestation = _eas.getAttestation(attestation);

        if (!isValidAttestation(hostAttestation)) return false;

        if (hostAttestation.schema == lea.eventCreatorSchemaId()) {
            address creator = abi.decode(hostAttestation.data, (address));

            return hostAttestation.recipient == eventAddress && user == creator;
        } else if (hostAttestation.schema == lea.eventCohostSchemaId()) {
            if (onlyCreator) return false;

            address cohost = abi.decode(hostAttestation.data, (address));

            return hostAttestation.recipient == eventAddress && user == cohost;
        }

        return false;
    }

    function onAttest(
        Attestation calldata _attestation,
        uint256
    ) internal view override returns (bool) {
        return
            isHost(
                _attestation.attester,
                _attestation.recipient,
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
