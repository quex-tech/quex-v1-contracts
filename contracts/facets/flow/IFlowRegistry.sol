// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct Flow {
    uint256 gasLimit;
    uint256 actionId;
    address consumer;
    address pool;
    bytes4 callback;
}

interface IFlowRegistry {
    function createFlow(Flow memory flow) external returns (uint256 flowId);
    function getFlow(uint256 flowId) external view returns (Flow memory);
}

library FlowStorage {
    struct Layout {
        mapping(uint256 => Flow) flows;
        uint256 lastFlowId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Flow");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}

contract FlowFacet is IFlowRegistry {
    function createFlow(Flow memory flow) external returns (uint256 flowId) {
        FlowStorage.Layout storage layout = FlowStorage.layout();
        flowId = layout.lastFlowId + 1;
        layout.flows[flowId] = flow;
        layout.lastFlowId = flowId;
        return flowId;
    }

    function getFlow(uint256 flowId) external view returns (Flow memory) {
        return FlowStorage.layout().flows[flowId];
    }
}
