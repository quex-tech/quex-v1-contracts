// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library TrustDomainPolicyStorage {
    struct Layout {
        mapping(address => uint256) allowedTDs;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Feed.TrustDomainPolicy");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
