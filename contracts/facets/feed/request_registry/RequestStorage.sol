// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library RequestStorage {
    struct Request {
        bytes32 feedId;
        address callbackAddress;
        bytes4 callbackMethod;
        uint32 callbackGasLimit;
        uint256 price;
    }

    struct Layout {
        mapping(bytes32 => Request) requests;
        uint256 requestIdNonce;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Feed.Request");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
