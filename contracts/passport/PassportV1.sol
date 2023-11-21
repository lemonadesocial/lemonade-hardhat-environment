// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDrawerV1.sol";
import "./IPassportV1.sol";
import "./IPassportV1Purchaser.sol";
import "./IPassportV1Reserver.sol";
import "./Shared.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

uint256 constant PAYMENT_PRICE_MAX_AGE = 3600;
uint256 constant PAYMENT_REFERRER_PERCENTAGE = 5;

abstract contract PassportV1 is
    AccessControlUpgradeable,
    ERC721Upgradeable,
    IPassportV1
{
    uint256 public priceAmount;
    AggregatorV3Interface public priceFeed1;
    AggregatorV3Interface public priceFeed2;
    address payable public treasury;
    IDrawerV1 public drawer;

    uint256 private _paymentIdCounter;
    struct Payment {
        address payable sender;
        uint256 value;
        bytes data;
    }
    mapping(uint256 => Payment) private _payments;

    uint256[] private _allTokens;
    mapping(address => uint256) private _tokens;

    mapping(uint256 => uint256) private _createdAts;
    mapping(uint256 => uint256) private _updatedAts;
    mapping(uint256 => mapping(bytes32 => bytes)) private _properties;

    function __PassportV1_init(
        string memory name,
        string memory symbol,
        uint256 priceAmount_,
        AggregatorV3Interface priceFeed1_,
        AggregatorV3Interface priceFeed2_,
        address payable treasury_,
        IDrawerV1 drawer_
    ) internal onlyInitializing {
        __ERC721_init_unchained(name, symbol);
        __PassportV1_init_unchained(
            priceAmount_,
            priceFeed1_,
            priceFeed2_,
            treasury_,
            drawer_
        );
    }

    function __PassportV1_init_unchained(
        uint256 priceAmount_,
        AggregatorV3Interface priceFeed1_,
        AggregatorV3Interface priceFeed2_,
        address payable treasury_,
        IDrawerV1 drawer_
    ) internal onlyInitializing {
        priceAmount = priceAmount_;
        priceFeed1 = priceFeed1_;
        priceFeed2 = priceFeed2_;
        treasury = treasury_;
        drawer = drawer_;
    }

    function assign(Assignment[] calldata assignments) public payable override {
        address sender = _msgSender();

        emit Assign(sender, assignments);

        _callContract(
            ASSIGN_METHOD,
            abi.encode(sender, assignments),
            msg.value,
            sender
        );
    }

    function claim() public payable override whenNotToken {
        address sender = _msgSender();

        emit Claim(sender);

        _callContract(CLAIM_METHOD, abi.encode(sender), msg.value, sender);
    }

    function purchase(
        uint160 roundIds,
        address payable referrer,
        bytes calldata data
    ) public payable override whenNotToken {
        (
            uint256 paymentId,
            Payment memory payment,
            uint256 unused
        ) = _createPayment(roundIds, 1, data);

        emit Purchase(paymentId, payment.sender, payment.value, referrer);

        _callContract(
            PURCHASE_METHOD,
            abi.encode(paymentId, payment.sender, referrer),
            unused,
            payment.sender
        );
    }

    function reserve(
        uint160 roundIds,
        Assignment[] calldata assignments,
        bytes calldata data
    ) public payable override {
        (
            uint256 paymentId,
            Payment memory payment,
            uint256 unused
        ) = _createPayment(roundIds, countAssignments(assignments), data);

        emit Reserve(paymentId, payment.sender, payment.value, assignments);

        _callContract(
            RESERVE_METHOD,
            abi.encode(paymentId, payment.sender, assignments),
            unused,
            payment.sender
        );
    }

    function setProperty(bytes32 key, bytes calldata value) public override {
        uint256 tokenId = _requireTokenUpdate();

        _properties[tokenId][key] = value;

        emit SetProperty(tokenId, key, value);
    }

    function setPropertyBatch(Property[] calldata properties) public override {
        uint256 tokenId = _requireTokenUpdate();

        uint256 length = properties.length;

        for (uint256 i; i < length; ) {
            Property memory property_ = properties[i];

            _properties[tokenId][property_.key] = property_.value;

            unchecked {
                ++i;
            }
        }

        emit SetPropertyBatch(tokenId, properties);
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sendValue(recipient, amount);
    }

    function withdrawPayment(
        uint256 paymentId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Payment memory payment = _requirePaymentDelete(paymentId);

        sendValue(payment.sender, payment.value);
    }

    function createdAt(
        uint256 tokenId
    ) public view override whenMinted(tokenId) returns (uint256) {
        return _createdAts[tokenId];
    }

    function property(
        uint256 tokenId,
        bytes32 key
    ) public view override whenMinted(tokenId) returns (bytes memory) {
        return _properties[tokenId][key];
    }

    function propertyBatch(
        uint256 tokenId,
        bytes32[] calldata keys
    ) public view override whenMinted(tokenId) returns (bytes[] memory values) {
        uint256 length = keys.length;

        for (uint256 i; i < length; ) {
            values[i] = _properties[tokenId][keys[i]];

            unchecked {
                ++i;
            }
        }
    }

    function price() public view override returns (uint160 roundIds, uint256) {
        int256 answer1;
        int256 answer2;

        if (address(priceFeed1) != address(0)) {
            (uint80 roundId, int256 answer, , , ) = priceFeed1
                .latestRoundData();

            roundIds |= roundId;
            answer1 = answer;
        }

        if (address(priceFeed2) != address(0)) {
            (uint80 roundId, int256 answer, , , ) = priceFeed2
                .latestRoundData();

            roundIds |= uint160(roundId) << 80;
            answer2 = answer;
        }

        return (roundIds, _price(answer1, answer2));
    }

    function priceAt(uint160 roundIds) public view override returns (uint256) {
        int256 answer1;
        int256 answer2;

        if (address(priceFeed1) != address(0)) {
            answer1 = _getRoundAnswer(priceFeed1, uint80(roundIds));
        }

        if (address(priceFeed2) != address(0)) {
            answer2 = _getRoundAnswer(priceFeed2, uint80(roundIds >> 80));
        }

        return _price(answer1, answer2);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IPassportV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token(address owner) public view override returns (uint256) {
        return tokenOfOwnerByIndex(owner, 0);
    }

    function tokenByIndex(
        uint256 index
    ) public view override returns (uint256) {
        if (index >= _allTokens.length) {
            revert NotFound();
        }

        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view override returns (uint256 tokenId) {
        tokenId = _tokens[owner];

        if (tokenId == 0 || index > 0) {
            revert NotFound();
        }
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        whenMinted(tokenId)
        returns (string memory)
    {
        return drawer.tokenURI(this, tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        return _allTokens.length;
    }

    function updatedAt(
        uint256 tokenId
    ) public view override whenMinted(tokenId) returns (uint256) {
        return _updatedAts[tokenId];
    }

    function _afterExecutePurchase(bool success) internal virtual {}

    function _afterExecuteReserve(bool success) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal override {
        if (from != address(0) || _tokens[to] != 0) {
            revert Forbidden();
        }

        _allTokens.push(tokenId);
        _tokens[to] = tokenId;

        _createdAts[tokenId] = block.timestamp;
    }

    function _callContract(
        bytes32 method,
        bytes memory params,
        uint256 gasFee,
        address refundAddress
    ) internal virtual;

    function _createPayment(
        uint160 roundIds,
        uint256 count,
        bytes calldata data
    )
        internal
        returns (uint256 paymentId, Payment memory payment, uint256 unused)
    {
        payment = Payment({
            sender: payable(_msgSender()),
            value: count * priceAt(roundIds),
            data: data
        });

        if (msg.value < payment.value) {
            revert Forbidden();
        }

        unchecked {
            paymentId = _paymentIdCounter++;
            unused = msg.value - payment.value;
        }

        _payments[paymentId] = payment;
    }

    function _doHook(address target, bytes memory data) internal {
        if (target.code.length > 0) {
            (bool success, ) = target.call(data);
            success;
        }
    }

    function _executeClaim(bytes memory params) internal {
        (address sender, uint256 tokenId) = abi.decode(
            params,
            (address, uint256)
        );

        _mint(sender, tokenId);

        emit ExecuteClaim(sender, tokenId);
    }

    function _executePurchase(bytes memory params) internal {
        (
            uint256 paymentId,
            address payable referrer,
            uint256 tokenId,
            bool success
        ) = abi.decode(params, (uint256, address, uint256, bool));

        Payment memory payment = _requirePaymentDelete(paymentId);

        emit ExecutePurchase(
            paymentId,
            payment.sender,
            payment.value,
            referrer,
            tokenId,
            success
        );

        if (success) {
            _mint(payment.sender, tokenId);

            if (referrer != address(0)) {
                uint256 n = (payment.value * PAYMENT_REFERRER_PERCENTAGE) / 100;

                sendValue(payment.sender, n);
                sendValue(referrer, n);

                payment.value -= n + n;
            }
        }

        sendValue(success ? treasury : payment.sender, payment.value);

        _afterExecutePurchase(success);

        _doHook(
            payment.sender,
            abi.encodeWithSelector(
                IPassportV1Purchaser.onPassportV1Purchased.selector,
                success,
                payment.data
            )
        );
    }

    function _executeReserve(bytes memory params) internal {
        (uint256 paymentId, bool referred, bool success) = abi.decode(
            params,
            (uint256, bool, bool)
        );

        Payment memory payment = _requirePaymentDelete(paymentId);

        emit ExecuteReserve(
            paymentId,
            payment.sender,
            payment.value,
            referred,
            success
        );

        if (success && referred) {
            uint256 n = (payment.value * PAYMENT_REFERRER_PERCENTAGE) / 100;

            sendValue(payment.sender, n);

            payment.value -= n;
        }

        sendValue(success ? treasury : payment.sender, payment.value);

        _afterExecuteReserve(success);

        _doHook(
            payment.sender,
            abi.encodeWithSelector(
                IPassportV1Reserver.onPassportV1Reserved.selector,
                success,
                payment.data
            )
        );
    }

    function _execute(bytes32 method, bytes memory params) internal virtual {
        if (method == CLAIM_METHOD) {
            _executeClaim(params);
        } else if (method == PURCHASE_METHOD) {
            _executePurchase(params);
        } else if (method == RESERVE_METHOD) {
            _executeReserve(params);
        } else {
            revert NotImplemented();
        }
    }

    function _getRoundAnswer(
        AggregatorV3Interface priceFeed,
        uint80 roundId
    ) internal view returns (int256) {
        (, int256 answer, , uint256 timestamp, ) = priceFeed.getRoundData(
            roundId
        );

        if (timestamp < block.timestamp - PAYMENT_PRICE_MAX_AGE) {
            revert Forbidden();
        }

        return answer;
    }

    function _requirePaymentDelete(
        uint256 paymentId
    ) internal returns (Payment memory state) {
        state = _payments[paymentId];

        if (state.sender == address(0)) {
            revert Forbidden();
        }

        delete _payments[paymentId];
    }

    function _requireTokenUpdate() internal returns (uint256 tokenId) {
        tokenId = _tokens[_msgSender()];

        if (tokenId == 0) {
            revert Forbidden();
        }

        _updatedAts[tokenId] = block.timestamp;
    }

    function _price(
        int256 answer1,
        int256 answer2
    ) internal view returns (uint256) {
        uint256 base = 1e18;
        uint256 quote = 1e18;

        if (address(priceFeed1) != address(0)) {
            base = _priceFeedAnswer(priceFeed1, answer1);
        }

        if (address(priceFeed2) != address(0)) {
            quote = _priceFeedAnswer(priceFeed2, answer2);
        }

        return (priceAmount * base) / quote;
    }

    function _priceFeedAnswer(
        AggregatorV3Interface priceFeed,
        int256 answer
    ) internal view returns (uint256) {
        require(answer > 0);

        uint8 decimals = priceFeed.decimals();

        if (decimals < 18) {
            return uint256(answer) * (10 ** (18 - decimals));
        } else if (decimals > 18) {
            return uint256(answer) / (10 ** (decimals - 18));
        }

        return uint256(answer);
    }

    function _requireMinted(uint256 tokenId) internal view override {
        if (!_exists(tokenId)) {
            revert NotFound();
        }
    }

    modifier whenMinted(uint256 tokenId) {
        _requireMinted(tokenId);
        _;
    }

    modifier whenNotToken() {
        uint256 tokenId = _tokens[_msgSender()];

        if (tokenId != 0) {
            revert Forbidden();
        }

        _;
    }

    uint256[38] private __gap;
}
