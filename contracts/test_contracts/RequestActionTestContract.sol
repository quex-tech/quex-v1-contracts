// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/core/IFlowRegistry.sol";
import "../interfaces/core/IQuexActionRegistry.sol";
import "../interfaces/core/IDepositManager.sol";
import "../interfaces/core/IQuexMonetary.sol";
import "../interfaces/oracles/IRequestOraclePool.sol";
import "../facets/actions/QuexActionFacet.sol";

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
    event log_uint(uint256 value);
    event log_address(address value);

    address quexCoreAddress;
    address oraclePoolAddress;
    uint256 lastRequestId;
    uint256 subscriptionId;
    uint256 flowId;
    OrderBook lastResponse;

    constructor(address quexCoreAddress_, address oraclePoolAddress_) {
        quexCoreAddress = quexCoreAddress_;
        oraclePoolAddress = oraclePoolAddress_;
    }

    function setUpFlow() external payable {
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

        uint256 actionId = requestOracle.addActionByParts(
            requestId,
            patchId,
            schemaId,
            filterId
        );

        IFlowRegistry flowRegistry = IFlowRegistry(quexCoreAddress);
        Flow memory flow = Flow(1000000, actionId, oraclePoolAddress, address(this), this.fulfillRequest.selector);
        flowId = flowRegistry.createFlow(flow);

        IDepositManager depositManager = IDepositManager(quexCoreAddress);

        // create subscription and fund it
        subscriptionId = depositManager.createSubscription();
        emit log_uint(subscriptionId);
        depositManager.addConsumer(subscriptionId, flow.consumer);
        emit log_address(flow.consumer);
        depositManager.deposit{value: msg.value}(subscriptionId);
        emit log_uint(msg.value);
    }

    function getFlowSubscriptionStatus() external view returns (uint256, uint256, bool, address, uint256) {
        IDepositManager depositManager = IDepositManager(quexCoreAddress);
        QuexActionFacet quexAction = QuexActionFacet(quexCoreAddress);
        Flow memory flow = IFlowRegistry(quexCoreAddress).getFlow(flowId);

        address pool = flow.pool;
        bool isValid = depositManager.hasAccessToSubscription(subscriptionId, address(this));
        uint256 subscriptionBalance = depositManager.withdrawableBalance(subscriptionId);
        (uint256 nativeFee, uint256 gasFee) = quexAction.getRequestFee(flowId);
        return (flowId, subscriptionId, isValid, pool, subscriptionBalance);
    }

    function createRequest() external {
        IQuexActionRegistry actionRegistry = IQuexActionRegistry(quexCoreAddress);
        lastRequestId = actionRegistry.createRequest(flowId, subscriptionId);
    }

    function deposit() external payable {
        IDepositManager depositManager = IDepositManager(quexCoreAddress);
        depositManager.deposit{value: msg.value}(subscriptionId);
    }

    function withdraw() external {
        IDepositManager depositManager = IDepositManager(quexCoreAddress);
        depositManager.withdraw(subscriptionId, msg.sender);
    }

    function fulfillRequest(uint256 requestId, DataItem memory dataItem, IdType /* idType */) external {
        require(msg.sender == quexCoreAddress);
        require(requestId == lastRequestId);
        lastResponse = abi.decode(dataItem.value, (OrderBook));
    }

    function getLastRequestId() external view returns (uint256 requestId) {
        return lastRequestId;
    }

    function getLastRequest() external view returns (Request memory) {
        QuexActionFacet quexAction = QuexActionFacet(quexCoreAddress);
        Request memory req = quexAction.getRequest(lastRequestId);

        return req;
    }

    function getLastResponse() external view returns (OrderBook memory) {
        return lastResponse;
    }
}
