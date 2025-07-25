// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Flow} from "../../interfaces/core/IFlowRegistry.sol";

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
