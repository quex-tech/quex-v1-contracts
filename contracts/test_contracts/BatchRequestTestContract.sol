// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/core/IFlowRegistry.sol";
import "../interfaces/core/IQuexActionRegistry.sol";

// Minimal consumer for batch actions: the action lives off-chain (relayer-side
// .bin), so the flow references a precomputed content-addressed actionId
// instead of registering request parts on-chain. The response schema is a
// single uint256.
contract BatchRequestTestContract {
    event BatchResponse(uint256 requestId, uint256 value, uint256 timestamp, uint256 error);

    address public immutable quexCore;
    address public immutable oraclePool;
    address public owner;
    uint256 public flowId;
    uint256 public subscriptionId;
    uint256 public lastRequestId;
    uint256 public lastValue;
    uint256 public lastTimestamp;
    uint256 public lastError;

    constructor(address quexCore_, address oraclePool_) {
        quexCore = quexCore_;
        oraclePool = oraclePool_;
        owner = msg.sender;
    }

    function setUpFlow(uint256 actionId, uint256 gasLimit) external returns (uint256) {
        require(msg.sender == owner, "not owner");
        flowId = IFlowRegistry(quexCore).createFlow(
            Flow(gasLimit, actionId, oraclePool, address(this), this.fulfillBatch.selector)
        );
        return flowId;
    }

    function setSubscriptionId(uint256 subscriptionId_) external {
        require(msg.sender == owner, "not owner");
        subscriptionId = subscriptionId_;
    }

    function createRequest() external returns (uint256) {
        require(msg.sender == owner, "not owner");
        lastRequestId = IQuexActionRegistry(quexCore).createRequest(flowId, subscriptionId);
        return lastRequestId;
    }

    function fulfillBatch(uint256 requestId, DataItem memory dataItem, IdType) external {
        require(msg.sender == quexCore, "not quex core");
        require(requestId == lastRequestId, "unexpected request");
        lastError = dataItem.error;
        lastTimestamp = dataItem.timestamp;
        if (dataItem.error == 0) {
            lastValue = abi.decode(dataItem.value, (uint256));
        }
        emit BatchResponse(requestId, lastValue, dataItem.timestamp, dataItem.error);
    }
}
