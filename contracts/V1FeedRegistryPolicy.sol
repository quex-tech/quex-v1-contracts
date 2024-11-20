// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1FeedRegistryPolicy.sol";

contract V1FeedRegistryPolicy is IV1FeedRegistryPolicy {
    function isAllowed(address) external pure returns (bool) {
        return true;
    }
}