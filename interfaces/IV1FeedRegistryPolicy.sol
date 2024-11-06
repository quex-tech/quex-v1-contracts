// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1FeedRegistryPolicy {
    function isAllowed(address address_) external view returns (bool);
}