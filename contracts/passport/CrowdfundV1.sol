// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICrowdfundV1.sol";
import "./IPassportV1.sol";
import "./IPassportV1Reserver.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CrowdfundV1 is
    Initializable,
    AccessControlUpgradeable,
    ICrowdfundV1,
    IPassportV1Reserver
{
    IPassportV1 public passport;

    uint256 private _campaignIdCounter;
    struct Campaign {
        State state;
        address payable creator;
        string title;
        string description;
        address payable[] contributors;
        uint256 total;
        uint256 unused;
    }
    mapping(uint256 => Campaign) private _campaigns;
    mapping(uint256 => Assignment[]) private _assignments;
    mapping(uint256 => mapping(address => uint256)) private _contributions;

    function initialize(IPassportV1 passport_) public initializer {
        passport = passport_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    receive() external payable {}

    function create(
        string memory title_,
        string memory description_,
        Assignment[] memory assignments_
    ) public override returns (uint256 campaignId) {
        unchecked {
            campaignId = ++_campaignIdCounter;
        }

        address payable creator_ = payable(_msgSender());

        _campaigns[campaignId] = Campaign({
            state: State.PENDING,
            creator: creator_,
            title: title_,
            description: description_,
            contributors: new address payable[](0),
            total: 0,
            unused: 0
        });

        uint256 length = assignments_.length;

        for (uint256 i; i < length; ) {
            _assignments[campaignId].push(assignments_[i]);

            unchecked {
                ++i;
            }
        }

        emit Create(creator_, title_, description_, assignments_, campaignId);
    }

    function execute(
        uint256 campaignId,
        uint160 roundIds
    ) public payable override {
        uint256 price = countAssignments(_assignments[campaignId]) *
            passport.priceAt(roundIds);

        Campaign storage campaign = _campaigns[campaignId];

        if (campaign.state != State.PENDING || campaign.total < price) {
            revert Forbidden();
        }

        unchecked {
            _campaigns[campaignId].state = State.EXECUTED;
            _campaigns[campaignId].unused = campaign.total - price;
        }

        passport.reserve{value: price + msg.value}(
            roundIds,
            _assignments[campaignId],
            abi.encode(campaignId)
        );

        emit Execute(campaignId);
    }

    function fund(
        uint256 campaignId
    ) public payable override whenExists(campaignId) {
        if (_campaigns[campaignId].state != State.PENDING || msg.value == 0) {
            revert Forbidden();
        }

        address payable contributor = payable(_msgSender());
        uint256 contribution = _contributions[campaignId][contributor];

        if (contribution == 0) {
            _campaigns[campaignId].contributors.push(contributor);
        }

        _campaigns[campaignId].total += msg.value;
        _contributions[campaignId][contributor] = contribution + msg.value;

        emit Fund(campaignId, msg.value);
    }

    function onPassportV1Reserved(
        bool success,
        bytes calldata data
    ) public override {
        uint256 campaignId = abi.decode(data, (uint256));

        Campaign memory campaign = _campaigns[campaignId];

        if (
            _msgSender() != address(passport) ||
            campaign.state != State.EXECUTED
        ) {
            revert Forbidden();
        }

        if (success) {
            _campaigns[campaignId].state = State.CONFIRMED;

            if (campaign.unused > 0) {
                sendValue(campaign.creator, campaign.unused);
            }
        } else {
            _refund(campaignId);
        }
    }

    function refund(uint256 campaignId) public override whenExists(campaignId) {
        Campaign memory campaign = _campaigns[campaignId];

        if (
            _msgSender() != campaign.creator || campaign.state != State.PENDING
        ) {
            revert Forbidden();
        }

        _refund(campaignId);
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sendValue(recipient, amount);
    }

    function assignments(
        uint256 campaignId
    )
        public
        view
        override
        whenExists(campaignId)
        returns (Assignment[] memory)
    {
        return _assignments[campaignId];
    }

    function contributors(
        uint256 campaignId
    )
        public
        view
        override
        whenExists(campaignId)
        returns (address payable[] memory)
    {
        return _campaigns[campaignId].contributors;
    }

    function creator(
        uint256 campaignId
    ) public view override whenExists(campaignId) returns (address) {
        return _campaigns[campaignId].creator;
    }

    function description(
        uint256 campaignId
    ) public view override whenExists(campaignId) returns (string memory) {
        return _campaigns[campaignId].description;
    }

    function goal(
        uint256 campaignId
    )
        public
        view
        override
        whenExists(campaignId)
        returns (uint160, uint256 amount)
    {
        (uint160 roundIds, uint256 price) = passport.price();

        return (roundIds, countAssignments(_assignments[campaignId]) * price);
    }

    function state(
        uint256 campaignId
    ) public view override whenExists(campaignId) returns (State) {
        return _campaigns[campaignId].state;
    }

    function title(
        uint256 campaignId
    ) public view override whenExists(campaignId) returns (string memory) {
        return _campaigns[campaignId].title;
    }

    function total(
        uint256 campaignId
    ) public view override whenExists(campaignId) returns (uint256) {
        return _campaigns[campaignId].total;
    }

    function _refund(uint256 campaignId) internal {
        Campaign memory campaign = _campaigns[campaignId];

        if (campaign.state == State.REFUNDED) {
            revert Forbidden();
        }

        _campaigns[campaignId].state = State.REFUNDED;

        uint256 length = campaign.contributors.length;

        for (uint256 i; i < length; ) {
            address payable contributor = campaign.contributors[i];

            sendValue(contributor, _contributions[campaignId][contributor]);

            unchecked {
                ++i;
            }
        }
    }

    modifier whenExists(uint256 campaignId) {
        if (_campaigns[campaignId].creator == address(0)) {
            revert NotFound();
        }

        _;
    }
}
