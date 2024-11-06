// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1FeedRegistryPolicy.sol";

contract V1FeedRegistryPolicy is IV1FeedRegistryPolicy {
    mapping(address => uint256) internal allowedAddresses;

    function addAllowedAddress(address address_) external {
        allowedAddresses[address_] = 1;
    }

    function removeAllowedAddress(address address_) external {
        allowedAddresses[address_] = 0;
    }

    function isAllowed(address address_) external view returns (bool) {
        return allowedAddresses[address_] == 1;
    }
}