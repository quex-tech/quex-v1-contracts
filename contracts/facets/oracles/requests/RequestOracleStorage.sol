// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/oracles/IRequestOraclePool.sol";

library RequestOracleStorage {
    struct RequestActionInternal {
        bytes32 requestId;
        bytes32 patchId;
        bytes32 schemaId;
        bytes32 filterId;
    }

    struct Layout {
        mapping(bytes32 => HTTPRequest) requests;
        mapping(bytes32 => HTTPPrivatePatch) privatePatches;
        mapping(bytes32 => string) jqFilters;
        mapping(bytes32 => string) resultSchemas;
        mapping(uint256 => RequestActionInternal) requestActions;
        mapping(bytes32 => address) privatePatchOwners;
        mapping(bytes32 => mapping(address => uint256)) privatePatchConsumers;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.pools.request.v2");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
