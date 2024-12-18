// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../facets/feed/request_registry/IFeedRequestRegistry.sol";

struct Order {
    uint256 price;
    uint256 quantity;
}

struct OrderBook {
    uint256 lastUpdateId;
    Order[5] bids;
    Order[5] asks;
}

contract OnChainFeedRequestTestContract {
    address quexDiamondAddress;
    bytes32 feedId;
    OrderBook[] orderBooks;

    constructor (address quexDiamondAddress_, bytes32 feedId_) {
        quexDiamondAddress = quexDiamondAddress_;
        feedId = feedId_;
    }

    function request(uint32 callbackGasLimit) external payable {
        uint256 requestPrice;
        IFeedRequestRegistry feedRequestRegistry = IFeedRequestRegistry(quexDiamondAddress);
        (, requestPrice) = feedRequestRegistry.sendFeedRequest{value: msg.value}(feedId, address(this), this.processResponse.selector, callbackGasLimit);
        if (msg.value > requestPrice) {
            payable(msg.sender).transfer(msg.value - requestPrice);
        }
    }

    function processResponse(bytes32 receivedRequestId, DataItem memory response) external {
        assert(receivedRequestId != 0);
        orderBooks.push(abi.decode(response.value, (OrderBook)));
    }

    function getOrderBooks() external view returns (OrderBook[] memory) {
        return orderBooks;
    }

    function getLastBid() external view returns (Order memory) {
        return orderBooks[orderBooks.length - 1].bids[0];
    }

    receive() external payable {}
}