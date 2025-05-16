// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library ConstantMaxResponseBlocksStorage {
    struct Layout {
        uint256 maxResponseBlocks;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quex.contracts.facets.oracles.common.constant_max_response_blocks.ConstantMaxResponseBlocksStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
