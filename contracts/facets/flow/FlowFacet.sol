// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../interfaces/core/IFlowRegistry.sol";
import "./FlowStorage.sol";

contract FlowFacet is IFlowRegistry {
    function createFlow(Flow calldata flow) external returns (uint256 flowId) {
        require(flow.consumer != address(this), "Self-calls forbidden");
        FlowStorage.Layout storage layout = FlowStorage.layout();
        flowId = layout.lastFlowId + 1;
        layout.flows[flowId] = flow;
        layout.lastFlowId = flowId;
        emit FlowAdded(flowId);
        return flowId;
    }

    function getFlow(uint256 flowId) external view returns (Flow memory) {
        return FlowStorage.layout().flows[flowId];
    }
}
