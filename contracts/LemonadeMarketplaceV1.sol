// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./rarible/RoyaltiesV2.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LemonadeMarketplaceV1 is AccessControlEnumerable, Pausable {
    using Counters for Counters.Counter;

    address private immutable _feeAccount;
    uint96 private immutable _feeValue;

    enum OrderKind {
        Direct,
        Auction
    }

    event OrderCreated(
        uint256 indexed orderId,
        OrderKind kind,
        uint256 openFrom,
        uint256 openTo,
        address indexed maker,
        address currency,
        uint256 price,
        address tokenContract,
        uint256 tokenId
    );
    event OrderBid(
        uint256 indexed orderId,
        address indexed bidder,
        uint256 bidAmount
    );
    event OrderFilled(
        uint256 indexed orderId,
        address indexed taker,
        uint256 paidAmount
    );
    event OrderCancelled(uint256 indexed orderId);

    struct Order {
        OrderKind kind;
        bool open;
        uint256 openFrom;
        uint256 openTo;
        address maker;
        address currency;
        uint256 price;
        address tokenContract;
        uint256 tokenId;
        address bidder;
        uint256 bidAmount;
        address taker;
        uint256 paidAmount;
    }
    mapping(uint256 => Order) private _orders;

    Counters.Counter private _orderIdTracker;

    constructor(address feeAccount, uint96 feeValue) {
        _feeAccount = feeAccount;
        _feeValue = feeValue;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function fee() external view returns (address, uint96) {
        return (_feeAccount, _feeValue);
    }

    function order(uint256 orderId)
        external
        view
        virtual
        whenExists(orderId)
        returns (
            OrderKind,
            bool,
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint256,
            address,
            uint256
        )
    {
        Order memory order_ = _orders[orderId];
        return (
            order_.kind,
            order_.open,
            order_.openFrom,
            order_.openTo,
            order_.maker,
            order_.currency,
            order_.price,
            order_.bidAmount,
            order_.taker,
            order_.paidAmount
        );
    }

    function token(uint256 orderId)
        external
        view
        virtual
        whenExists(orderId)
        returns (address, uint256)
    {
        return (_orders[orderId].tokenContract, _orders[orderId].tokenId);
    }

    function createOrder(
        OrderKind kind,
        uint256 openFrom,
        uint256 openTo,
        address currency,
        uint256 price,
        address tokenContract,
        uint256 tokenId
    ) external virtual whenNotPaused returns (uint256) {
        uint256 openDuration_ = openDuration(openFrom, openTo);

        require(
            openDuration_ > 0,
            "LemonadeMarketplace: order must be open at some point"
        );

        if (kind == OrderKind.Auction) {
            require(
                openDuration_ <= 30 * 24 * 60 * 60,
                "LemonadeMarketplace: order of kind auction must not be open for more than 30 days"
            );
        }

        IERC721(tokenContract).transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );

        uint256 orderId = _orderIdTracker.current();

        _orders[orderId] = Order({
            kind: kind,
            open: true,
            openFrom: openFrom,
            openTo: openTo,
            maker: _msgSender(),
            currency: currency,
            price: price,
            tokenContract: tokenContract,
            tokenId: tokenId,
            bidder: address(0),
            bidAmount: 0,
            taker: address(0),
            paidAmount: 0
        });

        _orderIdTracker.increment();

        Order memory order_ = _orders[orderId];
        emit OrderCreated(
            orderId,
            order_.kind,
            order_.openFrom,
            order_.openTo,
            order_.maker,
            order_.currency,
            order_.price,
            order_.tokenContract,
            order_.tokenId
        );
        return orderId;
    }

    function cancelOrder(uint256 orderId)
        external
        virtual
        whenNotPaused
        whenExists(orderId)
    {
        Order memory order_ = _orders[orderId];
        require(
            order_.maker == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "LemonadeMarketplace: must be the maker to cancel"
        );
        require(
            order_.open,
            "LemonadeMarketplace: order must be open to cancel"
        );
        require(
            order_.bidder == address(0),
            "LemonadeMarketplace: order must have no bid to cancel"
        );

        IERC721(order_.tokenContract).safeTransferFrom(
            address(this),
            order_.maker,
            order_.tokenId
        );

        _orders[orderId].open = false;
        emit OrderCancelled(orderId);
    }

    function bidOrder(uint256 orderId, uint256 amount)
        external
        virtual
        whenNotPaused
        whenExists(orderId)
    {
        Order memory order_ = _orders[orderId];
        require(
            order_.kind == OrderKind.Auction,
            "LemonadeMarketplace: order must be of kind auction to bid"
        );
        require(order_.open, "LemonadeMarketplace: order must be open to bid");
        require(
            order_.openFrom <= block.timestamp,
            "LemonadeMarketplace: order must be open to bid - too early"
        );
        require(
            order_.openTo > block.timestamp,
            "LemonadeMarketplace: order must be open to bid - too late"
        );
        require(
            order_.price <= amount,
            "LemonadeMarketplace: must match price to bid"
        );

        if (order_.bidder != address(0)) {
            require(
                order_.bidAmount < amount,
                "LemonadeMarketplace: must surpass bid to bid"
            );

            transferERC20(
                order_.currency,
                address(this),
                order_.bidder,
                order_.bidAmount
            );
        }

        _orders[orderId].bidder = _msgSender();
        _orders[orderId].bidAmount = amount;
        order_ = _orders[orderId];

        transferERC20(
            order_.currency,
            order_.bidder,
            address(this),
            order_.bidAmount
        );

        emit OrderBid(orderId, order_.bidder, order_.bidAmount);
    }

    function fillOrder(uint256 orderId, uint256 amount)
        external
        virtual
        whenNotPaused
        whenExists(orderId)
    {
        Order memory order_ = _orders[orderId];
        require(order_.open, "LemonadeMarketplace: order must be open to fill");

        _orders[orderId].open = false;
        address spender;

        if (order_.kind == OrderKind.Direct) {
            require(
                order_.openFrom <= block.timestamp,
                "LemonadeMarketplace: order must be open to fill - too early"
            );
            require(
                order_.openTo == 0 || order_.openTo > block.timestamp,
                "LemonadeMarketplace: order must be open to fill - too late"
            );
            require(
                order_.price <= amount,
                "LemonadeMarketplace: must match price to fill direct order"
            );

            _orders[orderId].taker = _msgSender();
            _orders[orderId].paidAmount = amount;
            spender = _msgSender();
        } else if (order_.kind == OrderKind.Auction) {
            require(
                (order_.bidder != address(0)),
                "LemonadeMarketplace: order must have bid to fill auction order"
            );
            require(
                (order_.bidder == _msgSender() &&
                    order_.openTo <= block.timestamp) ||
                    order_.maker == _msgSender() ||
                    hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
                "LemonadeMarketplace: must be the maker or final bidder to fill auction order"
            );

            _orders[orderId].taker = order_.bidder;
            _orders[orderId].paidAmount = order_.bidAmount;
            spender = address(this);
        }

        order_ = _orders[orderId];

        if (order_.paidAmount > 0) {
            uint256 transferAmount = order_.paidAmount;

            uint256 feeAmount = (order_.paidAmount * _feeValue) / 10000;
            transferERC20(order_.currency, spender, _feeAccount, feeAmount);
            transferAmount -= feeAmount;

            try
                RoyaltiesV2(order_.tokenContract).getRaribleV2Royalties(
                    order_.tokenId
                )
            returns (LibPart.Part[] memory royalties) {
                uint256 length = royalties.length;
                for (uint256 i; i < length; i++) {
                    if (order_.maker != royalties[i].account) {
                        uint256 royaltyAmount = (order_.paidAmount *
                            royalties[i].value) / 10000;
                        transferERC20(
                            order_.currency,
                            spender,
                            royalties[i].account,
                            royaltyAmount
                        );
                        transferAmount -= royaltyAmount;
                    }
                }
            } catch {
                try
                    IERC2981(order_.tokenContract).royaltyInfo(
                        order_.tokenId,
                        order_.paidAmount
                    )
                returns (address receiver, uint256 royaltyAmount) {
                    if (order_.maker != receiver) {
                        transferERC20(
                            order_.currency,
                            spender,
                            receiver,
                            royaltyAmount
                        );
                        transferAmount -= royaltyAmount;
                    }
                } catch {}
            }

            if (transferAmount > 0) {
                transferERC20(
                    order_.currency,
                    spender,
                    order_.maker,
                    transferAmount
                );
            }
        }

        IERC721(order_.tokenContract).safeTransferFrom(
            address(this),
            order_.taker,
            order_.tokenId
        );

        emit OrderFilled(orderId, order_.taker, order_.paidAmount);
    }

    function transferERC20(
        address currency_,
        address spender,
        address recipient,
        uint256 amount
    ) private {
        IERC20 currency = IERC20(currency_);

        if (spender == address(this)) {
            currency.transfer(recipient, amount);
        } else {
            currency.transferFrom(spender, recipient, amount); // requires allowance
        }
    }

    function openDuration(uint256 openFrom, uint256 openTo)
        private
        view
        returns (uint256)
    {
        uint256 start = openFrom < block.timestamp ? block.timestamp : openFrom;
        uint256 end = openTo == 0 ? type(uint256).max : openTo;

        if (start > end) {
            // avoids overflow
            return 0;
        }

        return end - start;
    }

    modifier whenExists(uint256 orderId) {
        require(
            _orders[orderId].maker != address(0),
            "LemonadeMarketplace: order nonexistent"
        );
        _;
    }

    function pause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
