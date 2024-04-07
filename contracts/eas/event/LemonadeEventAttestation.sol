// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/resolver/examples/AttesterResolver.sol";

import "./ILemonadeEventAttestation.sol";
import "./resolvers/EventHostSchemaResolver.sol";
import "./resolvers/TicketIssuingSchemaResolver.sol";

contract Event {}

contract LemonadeEventAttestation is
    OwnableUpgradeable,
    ILemonadeEventAttestation
{
    using ECDSA for bytes;
    using ECDSA for bytes32;

    bytes32 public eventCreatorSchemaId;
    bytes32 public eventDetailSchemaId;
    bytes32 public eventCohostSchemaId;
    bytes32 public ticketTypeSchemaId;
    bytes32 public ticketSchemaId;

    IEAS internal eas;

    event EventCreated(
        address eventAddress,
        address creator,
        bytes32 attestation
    );

    function initialize(address _eas) public initializer {
        __Ownable_init();

        eas = IEAS(_eas);

        _initSchemas();
    }

    function registerEvent() external payable {
        address creator = _msgSender();

        Event event_ = new Event();

        address eventAddress = address(event_);

        AttestationRequestData memory data = AttestationRequestData(
            eventAddress,
            0,
            true,
            "",
            abi.encode(creator),
            msg.value
        );

        AttestationRequest memory request = AttestationRequest(
            eventCreatorSchemaId,
            data
        );

        bytes32 attestation = eas.attest(request);

        emit EventCreated(eventAddress, creator, attestation);
    }

    function isValidTicket(
        bytes32 _ticketUID,
        bytes calldata _signature
    ) external view returns (bool) {
        bytes memory encoded = abi.encode(_ticketUID);

        address signer = encoded.toEthSignedMessageHash().recover(_signature);

        Attestation memory attestation = eas.getAttestation(_ticketUID);

        return
            isValidAttestation(attestation) &&
            attestation.schema == ticketSchemaId &&
            attestation.recipient == signer;
    }

    function _initSchemas() internal onlyInitializing {
        ISchemaResolver lemonadeAttesterSchemaResolver = new AttesterResolver(
            eas,
            address(this)
        );

        ISchemaResolver creatorSchemaResolver = new EventHostSchemaResolver(
            eas,
            this,
            true
        );

        EventHostSchemaResolver hostSchemaResolver = new EventHostSchemaResolver(
            eas,
            this,
            false
        );

        ISchemaResolver ticketSchemaResolver = new TicketIssuingSchemaResolver(
            eas,
            hostSchemaResolver
        );

        _initEventCreatorSchema(lemonadeAttesterSchemaResolver);
        _initEventCohostSchema(creatorSchemaResolver);
        _initEventDetailSchema(hostSchemaResolver);
        _initTicketTypeSchema(hostSchemaResolver);
        _initTicketSchema(ticketSchemaResolver);
    }

    function _initEventCreatorSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "address creator";

        eventCreatorSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initEventCohostSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "address cohost";

        eventCohostSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initEventDetailSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string
            memory schema = "string title, string description, uint256 start, uint256 end, string location";

        eventDetailSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initTicketTypeSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "string title, address currency, uint256 cost";

        ticketTypeSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initTicketSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "bytes32 ticketTypeUID";

        ticketSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }
}
