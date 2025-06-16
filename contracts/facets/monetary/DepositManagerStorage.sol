// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library DepositManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.DepositManager");

    struct Subscription {
        uint256 balance;
        uint256 reserved;
        address owner;
        mapping(address => uint256) consumers;
    }

    struct Layout {
        uint256 counter;
        mapping(uint256 => Subscription) subscriptions;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}