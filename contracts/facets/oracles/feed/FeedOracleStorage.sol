// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/oracles/IFeedRegistry.sol";

library FeedOracleStorage {
    struct FeedInternal {
        bytes32 requestId;
        bytes32 patchId;
        bytes32 schemaId;
        bytes32 filterId;
    }

    struct Layout {
        mapping(bytes32 => HTTPRequest) requests;
        mapping(bytes32 => HTTPPrivatePatch) privatePatches;
        mapping(bytes32 => address) privatePatchTdAddresses;
        mapping(bytes32 => string) jqFilters;
        mapping(bytes32 => string) resultSchemas;
        mapping(uint256 => FeedInternal) feeds;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.pools.feeds.Request");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
