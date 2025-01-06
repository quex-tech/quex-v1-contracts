// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library QuexMonetaryStorage {
    struct Layout {
        address treasuryAddress;
        uint256 constantQuexFee;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Monetary");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
