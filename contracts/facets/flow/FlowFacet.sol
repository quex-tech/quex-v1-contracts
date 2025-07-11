// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IFlowRegistry, Flow} from "../../interfaces/core/IFlowRegistry.sol";
import {FlowStorage} from "./FlowStorage.sol";

contract FlowFacet is IFlowRegistry {
    function createFlow(Flow calldata flow) external returns (uint256 flowId) {
        if (flow.consumer == address(this)) {
            revert Flow_SelfCallForbidden();
        }
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
