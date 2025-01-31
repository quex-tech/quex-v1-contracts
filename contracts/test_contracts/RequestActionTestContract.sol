// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/core/IQuexActionRegistry.sol";
import "../interfaces/oracles/IRequestOraclePool.sol";

struct Order {
    uint256 price;
    uint256 quantity;
}

struct OrderBook {
    uint256 lastUpdateId;
    Order[5] bids;
    Order[5] asks;
}

contract RequestActionTestContract {
    address quexCoreAddress;
    address oraclePoolAddress;
    uint256 lastRequestId;
    OrderBook lastResponse;

    constructor(address quexCoreAddress_, address oraclePoolAddress_) {
        quexCoreAddress = quexCoreAddress_;
        oraclePoolAddress = oraclePoolAddress_;
    }

    function createRequest() external payable {
        IRequestOraclePool requestOracle = IRequestOraclePool(oraclePoolAddress);
        QueryParameter[] memory parameters = new QueryParameter[](2);
        parameters[0] = QueryParameter("symbol", "BTCUSDT");
        parameters[1] = QueryParameter("limit", "5");
        HTTPRequest memory request = HTTPRequest(
            RequestMethod.Get,
            "www.binance.com",
            "/api/v3/depth",
            new RequestHeader[](0),
            parameters,
            ""
        );
        bytes32 requestId = requestOracle.addRequest(request);
        bytes32 patchId = bytes32(0);
        bytes32 schemaId = requestOracle.addResponseSchema("(uint256,(uint256,uint256)[5],(uint256,uint256)[5])");
        bytes32 filterId = requestOracle.addJqFilter(
            "[.lastUpdateId] + ([.bids, .asks] | map(map(map(tonumber*100000000|floor))))"
        );

        uint256 flowId = requestOracle.addFlow(
            requestId,
            patchId,
            schemaId,
            filterId,
            address(this),
            this.fulfillRequest.selector,
            1000000
        );

        IQuexActionRegistry actionRegistry = IQuexActionRegistry(quexCoreAddress);
        (uint256 nativeFee, uint256 gasFee) = actionRegistry.getRequestFee(flowId);
        uint256 totalRequestPrice = nativeFee + gasFee * tx.gasprice;
        lastRequestId = requestOracle.startRequest{value: totalRequestPrice}(flowId);

        if (msg.value > totalRequestPrice) {
            payable(msg.sender).transfer(msg.value - totalRequestPrice);
        }
    }

    function fulfillRequest(uint256 requestId, DataItem memory dataItem, IdType /* idType */) external {
        require(msg.sender == quexCoreAddress);
        require(requestId == lastRequestId);
        lastResponse = abi.decode(dataItem.value, (OrderBook));
    }

    function getLastRequestId() external view returns (uint256 requestId) {
        return lastRequestId;
    }

    function getLastResponse() external view returns (OrderBook memory) {
        return lastResponse;
    }
}
