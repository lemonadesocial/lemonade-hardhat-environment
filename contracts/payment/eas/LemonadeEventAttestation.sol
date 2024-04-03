// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/resolver/examples/AttesterResolver.sol";

struct EventData {
    string title;
    string description;
    uint256 start;
    uint256 end;
    string location;
    uint256 guestLimit;
    bytes32 externalEventId;
}

interface ILemonadeEventAttestation {
    function isEventCreator(
        bytes32 _eventUID,
        address user
    ) external view returns (bool);

    function eventCohostSchemaId() external view returns (bytes32);
}

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

    function onAttest(
        Attestation calldata _attestation,
        uint256
    ) internal view override returns (bool) {
        address attester = _attestation.attester;
        bytes32 eventUID = abi.decode(_attestation.data, (bytes32));

        bool isCreator = lea.isEventCreator(eventUID, attester);

        //-- if is creator then
        if (isCreator) return true;

        //-- is not creator but onlyCreator is required
        if (onlyCreator) return false;

        bytes32 proofUID = _attestation.refUID;
        Attestation memory hostAttestation = _eas.getAttestation(proofUID);

        if (
            hostAttestation.schema == lea.eventCohostSchemaId() &&
            hostAttestation.recipient == attester
        ) {
            bytes32 uid = abi.decode(hostAttestation.data, (bytes32));
            return uid == eventUID;
        }

        return false;
    }

    function onRevoke(
        Attestation calldata,
        uint256
    ) internal pure override returns (bool) {
        return true;
    }
}

contract LemonadeEventAttestation is
    OwnableUpgradeable,
    ILemonadeEventAttestation
{
    using ECDSA for bytes;
    using ECDSA for bytes32;

    bytes32 public eventSchemaId;
    bytes32 public eventCohostSchemaId;
    bytes32 public ticketTypeSchemaId;
    bytes32 public ticketSchemaId;

    IEAS internal eas;
    mapping(bytes32 => address) internal eventCreators;

    event EventCreated(address host, bytes32 eventUID);

    function initialize(address _eas) public initializer {
        __Ownable_init();

        eas = IEAS(_eas);

        _initSchemas();
    }

    function registerEvent(EventData calldata eventData) external payable {
        address creator = _msgSender();

        AttestationRequestData memory data = AttestationRequestData(
            creator,
            0,
            true,
            "",
            abi.encode(
                eventData.title,
                eventData.description,
                eventData.start,
                eventData.end,
                eventData.location,
                eventData.guestLimit,
                eventData.externalEventId
            ),
            msg.value
        );

        AttestationRequest memory attestation = AttestationRequest(
            eventSchemaId,
            data
        );

        bytes32 uid = eas.attest(attestation);

        eventCreators[uid] = creator;

        emit EventCreated(creator, uid);
    }

    function isEventCreator(
        bytes32 _eventUID,
        address _user
    ) public view returns (bool) {
        return eventCreators[_eventUID] == _user;
    }

    function isValidTicket(
        bytes32 _ticketUID,
        bytes calldata _signature
    ) external view returns (bool) {
        bytes memory encoded = abi.encode(_ticketUID);

        address signer = encoded.toEthSignedMessageHash().recover(_signature);

        Attestation memory attestation = eas.getAttestation(_ticketUID);

        return
            attestation.schema == ticketSchemaId &&
            attestation.recipient == signer;
    }

    function _initSchemas() internal onlyInitializing {
        ISchemaResolver lemonadeAttesterSchemaResolver = new AttesterResolver(
            eas,
            address(this)
        );
        ISchemaResolver eventCreatorSchemaResolver = new EventHostSchemaResolver(
                eas,
                this,
                true
            );
        ISchemaResolver eventHostsSchemaResolver = new EventHostSchemaResolver(
            eas,
            this,
            false
        );

        _initEventSchema(lemonadeAttesterSchemaResolver);
        _initEventCohostSchema(eventCreatorSchemaResolver);
        _initTicketTypeSchema(eventHostsSchemaResolver);
        _initTicketSchema(eventHostsSchemaResolver);
    }

    function _initEventSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string
            memory schema = "string title, string description, uint256 start, uint256 end, string location, uint256 guestLimit, string externalEventId";

        eventSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initEventCohostSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "bytes32 eventUID";

        eventCohostSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initTicketTypeSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string
            memory schema = "bytes32 eventUID, string title, address currency, uint256 cost";

        ticketTypeSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }

    function _initTicketSchema(
        ISchemaResolver _resolver
    ) internal onlyInitializing {
        string memory schema = "bytes32 eventUID, bytes32 ticketTypeUID";

        ticketSchemaId = eas.getSchemaRegistry().register(
            schema,
            _resolver,
            true
        );
    }
}
