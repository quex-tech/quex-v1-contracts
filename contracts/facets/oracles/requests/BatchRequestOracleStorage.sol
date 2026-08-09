// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library BatchRequestOracleStorage {
    struct BatchActionInternal {
        bytes32[] requestIds;
        bytes32[] patchIds;
        bytes32 schemaId;
        bytes32 filterId;
    }

    struct Layout {
        mapping(uint256 => BatchActionInternal) batchActions;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.pools.request.batch.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
