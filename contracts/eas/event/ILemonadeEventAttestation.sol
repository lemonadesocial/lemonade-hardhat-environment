// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";

interface ILemonadeEventAttestation {
    function eventCreatorSchemaId() external view returns (bytes32);

    function eventCohostSchemaId() external view returns (bytes32);

    function ticketSchemaId() external view returns (bytes32);
}

function isValidAttestation(
    Attestation memory attestation
) view returns (bool) {
    return
        attestation.revocationTime == 0 &&
        (attestation.expirationTime == 0 ||
            attestation.expirationTime >= block.timestamp);
}
