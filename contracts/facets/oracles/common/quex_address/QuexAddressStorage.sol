// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library QuexAddressStorage {
    struct Layout {
        address quexAddress;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.oracles.common.QuexAddress");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
